use acter_core::{
    models::{self, ActerModel, AnyActerModel},
    statics::KEYS,
};
use anyhow::{bail, Context, Result};
use core::time::Duration;
use futures::stream::StreamExt;
use matrix_sdk::{room::Room, RoomState};
use ruma_common::{EventId, OwnedEventId, OwnedUserId};
use ruma_events::{
    reaction::{self, ReactionEventContent},
    relation::Annotation,
    AnyMessageLikeEventContent, MessageLikeEventType,
};
use std::{ops::Deref, str::FromStr};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::{error, trace, warn};

use super::{client::Client, RUNTIME};

impl Client {
    pub async fn wait_for_reaction(
        &self,
        key: String,
        timeout: Option<Box<Duration>>,
    ) -> Result<Reaction> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Reaction(reaction) = client.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a reaction");
                };
                let room = client
                    .core
                    .client()
                    .get_room(&reaction.meta.room_id)
                    .context("Room not found")?;
                Ok(Reaction {
                    client: client.clone(),
                    room,
                    inner: reaction,
                })
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct Reaction {
    client: Client,
    room: Room,
    inner: models::Reaction,
}

impl Deref for Reaction {
    type Target = models::Reaction;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Reaction {
    pub fn sender(&self) -> OwnedUserId {
        self.inner.meta.sender.clone()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.meta.origin_server_ts.get().into()
    }

    pub fn relates_to(&self) -> String {
        self.inner.relates_to.event_id.to_string()
    }
}

#[derive(Clone, Debug)]
pub struct ReactionManager {
    client: Client,
    room: Room,
    inner: models::ReactionManager,
}

impl Deref for ReactionManager {
    type Target = models::ReactionManager;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl ReactionManager {
    pub(crate) fn new(
        client: Client,
        room: Room,
        inner: models::ReactionManager,
    ) -> ReactionManager {
        ReactionManager {
            client,
            room,
            inner,
        }
    }

    pub async fn send_reaction(&self, event_id: String, key: String) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let reaction = self.inner.clone();

        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();

        let event_id = OwnedEventId::from_str(&event_id).unwrap();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                trace!("before sending reaction");
                let content = ReactionEventContent::new(Annotation::new(event_id, key));
                let response = room.send(content).await?;
                trace!("after sending reaction");
                Ok(response.event_id)
            })
            .await?
    }

    pub fn stats(&self) -> models::ReactionStats {
        self.inner.stats().clone()
    }

    pub fn has_reaction_entries(&self) -> bool {
        *self.stats().has_reaction_entries()
    }

    pub fn total_reaction_count(&self) -> u32 {
        *self.stats().total_reaction_count()
    }

    pub async fn reaction_entries(&self) -> Result<Vec<Reaction>> {
        let manager = self.inner.clone();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let res = manager
                    .reaction_entries()
                    .await?
                    .into_iter()
                    .map(|(user_id, inner)| Reaction {
                        client: client.clone(),
                        room: room.clone(),
                        inner,
                    })
                    .collect();
                Ok(res)
            })
            .await?
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = ()> {
        BroadcastStream::new(self.subscribe()).map(|f| f.unwrap_or_default())
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = models::Reaction::index_for(&self.inner.event_id());
        self.client.subscribe(key)
    }
}
