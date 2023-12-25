use anyhow::{bail, Context, Result};
use matrix_sdk::{
    media::{MediaFormat, MediaRequest},
    room::RoomMember,
    ruma::api::client::user_directory::search_users,
    Account, Client, DisplayName,
};
use ruma_common::{OwnedRoomId, OwnedUserId};
use ruma_events::room::MediaSource;

use super::{
    common::{into_media_format, OptionBuffer, OptionString, ThumbnailSize},
    RUNTIME,
};

#[derive(Clone)]
pub struct PublicProfile {
    inner: search_users::v3::User,
    client: Client,
}

impl PublicProfile {
    pub fn new(inner: search_users::v3::User, client: Client) -> Self {
        PublicProfile { inner, client }
    }

    pub(crate) async fn avatar(&self, format: MediaFormat) -> Result<Option<Vec<u8>>> {
        let Some(url) = self.inner.avatar_url.as_ref() else { return Ok(None) };
        let request = MediaRequest {
            source: MediaSource::Plain(url.to_owned()),
            format,
        };
        let buf = self
            .client
            .media()
            .get_media_content(&request, true)
            .await?;
        Ok(Some(buf))
    }
}

#[derive(Clone)]
pub struct UserProfile {
    account: Option<Account>,
    public_profile: Option<PublicProfile>,
    user_id: OwnedUserId,
    member: Option<RoomMember>,
}

impl UserProfile {
    pub(crate) fn from_account(account: Account, user_id: OwnedUserId) -> Self {
        UserProfile {
            account: Some(account),
            user_id,
            member: None,
            public_profile: None,
        }
    }

    pub(crate) fn from_member(member: RoomMember) -> Self {
        UserProfile {
            account: None,
            user_id: member.user_id().to_owned(),
            member: Some(member),
            public_profile: None,
        }
    }

    pub(crate) fn from_search(public_profile: PublicProfile) -> Self {
        UserProfile {
            account: None,
            user_id: public_profile.inner.user_id.to_owned(),
            member: None,
            public_profile: Some(public_profile),
        }
    }

    pub fn user_id(&self) -> OwnedUserId {
        self.user_id.clone()
    }

    pub async fn has_avatar(&self) -> Result<bool> {
        if let Some(account) = self.account.clone() {
            return RUNTIME
                .spawn(async move {
                    let url = account.get_avatar_url().await?;
                    Ok(url.is_some())
                })
                .await?;
        }
        if let Some(member) = self.member.as_ref() {
            return Ok(member.avatar_url().is_some());
        }

        if let Some(public_profile) = self.public_profile.as_ref() {
            return Ok(public_profile.inner.avatar_url.is_some());
        }
        Ok(false)
    }

    pub async fn get_avatar(&self, thumb_size: Option<Box<ThumbnailSize>>) -> Result<OptionBuffer> {
        let format = into_media_format(thumb_size);
        if let Some(account) = self.account.clone() {
            return RUNTIME
                .spawn(async move {
                    let buf = account.get_avatar(format).await?;
                    Ok(OptionBuffer::new(buf))
                })
                .await?;
        }
        if let Some(member) = self.member.clone() {
            return RUNTIME
                .spawn(async move {
                    let buf = member.avatar(format).await?;
                    Ok(OptionBuffer::new(buf))
                })
                .await?;
        }

        if let Some(public_profile) = self.public_profile.clone() {
            return RUNTIME
                .spawn(async move {
                    let buf = public_profile.avatar(format).await?;
                    Ok(OptionBuffer::new(buf))
                })
                .await?;
        }
        Ok(OptionBuffer::new(None))
    }

    pub async fn get_display_name(&self) -> Result<OptionString> {
        if let Some(account) = self.account.clone() {
            return RUNTIME
                .spawn(async move {
                    let text = account.get_display_name().await?;
                    Ok(OptionString::new(text))
                })
                .await?;
        }
        if let Some(member) = self.member.clone() {
            let text = member.display_name().map(|x| x.to_string());
            return Ok(OptionString::new(text));
        }
        if let Some(public_profile) = self.public_profile.clone() {
            let text = public_profile.inner.display_name;
            return Ok(OptionString::new(text));
        }
        Ok(OptionString::new(None))
    }
}

#[derive(Clone)]
pub struct RoomProfile {
    client: Client,
    room_id: OwnedRoomId,
}

impl RoomProfile {
    pub(crate) fn new(client: Client, room_id: OwnedRoomId) -> Self {
        RoomProfile { client, room_id }
    }

    pub fn has_avatar(&self) -> Result<bool> {
        let room = self
            .client
            .get_room(&self.room_id)
            .context("Room not found")?;
        Ok(room.avatar_url().is_some())
    }

    pub async fn get_avatar(&self, thumb_size: Option<Box<ThumbnailSize>>) -> Result<OptionBuffer> {
        let room = self
            .client
            .get_room(&self.room_id)
            .context("Room not found")?;
        let format = into_media_format(thumb_size);
        RUNTIME
            .spawn(async move {
                let buf = room.avatar(format).await?;
                Ok(OptionBuffer::new(buf))
            })
            .await?
    }

    pub async fn get_display_name(&self) -> Result<OptionString> {
        let room = self
            .client
            .get_room(&self.room_id)
            .context("Room not found")?;
        RUNTIME
            .spawn(async move {
                let result = room.display_name().await?;
                match result {
                    DisplayName::Named(name) => Ok(OptionString::new(Some(name))),
                    DisplayName::Aliased(name) => Ok(OptionString::new(Some(name))),
                    DisplayName::Calculated(name) => Ok(OptionString::new(Some(name))),
                    DisplayName::EmptyWas(name) => Ok(OptionString::new(Some(name))),
                    DisplayName::Empty => Ok(OptionString::new(None)),
                }
            })
            .await?
    }
}
