use std::sync::Arc;

use acter_core::push::default_rules;
use anyhow::{bail, Context, Result};
use matrix_sdk::{
    notification_settings::{
        IsEncrypted, IsOneToOne, NotificationSettings as SdkNotificationSettings,
        RoomNotificationMode,
    },
    ruma::{
        api::client::push::{
            get_pushers, set_pusher, EmailPusherData, Pusher as RumaPusher, PusherIds, PusherInit,
            PusherKind,
        },
        assign,
        push::HttpPusherData,
    },
};

use futures::stream::StreamExt;
use matrix_sdk_ui::notification_client::{
    NotificationClient, NotificationEvent, NotificationItem as SdkNotificationItem,
    NotificationProcessSetup,
};
use ruma_client_api::push::{get_pushrules_all, set_pushrule, RuleScope};
use ruma_common::{EventId, OwnedRoomId, RoomId};
use tokio_stream::{wrappers::BroadcastStream, Stream};

use super::{
    message::{any_sync_event_to_message, sync_event_to_message},
    Client,
};

use crate::{RoomMessage, RUNTIME};

pub(crate) fn room_notification_mode_name(input: &RoomNotificationMode) -> String {
    match input {
        RoomNotificationMode::AllMessages => "all".to_owned(),
        RoomNotificationMode::MentionsAndKeywordsOnly => "mentions".to_owned(),
        RoomNotificationMode::Mute => "muted".to_owned(),
    }
}

pub(crate) fn notification_mode_from_input(input: &str) -> Option<RoomNotificationMode> {
    match input.trim().to_lowercase().as_str() {
        "all" => Some(RoomNotificationMode::AllMessages),
        "mentions" => Some(RoomNotificationMode::MentionsAndKeywordsOnly),
        "muted" => Some(RoomNotificationMode::Mute),
        _ => None,
    }
}

pub struct NotificationItem {
    pub(crate) inner: SdkNotificationItem,
    pub(crate) room_id: OwnedRoomId,
}

impl NotificationItem {
    fn new(inner: SdkNotificationItem, room_id: OwnedRoomId) -> Self {
        NotificationItem { inner, room_id }
    }
}

impl NotificationItem {
    pub fn is_invite(&self) -> bool {
        matches!(self.inner.event, NotificationEvent::Invite(_))
    }

    pub fn room_message(&self) -> Option<RoomMessage> {
        let NotificationEvent::Timeline(s) = &self.inner.event else {
            return None;
        };
        any_sync_event_to_message(s.clone(), self.room_id.clone())
    }
    // pub fn event(&self) -> NotificationEvent {
    //     self.inner.event
    // }
    pub fn sender_display_name(&self) -> Option<String> {
        self.inner.sender_display_name.clone()
    }

    pub fn sender_avatar_url(&self) -> Option<String> {
        self.inner.sender_avatar_url.clone()
    }

    pub fn room_display_name(&self) -> String {
        self.inner.room_display_name.clone()
    }

    pub fn room_avatar_url(&self) -> Option<String> {
        self.inner.room_avatar_url.clone()
    }

    pub fn room_canonical_alias(&self) -> Option<String> {
        self.inner.room_canonical_alias.clone()
    }

    pub fn is_room_encrypted(&self) -> Option<bool> {
        self.inner.is_room_encrypted
    }

    pub fn is_direct_message_room(&self) -> bool {
        self.inner.is_direct_message_room
    }

    pub fn joined_members_count(&self) -> u64 {
        self.inner.joined_members_count
    }

    pub fn is_noisy(&self) -> Option<bool> {
        self.inner.is_noisy
    }
}

pub struct Pusher {
    inner: RumaPusher,
    client: Client,
}

impl Pusher {
    fn new(inner: RumaPusher, client: Client) -> Self {
        Pusher { inner, client }
    }

    pub fn is_email_pusher(&self) -> bool {
        matches!(self.inner.kind, PusherKind::Email(_))
    }

    pub fn pushkey(&self) -> String {
        self.inner.ids.pushkey.clone()
    }

    pub fn app_id(&self) -> String {
        self.inner.ids.app_id.clone()
    }

    pub fn app_display_name(&self) -> String {
        self.inner.app_display_name.clone()
    }

    pub fn device_display_name(&self) -> String {
        self.inner.device_display_name.clone()
    }

    pub fn lang(&self) -> String {
        self.inner.lang.clone()
    }

    pub fn profile_tag(&self) -> Option<String> {
        self.inner.profile_tag.clone()
    }

    pub async fn delete(&self) -> Result<bool> {
        let client = self.client.core.client().clone();
        let app_id = self.app_id();
        let pushkey = self.pushkey();
        RUNTIME
            .spawn(async move {
                // FIXME: how to set `append = true` for single-device-multi-user-support...?!?
                let request = set_pusher::v3::Request::delete(PusherIds::new(pushkey, app_id));
                client.send(request, None).await?;
                Ok(false)
            })
            .await?
    }
}

impl Client {
    pub async fn get_notification_item(
        &self,
        room_id: String,
        event_id: String,
    ) -> Result<NotificationItem> {
        let client = self.core.client().clone();
        let room_id = RoomId::parse(room_id)?;
        let event_id = EventId::parse(event_id)?;
        RUNTIME
            .spawn(async move {
                let notif_client = NotificationClient::builder(
                    client,
                    NotificationProcessSetup::MultipleProcesses,
                )
                .await?
                .build();

                let notif = notif_client
                    .get_notification(&room_id, &event_id)
                    .await?
                    .context("(hidden notification)")?;
                Ok(NotificationItem::new(notif, room_id))
            })
            .await?
    }
    pub async fn notification_settings(&self) -> Result<NotificationSettings> {
        let client = self.core.client().clone();
        Ok(RUNTIME
            .spawn(async move { NotificationSettings::new(client.notification_settings().await) })
            .await?)
    }

    pub async fn add_email_pusher(
        &self,
        device_name: String,
        app_name: String,
        email: String,
        lang: Option<String>,
    ) -> Result<bool> {
        let pusher_data = PusherInit {
            ids: PusherIds::new(email, "m.email".to_owned()),
            kind: PusherKind::Email(EmailPusherData::new()),
            app_display_name: app_name,
            device_display_name: device_name,
            profile_tag: None,
            lang: lang.unwrap_or("en".to_owned()),
        };
        let client = self.core.client().clone();
        RUNTIME
            .spawn(async move {
                // FIXME: how to set `append = true` for single-device-multi-user-support...?!?
                let request = set_pusher::v3::Request::post(pusher_data.into());
                client.send(request, None).await?;
                Ok(false)
            })
            .await?
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn add_pusher(
        &self,
        app_id: String,
        token: String,
        device_name: String,
        app_name: String,
        server_url: String,
        with_ios_defaults: bool,
        lang: Option<String>,
    ) -> Result<bool> {
        let client = self.core.client().clone();
        let device_id = client.device_id().context("DeviceId not found")?;
        let push_data = if with_ios_defaults {
            assign!(HttpPusherData::new(server_url), {
                default_payload: serde_json::json!({
                        "aps": {
                            "mutable-content": 1,
                            "content-available": 1
                    },
                    "device_id": device_id,
                })
            })
        } else {
            assign!(HttpPusherData::new(server_url), {
                default_payload: serde_json::json!({
                    "device_id": device_id,
                })
            })
        };
        let pusher_data = PusherInit {
            ids: PusherIds::new(token, app_id),
            kind: PusherKind::Http(push_data),
            app_display_name: app_name,
            device_display_name: device_name,
            profile_tag: None,
            lang: lang.unwrap_or("en".to_owned()),
        };
        RUNTIME
            .spawn(async move {
                // FIXME: how to set `append = true` for single-device-multi-user-support...?!?
                let request = set_pusher::v3::Request::post(pusher_data.into());
                client.send(request, None).await?;
                Ok(false)
            })
            .await?
    }

    pub async fn pushers(&self) -> Result<Vec<Pusher>> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let resp = client
                    .core
                    .client()
                    .send(get_pushers::v3::Request::new(), None)
                    .await?;
                Ok(resp
                    .pushers
                    .into_iter()
                    .map(|inner| Pusher::new(inner, client.clone()))
                    .collect())
            })
            .await?
    }

    pub async fn install_default_acter_push_rules(&self) -> Result<bool> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                for rule in default_rules() {
                    let resp = client
                        .core
                        .client()
                        .send(
                            set_pushrule::v3::Request::new(RuleScope::Global, rule),
                            None,
                        )
                        .await?;
                }
                Ok(true)
            })
            .await?
    }

    pub async fn push_rules(&self) -> Result<ruma::push::Ruleset> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let resp = client
                    .core
                    .client()
                    .send(get_pushrules_all::v3::Request::new(), None)
                    .await?;
                Ok(resp.global)
            })
            .await?
    }
}

#[derive(Debug, Clone)]
pub struct NotificationSettings {
    inner: Arc<SdkNotificationSettings>,
}
impl NotificationSettings {
    pub fn new(inner: SdkNotificationSettings) -> Self {
        NotificationSettings {
            inner: Arc::new(inner),
        }
    }
    pub fn changes_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.inner.subscribe_to_changes()).map(|_| true)
    }

    pub async fn default_notification_mode(
        &self,
        is_encrypted: bool,
        is_one_to_one: bool,
    ) -> Result<String> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let mode = inner
                    .get_default_room_notification_mode(
                        IsEncrypted::from(is_encrypted),
                        IsOneToOne::from(is_one_to_one),
                    )
                    .await;
                Ok(room_notification_mode_name(&mode))
            })
            .await?
    }

    pub async fn set_default_notification_mode(
        &self,
        is_encrypted: bool,
        is_one_to_one: bool,
        mode: String,
    ) -> Result<bool> {
        let new_level =
            notification_mode_from_input(&mode).context("Unknown Notification Level")?;
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                inner
                    .set_default_room_notification_mode(
                        IsEncrypted::from(is_encrypted),
                        IsOneToOne::from(is_one_to_one),
                        new_level,
                    )
                    .await?;
                Ok(true)
            })
            .await?
    }
}
