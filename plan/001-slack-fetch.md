# 001 - Slack Message Fetching

## Overview

Implement a rake task to fetch messages from Slack channels, storing them in the database for later classification and association with projects.

## Goals

- Fetch messages from Slack channels you're a member of
- Avoid duplicate messages on subsequent runs
- Provide clear visibility into what's being fetched
- Support both bulk fetching (all channels) and targeted fetching (specific channel)

## Requirements

### Functional Requirements

1. **Channel Discovery**
   - Fetch list of all channels the authenticated user is a member of
   - Store channel metadata (id, name) in `slack_channels` table
   - Update channel names if they've changed since last fetch

2. **Message Fetching**
   - Fetch messages from each channel
   - Support optional channel ID parameter to target specific channel(s)
   - Default behavior: fetch from all channels

3. **Time Range Logic**
   - **First run (no history)**: Fetch messages from last 30 days
   - **Subsequent runs**: Fetch messages since `last_fetched_at` timestamp
   - Use `last_fetched_at` per channel to track progress

4. **Duplicate Prevention**
   - Track `last_fetched_at` timestamp per channel in `slack_channels` table
   - Only fetch messages with timestamp > `last_fetched_at`
   - Rely on `slack_message_id` uniqueness constraint to prevent duplicates

5. **User Management**
   - Look up or create `Person` records for message authors
   - Match by `slack_user_id`
   - Fetch user profile from Slack API if creating new person

6. **Output Format**
   - Show which channels are being processed
   - Display count of new messages per channel
   - Concise, progress-indicator style output

### Data Model Changes

Add to `slack_channels` table:
- `last_fetched_at` (datetime, nullable)

### Slack API Calls

1. **conversations.list**
   - Purpose: Get all channels user is member of
   - Filter: `types=public_channel,private_channel` (exclude IMs/MPIMs for MVP)
   - Returns: channel id, name, is_member flag

2. **conversations.history**
   - Purpose: Fetch messages from a channel
   - Parameters:
     - `channel`: channel ID
     - `oldest`: timestamp for filtering (last_fetched_at or 30 days ago)
     - `limit`: 1000 (Slack's max per page)
   - Pagination: Use `cursor` if response has `has_more: true`
   - Returns: messages with ts (timestamp), user, text, thread_ts

3. **users.info**
   - Purpose: Get user profile when creating new Person
   - Parameters: `user`: user ID
   - Returns: real_name, display_name

### Error Handling

1. **API Rate Limits**
   - Slack rate limit: ~1 request per second per method
   - Handle 429 responses with exponential backoff
   - Log warning and continue with next channel

2. **Permission Errors**
   - Handle 403/not_in_channel errors gracefully
   - Log warning and skip channel
   - Don't fail entire rake task

3. **Network/Timeout Errors**
   - Retry up to 3 times with exponential backoff
   - Log error and continue with next channel

4. **Invalid Data**
   - Skip messages with missing required fields
   - Log warning with message ID
   - Continue processing remaining messages

### Transaction Handling

- Update `last_fetched_at` after successfully processing all messages from a channel
- Use database transaction to ensure messages and last_fetched_at are consistent
- If processing fails mid-channel, `last_fetched_at` remains unchanged (re-fetch on next run)

## Implementation Tasks

1. **Migration**: Add `last_fetched_at` to `slack_channels`
2. **Service Object**: Create `SlackMessageFetcher` service
   - `fetch_all_channels` method
   - `fetch_channel(channel_id)` method
   - Private methods for API calls, user lookup, message storage
3. **Rake Task**: Create `lib/tasks/slack.rake`
   - Task: `slack:fetch_messages[channel_id]`
   - Optional channel_id parameter
   - Call SlackMessageFetcher service
4. **Configuration**: Ensure `SLACK_API_TOKEN` is documented/required

## Usage Examples

```bash
# Fetch from all channels
dev-exec 'bin/rake slack:fetch_messages'

# Fetch from specific channel
dev-exec 'bin/rake slack:fetch_messages[C01234ABCD]'
```

## Sample Output

```
Fetching messages from Slack...
Discovered 5 channels

[1/5] #engineering (C01234ABCD): 47 new messages
[2/5] #design-system (C56789EFGH): 12 new messages
[3/5] #releases (C11111AAAA): 0 new messages
[4/5] #team-updates (C22222BBBB): 8 new messages
[5/5] #incidents (C33333CCCC): 3 new messages

✓ Fetched 70 total messages from 5 channels
```

## Future Considerations (Out of Scope for This Step)

- Fetch thread replies (currently only top-level messages)
- Real-time message fetching via Slack Events API
- Fetch from direct messages or multi-person DMs
- Update existing messages if edited
- Mark messages as deleted if removed from Slack
- Fetch reactions, attachments, file metadata
