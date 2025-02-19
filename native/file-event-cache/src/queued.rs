use crate::EventCacheStore;
use async_trait::async_trait;
use matrix_sdk::{deserialized_responses::TimelineEvent, ruma::OwnedEventId};
use matrix_sdk_base::{
    event_cache::{
        store::media::{IgnoreMediaRetentionPolicy, MediaRetentionPolicy},
        Event, Gap,
    },
    linked_chunk::{RawChunk, Update},
    media::MediaRequestParameters,
    ruma::{MxcUri, RoomId},
};
use std::sync::Arc;
use tokio::sync::Semaphore;
use tracing::instrument;

#[derive(Debug)]
pub struct QueuedEventCacheStore<T>
where
    T: EventCacheStore,
{
    inner: T,
    queue: Arc<Semaphore>,
}

impl<T> QueuedEventCacheStore<T>
where
    T: EventCacheStore,
{
    pub fn new(store: T, queue_size: usize) -> Self {
        QueuedEventCacheStore {
            inner: store,
            queue: Arc::new(Semaphore::new(queue_size)),
        }
    }
}

#[async_trait]
impl<T> EventCacheStore for QueuedEventCacheStore<T>
where
    T: EventCacheStore,
{
    type Error = T::Error;

    async fn try_take_leased_lock(
        &self,
        lease_duration_ms: u32,
        key: &str,
        holder: &str,
    ) -> Result<bool, Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner
            .try_take_leased_lock(lease_duration_ms, key, holder)
            .await
    }

    async fn handle_linked_chunk_updates(
        &self,
        room_id: &RoomId,
        updates: Vec<Update<Event, Gap>>,
    ) -> Result<(), Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner
            .handle_linked_chunk_updates(room_id, updates)
            .await
    }

    async fn reload_linked_chunk(
        &self,
        room_id: &RoomId,
    ) -> Result<Vec<RawChunk<TimelineEvent, Gap>>, Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.reload_linked_chunk(room_id).await
    }

    #[instrument(skip_all)]
    async fn add_media_content(
        &self,
        request: &MediaRequestParameters,
        content: Vec<u8>,
        ignore_policy: IgnoreMediaRetentionPolicy,
    ) -> Result<(), Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner
            .add_media_content(request, content, ignore_policy)
            .await
    }

    #[instrument(skip_all)]
    async fn get_media_content(
        &self,
        request: &MediaRequestParameters,
    ) -> Result<Option<Vec<u8>>, Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.get_media_content(request).await
    }
    #[instrument(skip_all)]
    async fn get_media_content_for_uri(
        &self,
        uri: &MxcUri,
    ) -> Result<Option<Vec<u8>>, Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.get_media_content_for_uri(uri).await
    }

    #[instrument(skip_all)]
    async fn remove_media_content(
        &self,
        request: &MediaRequestParameters,
    ) -> Result<(), Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.remove_media_content(request).await
    }

    #[instrument(skip_all)]
    async fn remove_media_content_for_uri(&self, uri: &MxcUri) -> Result<(), Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.remove_media_content_for_uri(uri).await
    }

    #[instrument(skip_all)]
    async fn replace_media_key(
        &self,
        from: &MediaRequestParameters,
        to: &MediaRequestParameters,
    ) -> Result<(), Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.replace_media_key(from, to).await
    }

    fn media_retention_policy(&self) -> MediaRetentionPolicy {
        self.inner.media_retention_policy()
    }

    async fn set_media_retention_policy(
        &self,
        policy: MediaRetentionPolicy,
    ) -> Result<(), Self::Error> {
        self.inner.set_media_retention_policy(policy).await
    }
    async fn set_ignore_media_retention_policy(
        &self,
        request: &MediaRequestParameters,
        ignore_policy: IgnoreMediaRetentionPolicy,
    ) -> Result<(), Self::Error> {
        self.inner
            .set_ignore_media_retention_policy(request, ignore_policy)
            .await
    }

    async fn clear_all_rooms_chunks(&self) -> Result<(), Self::Error> {
        self.inner.clear_all_rooms_chunks().await
    }

    async fn clean_up_media_cache(&self) -> Result<(), Self::Error> {
        self.inner.clean_up_media_cache().await
    }

    async fn filter_duplicated_events(
        &self,
        room_id: &RoomId,
        events: Vec<OwnedEventId>,
    ) -> Result<Vec<OwnedEventId>, Self::Error> {
        self.inner.filter_duplicated_events(room_id, events).await
    }
}
