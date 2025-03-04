use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::{accept_all_invites, random_users_with_random_chat_and_space_under_template};

const TMPL: &str = r#"
version = "0.1"
name = "Pin Notifications Setup Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }
space = { type = "space", is-default = true, required = true, description = "The main user" }

[objects.acter-website-pin]
type = "pin"
title = "Acter Website"
url = "https://acter.global"

"#;

#[tokio::test]
async fn ref_details_as_url_preview() -> Result<()> {
    let _ = env_logger::try_init();
    let (users, _sync_states, _space_id, chat_id, _engine) =
        random_users_with_random_chat_and_space_under_template("url_preview_ref_details", 2, TMPL)
            .await?;

    let mut user = users[0].clone();
    let mut second = users[1].clone();

    let sync_state1 = user.start_sync();
    sync_state1.await_has_synced_history().await?;

    let sync_state2 = second.start_sync();
    sync_state2.await_has_synced_history().await?;

    // wait for sync to catch up
    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = second_user.clone();
    let obj_entry = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.pins().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            Ok(entries[0].clone())
        }
    })
    .await?;

    let ref_details = obj_entry.ref_details().await?;
    let target_uri = ref_details.generate_internal_link(true)?;
    let mut draft = user.text_plain_draft("look at this pin".to_owned());
    draft = draft.add_ref_details(Box::new(ref_details))?;

    let convo = first
        .convo(chat_id.to_string())
        .await
        .expect("we are in the chat");
    let tl = convo.timeline_stream();
    tl.send_message(Box::new(draft)).await?;

    let fetcher_client = second.clone();
    let target_chat_id = chat_id.to_string();
    let latest_msg = Retry::spawn(retry_strategy.clone(), move || {
        let second = fetcher_client.clone();
        let chat_id = target_chat_id.clone();
        async move {
            accept_all_invites(&second).await?;

            let convo = second.convo(chat_id).await?;
            let Some(msg) = convo.latest_message() else {
                bail!("no latest message found");
            };
            let Some(item) = msg.event_item() else {
                bail!("Not the proper event");
            };
            if item.event_type() != "m.room.message" {
                bail!(format!("Not the message we are looking for {item:?}"));
            }
            Ok(msg)
        }
    })
    .await?;

    let msg = latest_msg
        .event_item()
        .expect("has item")
        .msg_content()
        .expect("has content");
    assert!(msg.has_url_previews(), "no url previews found");

    let previews = msg.url_previews();
    assert_eq!(previews.len(), 1);
    let preview = previews.first().expect("has one");
    assert_eq!(preview.title().unwrap(), "Acter Website");
    assert_eq!(preview.url().unwrap(), target_uri);

    Ok(())
}

#[tokio::test]
async fn url_preview_on_message() -> Result<()> {
    let _ = env_logger::try_init();
    let (users, _sync_states, _space_id, chat_id, _engine) =
        random_users_with_random_chat_and_space_under_template("url_preview_ref_details", 2, TMPL)
            .await?;

    let mut user = users[0].clone();
    let mut second = users[1].clone();

    let sync_state1 = user.start_sync();
    sync_state1.await_has_synced_history().await?;

    let sync_state2 = second.start_sync();
    sync_state2.await_has_synced_history().await?;

    // wait for sync to catch up
    let first = users.first().expect("exists");
    let target_uri = option_env!("DEFAULT_HOMESERVER_URL")
        .unwrap_or("http://localhost:8118")
        .to_string();

    let preview = user.url_preview(target_uri.clone()).await?;

    assert_eq!(preview.title().unwrap(), "Synapse is running");

    let mut draft = user.text_plain_draft("look at this pin".to_owned());
    draft = draft.add_url_preview(Box::new(preview))?;

    let convo = first
        .convo(chat_id.to_string())
        .await
        .expect("we are in the chat");
    let tl = convo.timeline_stream();
    tl.send_message(Box::new(draft)).await?;

    let fetcher_client = second.clone();
    let target_chat_id = chat_id.to_string();
    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let latest_msg = Retry::spawn(retry_strategy, move || {
        let second = fetcher_client.clone();
        let chat_id = target_chat_id.clone();
        async move {
            accept_all_invites(&second).await?;

            let convo = second.convo(chat_id).await?;
            let Some(msg) = convo.latest_message() else {
                bail!("no latest message found");
            };
            let Some(item) = msg.event_item() else {
                bail!("Not the proper event");
            };
            if item.event_type() != "m.room.message" {
                bail!(format!("Not the message we are looking for {item:?}"));
            }
            Ok(msg)
        }
    })
    .await?;

    let msg = latest_msg
        .event_item()
        .expect("has item")
        .msg_content()
        .expect("has content");
    assert!(msg.has_url_previews(), "no url previews found");

    let previews = msg.url_previews();
    assert_eq!(previews.len(), 1);
    let preview = previews.first().expect("has one");
    assert_eq!(preview.title().unwrap(), "Synapse is running");
    assert_eq!(preview.url().unwrap(), target_uri);

    Ok(())
}
