use std::ops::Deref;

use acter_core::{
    activities::Activity as CoreActivity,
    models::{status::membership::MembershipChange as CoreMembershipChange, ActerModel},
    referencing::IndexKey,
};
use futures::{FutureExt, Stream, StreamExt};
use ruma::{EventId, OwnedEventId, OwnedRoomId, RoomId};
use tokio::sync::broadcast::Receiver;
use tokio_stream::wrappers::BroadcastStream;

use super::{Client, RUNTIME};

#[cfg(any(test, feature = "testing"))]
use acter_core::activities::ActivityContent;
#[derive(Clone, Debug)]
pub struct MembershipChange(CoreMembershipChange);

impl MembershipChange {
    pub fn user_id_str(&self) -> String {
        self.0.user_id.to_string()
    }
    pub fn display_name(&self) -> Option<String> {
        self.0.display_name.clone()
    }
    pub fn avatar_url(&self) -> Option<String> {
        self.0.avatar_url.as_ref().map(|a| a.to_string())
    }
    pub fn reason(&self) -> Option<String> {
        self.0.reason.clone()
    }
}

#[derive(Clone, Debug)]
pub struct Activity {
    inner: CoreActivity,
    client: Client,
}

impl Activity {
    #[cfg(any(test, feature = "testing"))]
    pub fn content(&self) -> &ActivityContent {
        self.inner.content()
    }

    pub fn membership_change(&self) -> Option<MembershipChange> {
        self.inner.membership_change().map(MembershipChange)
    }

    pub fn sender_id_str(&self) -> String {
        self.inner.event_meta().sender.to_string()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.event_meta().origin_server_ts.get().into()
    }

    pub fn room_id_str(&self) -> String {
        self.inner.event_meta().room_id.to_string()
    }

    pub fn event_id_str(&self) -> String {
        self.inner.event_meta().event_id.to_string()
    }
}

impl Deref for Activity {
    type Target = CoreActivity;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

#[derive(Debug, Clone)]
pub struct Activities {
    index: IndexKey,
    client: Client,
}

impl Activities {
    pub async fn get_ids(&self, offset: u32, limit: u32) -> anyhow::Result<Vec<String>> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                anyhow::Ok(
                    me.client
                        .store()
                        .get_list(&me.index)
                        .await?
                        .filter_map(|a| {
                            // potential optimization: do the check without conversation and
                            // return the event id if feasible
                            let event_id = a.event_id().to_string();
                            CoreActivity::try_from(a).map(|_| event_id).ok()
                        })
                        .skip(offset as usize)
                        .take(limit as usize)
                        .collect(),
                )
            })
            .await?
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|f| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(self.index.clone())
    }
}

impl Client {
    pub async fn activity(&self, key: String) -> anyhow::Result<Activity> {
        let ev_id = EventId::parse(key)?;
        let client = self.clone();

        Ok(RUNTIME
            .spawn(async move {
                client
                    .core
                    .activity(&ev_id)
                    .await
                    .map(|inner| Activity { inner, client })
            })
            .await??)
    }

    pub fn activities_for_room(&self, room_id: String) -> anyhow::Result<Activities> {
        Ok(Activities {
            index: IndexKey::RoomHistory(RoomId::parse(room_id)?),
            client: self.clone(),
        })
    }
    pub fn activities_for_obj(&self, object_id: String) -> anyhow::Result<Activities> {
        Ok(Activities {
            index: IndexKey::ObjectHistory(EventId::parse(object_id)?),
            client: self.clone(),
        })
    }
}
