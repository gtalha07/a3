use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::tests::activities::status::get_latest_activity;
use crate::utils::random_users_with_random_space_under_template;

const TMPL: &str = r#"
version = "0.1"
name = "News Notifications Setup Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }
space = { type = "space", is-default = true, required = true, description = "The main user" }

[objects.example-news-one-image]
type = "news-entry"
slides = [
  { body = "This is the news section. Swipe down for more.", info = { size = 3264047, mimetype = "image/jpeg", thumbnail_info = { w = 400, h = 600, mimetype = "image/jpeg", size = 130511 }, w = 3840, h = 5760, "xyz.amorgan.blurhash" = "TQF=,g?uIo},={X5$c#+V@t2sRjF", thumbnail_url = "mxc://acter.global/aJhqfXrJRWXsFgWFRNlBlpnD" }, msgtype = "m.image", url = "mxc://acter.global/tVLtaQaErMyoXmcCroPZdfNG" }
]

[objects.example-story-two-images]
type = "story"

[[objects.example-story-two-images.slides]]
body = "This is the story section. Swipe down for more."
info = { size = 3264047, mimetype = "image/jpeg", thumbnail_info = { w = 400, h = 600, mimetype = "image/jpeg", size = 130511 }, w = 3840, h = 5760, "xyz.amorgan.blurhash" = "TQF=,g?uIo},={X5$c#+V@t2sRjF", thumbnail_url = "mxc://acter.global/aJhqfXrJRWXsFgWFRNlBlpnD" }
type = "Image"
url = "mxc://acter.global/tVLtaQaErMyoXmcCroPZdfNG"

"#;

#[tokio::test]
async fn like_activity_on_news() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("likeOnboost", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = second_user.clone();
    let news_entry = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let news_entries = client.latest_news_entries(1).await?;
            if news_entries.len() != 1 {
                bail!("news entries not found found");
            }
            Ok(news_entries[0].clone())
        }
    })
    .await?;

    let reactions = news_entry.reactions().await?;
    reactions.send_like().await?;

    let activity = Retry::spawn(retry_strategy.clone(), move || {
        let first = first.clone();
        let space_id = space_id.clone();
        async move { get_latest_activity(&first, space_id.to_string(), "reaction").await }
    })
    .await?;
    assert_eq!(activity.type_str(), "reaction");
    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "news");
    assert_eq!(object.object_id_str(), news_entry.event_id().to_string());

    Ok(())
}

#[tokio::test]
async fn like_activity_on_story() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("likeOnboost", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = second_user.clone();
    let story = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let news_entries = client.latest_stories(1).await?;
            if news_entries.len() != 1 {
                bail!("story entries not found found");
            }
            Ok(news_entries[0].clone())
        }
    })
    .await?;

    let reactions = story.reactions().await?;
    reactions.send_like().await?;

    let activity = Retry::spawn(retry_strategy.clone(), move || {
        let first = first.clone();
        let space_id = space_id.clone();
        async move { get_latest_activity(&first, space_id.to_string(), "reaction").await }
    })
    .await?;
    assert_eq!(activity.type_str(), "reaction");
    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "story");
    assert_eq!(object.object_id_str(), story.event_id().to_string());

    Ok(())
}
