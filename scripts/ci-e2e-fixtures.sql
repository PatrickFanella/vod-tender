-- Synthetic browser fixtures. Loaded only through the job-owned CI database helper.
BEGIN;
INSERT INTO vods (twitch_vod_id, title, date, channel, processed, youtube_url,
                  download_state, download_bytes, download_total, download_retries, progress_updated_at)
VALUES
  ('ci-e2e-1', 'Test VOD 1', '2025-10-19T10:00:00Z', '', true, 'https://youtube.com/watch?v=test1',
   'completed', 100000000, 100000000, 0, '2025-10-19T10:30:00Z'),
  ('ci-e2e-2', 'Test VOD 2', '2025-10-19T11:00:00Z', '', false, NULL,
   'downloading', 91000000, 200000000, 1, '2025-10-19T11:15:00Z')
ON CONFLICT (twitch_vod_id) DO UPDATE SET
  title = EXCLUDED.title, date = EXCLUDED.date, channel = EXCLUDED.channel,
  processed = EXCLUDED.processed, youtube_url = EXCLUDED.youtube_url,
  download_state = EXCLUDED.download_state, download_bytes = EXCLUDED.download_bytes,
  download_total = EXCLUDED.download_total, download_retries = EXCLUDED.download_retries,
  progress_updated_at = EXCLUDED.progress_updated_at;

DELETE FROM chat_messages WHERE vod_id IN ('ci-e2e-1', 'ci-e2e-2');
INSERT INTO chat_messages (vod_id, channel, username, message, abs_timestamp, rel_timestamp)
VALUES ('ci-e2e-1', '', 'testuser1', 'Hello world!', '2025-10-19T10:05:00Z', 300),
       ('ci-e2e-1', '', 'testuser2', 'Great stream!', '2025-10-19T10:05:10Z', 310);
COMMIT;
