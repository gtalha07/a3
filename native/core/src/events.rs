pub mod attachments;
pub mod bookmarks;
pub mod calendar;
pub mod comments;
mod common;
pub mod news;
pub mod pins;
pub mod room;
pub mod rsvp;
pub mod settings;
pub mod tasks;
pub mod three_pid;

pub use common::*;
use matrix_sdk_base::ruma::{
    events::{
        reaction::{ReactionEvent, ReactionEventContent},
        EventTypeDeHelper, StaticEventContent,
    },
    exports::{serde::de::Error as SerdeDeError, serde_json as smart_serde_json},
};

#[derive(Clone, Debug)]
pub enum AnyActerEvent {
    CalendarEvent(calendar::CalendarEventEvent),
    CalendarEventUpdate(calendar::CalendarEventUpdateEvent),

    Pin(pins::PinEvent),
    PinUpdate(pins::PinUpdateEvent),

    NewsEntry(news::NewsEntryEvent),
    NewsEntryUpdate(news::NewsEntryUpdateEvent),

    TaskList(tasks::TaskListEvent),
    TaskListUpdate(tasks::TaskListUpdateEvent),

    Task(tasks::TaskEvent),
    TaskUpdate(tasks::TaskUpdateEvent),
    TaskSelfAssign(tasks::TaskSelfAssignEvent),
    TaskSelfUnassign(tasks::TaskSelfUnassignEvent),

    // Generic Relative Features
    Comment(comments::CommentEvent),
    CommentUpdate(comments::CommentUpdateEvent),

    Attachment(attachments::AttachmentEvent),
    AttachmentUpdate(attachments::AttachmentUpdateEvent),

    Reaction(ReactionEvent),
    Rsvp(rsvp::RsvpEvent),
}

impl<'de> serde::Deserialize<'de> for AnyActerEvent {
    fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let json = Box::<smart_serde_json::value::RawValue>::deserialize(deserializer)?;
        let EventTypeDeHelper { ev_type, .. } =
            ::matrix_sdk_base::ruma::serde::from_raw_json_value(&json)?;
        match &*ev_type {
            calendar::CalendarEventEventContent::TYPE => {
                let event = smart_serde_json::from_str::<calendar::CalendarEventEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::CalendarEvent(event))
            }
            calendar::CalendarEventUpdateEventContent::TYPE => {
                let event =
                    smart_serde_json::from_str::<calendar::CalendarEventUpdateEvent>(json.get())
                        .map_err(D::Error::custom)?;
                Ok(Self::CalendarEventUpdate(event))
            }

            pins::PinEventContent::TYPE => {
                let event = smart_serde_json::from_str::<pins::PinEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Pin(event))
            }
            pins::PinUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<pins::PinUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::PinUpdate(event))
            }

            news::NewsEntryEventContent::TYPE => {
                let event = smart_serde_json::from_str::<news::NewsEntryEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::NewsEntry(event))
            }
            news::NewsEntryUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<news::NewsEntryUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::NewsEntryUpdate(event))
            }

            tasks::TaskListEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::TaskListEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::TaskList(event))
            }
            tasks::TaskListUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::TaskListUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::TaskListUpdate(event))
            }

            tasks::TaskEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::TaskEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Task(event))
            }
            tasks::TaskUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::TaskUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::TaskUpdate(event))
            }

            tasks::TaskSelfAssignEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::TaskSelfAssignEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::TaskSelfAssign(event))
            }

            tasks::TaskSelfUnassignEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::TaskSelfUnassignEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::TaskSelfUnassign(event))
            }

            comments::CommentEventContent::TYPE => {
                let event = smart_serde_json::from_str::<comments::CommentEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Comment(event))
            }
            comments::CommentUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<comments::CommentUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::CommentUpdate(event))
            }

            attachments::AttachmentEventContent::TYPE => {
                let event = smart_serde_json::from_str::<attachments::AttachmentEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Attachment(event))
            }
            attachments::AttachmentUpdateEventContent::TYPE => {
                let event =
                    smart_serde_json::from_str::<attachments::AttachmentUpdateEvent>(json.get())
                        .map_err(D::Error::custom)?;
                Ok(Self::AttachmentUpdate(event))
            }

            rsvp::RsvpEventContent::TYPE => {
                let event = smart_serde_json::from_str::<rsvp::RsvpEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Rsvp(event))
            }

            ReactionEventContent::TYPE => {
                let event =
                    ::matrix_sdk_base::ruma::exports::serde_json::from_str::<ReactionEvent>(
                        json.get(),
                    )
                    .map_err(D::Error::custom)?;
                Ok(Self::Reaction(event))
            }

            _ => Err(SerdeDeError::unknown_variant(
                &ev_type,
                &[
                    calendar::CalendarEventEventContent::TYPE,
                    calendar::CalendarEventUpdateEventContent::TYPE,
                    pins::PinEventContent::TYPE,
                    pins::PinUpdateEventContent::TYPE,
                    news::NewsEntryEventContent::TYPE,
                    news::NewsEntryUpdateEventContent::TYPE,
                    tasks::TaskListEventContent::TYPE,
                    tasks::TaskListUpdateEventContent::TYPE,
                    tasks::TaskEventContent::TYPE,
                    tasks::TaskUpdateEventContent::TYPE,
                    tasks::TaskSelfAssignEventContent::TYPE,
                    tasks::TaskSelfUnassignEventContent::TYPE,
                    comments::CommentEventContent::TYPE,
                    comments::CommentUpdateEventContent::TYPE,
                    attachments::AttachmentEventContent::TYPE,
                    attachments::AttachmentUpdateEventContent::TYPE,
                    rsvp::RsvpEventContent::TYPE,
                    ReactionEventContent::TYPE,
                ],
            )),
        }
    }
}
