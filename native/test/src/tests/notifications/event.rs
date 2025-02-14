use std::time::SystemTime;

use acter::UtcDateTime;
use anyhow::{bail, Result};
use chrono::Days;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::{random_users_with_random_space, random_users_with_random_space_under_template};

const TMPL: &str = r#"
version = "0.1"
name = "Event Notifications Setup Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }
space = { type = "space", is-default = true, required = true, description = "The main user" }

[objects.acter-event-1]
type = "calendar-event"
title = "First meeting"
utc_start = "{{ future(add_mins=1).as_rfc3339 }}"
utc_end = "{{ future(add_mins=60).as_rfc3339 }}"

"#;

#[tokio::test]
async fn event_creation_notification() -> Result<()> {
    let _ = env_logger::try_init();
    let (users, room_id) =
        random_users_with_random_space("event_creation_notifications", 2).await?;

    let mut user = users[0].clone();
    let mut second = users[1].clone();

    second.install_default_acter_push_rules().await?;

    let sync_state1 = user.start_sync();
    sync_state1.await_has_synced_history().await?;

    let sync_state2 = second.start_sync();
    sync_state2.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let main_space = Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            let spaces = client.spaces().await?;
            if spaces.len() != 1 {
                bail!("space not found");
            }
            Ok(spaces.first().cloned().expect("space found"))
        }
    })
    .await?;

    let space_on_second = second.room(main_space.room_id_str()).await?;
    space_on_second
        .set_notification_mode(Some("all".to_owned()))
        .await?; // we want to see push for everything;

    let mut draft = main_space.calendar_event_draft()?;
    draft.title("First meeting".to_owned());
    draft.utc_start_from_rfc3339(UtcDateTime::from(SystemTime::now()).to_rfc3339())?;
    draft.utc_end_from_rfc3339(UtcDateTime::from(SystemTime::now()).to_rfc3339())?;
    let event_id = draft.send().await?;
    tracing::trace!("draft sent event id: {}", event_id);

    let notifications = second
        .get_notification_item(room_id.to_string(), event_id.to_string())
        .await?;

    assert_eq!(notifications.push_style(), "creation");
    assert_eq!(notifications.target_url(), format!("/events/{event_id}"));
    let parent = notifications.parent().unwrap();
    assert_eq!(parent.type_str(), "event".to_owned());
    assert_eq!(parent.title().unwrap(), "First meeting".to_owned());
    assert_eq!(parent.emoji(), "🗓️"); // calendar icon
    assert_eq!(parent.object_id_str(), event_id);

    Ok(())
}

#[tokio::test]
async fn event_title_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventTitleUpdate", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let obj_entry = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.calendar_events().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            Ok(entries[0].clone())
        }
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id_str())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let mut update = obj_entry.update_builder()?;
    update.title("Renamed Event".to_owned());
    let notification_ev = update.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "titleChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id().to_string(),
    );

    let obj_id = obj_entry.event_id().to_string();

    assert_eq!(notification_item.title(), "Renamed Event"); // new title
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/events/{}", obj_id,)
    );
    assert_eq!(parent.type_str(), "event");
    // assert_eq!(parent.title().unwrap(), "First Meeting"); // old name
    assert_eq!(parent.emoji(), "🗓️"); // calendar icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn event_desc_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventDescUpdate", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let obj_entry = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.calendar_events().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            Ok(entries[0].clone())
        }
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id_str())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let mut update = obj_entry.update_builder()?;
    update.description_text("Added content".to_owned());
    let notification_ev = update.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "descriptionChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in event"),
        obj_entry.event_id().to_string(),
    );

    let obj_id = obj_entry.event_id().to_string();

    let content = notification_item.body().expect("found content");
    assert_eq!(content.body(), "Added content"); // new description
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/events/{}", obj_id,)
    );
    assert_eq!(parent.type_str(), "event");
    assert_eq!(parent.title().unwrap(), "First meeting");
    assert_eq!(parent.emoji(), "🗓️"); // calendar icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn event_rescheduled() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventDescUpdate", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let obj_entry = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.calendar_events().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            Ok(entries[0].clone())
        }
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id_str())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let new_date = UtcDateTime::from(SystemTime::now())
        .checked_add_days(Days::new(1))
        .expect("there is a tomorrow");
    let mut update = obj_entry.update_builder()?;
    update
        .utc_start_from_rfc3339(new_date.to_rfc3339())
        .unwrap();
    update
        .utc_end_from_rfc3339(
            new_date
                .checked_add_days(Days::new(1))
                .unwrap()
                .to_rfc3339(),
        )
        .unwrap();
    let notification_ev = update.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "eventDateChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in event"),
        obj_entry.event_id().to_string(),
    );

    let obj_id = obj_entry.event_id().to_string();
    assert_eq!(notification_item.new_date(), Some(new_date));
    assert_eq!(notification_item.title(), new_date.to_rfc3339());
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/events/{}", obj_id,)
    );
    assert_eq!(parent.type_str(), "event");
    assert_eq!(parent.title().unwrap(), "First meeting");
    assert_eq!(parent.emoji(), "🗓️"); // calendar icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn event_rsvp() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventDescUpdate", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let obj_entry = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.calendar_events().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            Ok(entries[0].clone())
        }
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id_str())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let rsvp_manager = obj_entry.rsvps().await?;
    // test yes
    {
        let mut rsvp = rsvp_manager.rsvp_draft()?;
        rsvp.status("yes".to_string());

        let notification_ev = rsvp.send().await?;

        let notification_item = first
            .get_notification_item(space_id.to_string(), notification_ev.to_string())
            .await?;
        assert_eq!(notification_item.push_style(), "rsvpYes");
        assert_eq!(
            notification_item
                .parent_id_str()
                .expect("parent is in event"),
            obj_entry.event_id().to_string(),
        );

        let obj_id = obj_entry.event_id().to_string();
        let parent = notification_item.parent().expect("parent was found");
        assert_eq!(
            notification_item.target_url(),
            format!("/events/{}", obj_id,)
        );
        assert_eq!(parent.type_str(), "event");
        assert_eq!(parent.title().unwrap(), "First meeting");
        assert_eq!(parent.emoji(), "🗓️"); // calendar icon
        assert_eq!(parent.object_id_str(), obj_id);
    }

    // test no
    {
        let mut rsvp = rsvp_manager.rsvp_draft()?;
        rsvp.status("no".to_string());

        let notification_ev = rsvp.send().await?;

        let notification_item = first
            .get_notification_item(space_id.to_string(), notification_ev.to_string())
            .await?;
        assert_eq!(notification_item.push_style(), "rsvpNo");
        assert_eq!(
            notification_item
                .parent_id_str()
                .expect("parent is in event"),
            obj_entry.event_id().to_string(),
        );

        let obj_id = obj_entry.event_id().to_string();
        let parent = notification_item.parent().expect("parent was found");
        assert_eq!(
            notification_item.target_url(),
            format!("/events/{}", obj_id,)
        );
        assert_eq!(parent.type_str(), "event");
        assert_eq!(parent.title().unwrap(), "First meeting");
        assert_eq!(parent.emoji(), "🗓️"); // calendar icon
        assert_eq!(parent.object_id_str(), obj_id);
    }

    // test no
    {
        let mut rsvp = rsvp_manager.rsvp_draft()?;
        rsvp.status("maybe".to_string());

        let notification_ev = rsvp.send().await?;

        let notification_item = first
            .get_notification_item(space_id.to_string(), notification_ev.to_string())
            .await?;
        assert_eq!(notification_item.push_style(), "rsvpMaybe");
        assert_eq!(
            notification_item
                .parent_id_str()
                .expect("parent is in event"),
            obj_entry.event_id().to_string(),
        );

        let obj_id = obj_entry.event_id().to_string();
        let parent = notification_item.parent().expect("parent was found");
        assert_eq!(
            notification_item.target_url(),
            format!("/events/{}", obj_id,)
        );
        assert_eq!(parent.type_str(), "event");
        assert_eq!(parent.title().unwrap(), "First meeting");
        assert_eq!(parent.emoji(), "🗓️"); // calendar icon
        assert_eq!(parent.object_id_str(), obj_id);
    }

    Ok(())
}

#[ignore]
#[tokio::test]
async fn event_redaction() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventRedaction", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = first.clone();
    let event = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.calendar_events().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            Ok(entries[0].clone())
        }
    })
    .await?;

    // we want to see push for everything;
    second_user
        .room(event.room_id_str())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let obj_id = event.event_id().to_string();
    let space = first.space(event.room_id().to_string()).await?;
    let notification_ev = space.redact(&event.event_id(), None, None).await?.event_id;

    let notification_item = second_user
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "redaction");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in redaction"),
        obj_id,
    );

    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(notification_item.target_url(), format!("/events/"));
    assert_eq!(parent.type_str(), "event");
    assert_eq!(parent.title().unwrap(), "First Meeting");
    assert_eq!(parent.emoji(), "🗓️"); // calendar icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}
