# Engineering Manager Project Tracker - MVP Plan

## Overview

A CLI application to help engineering managers track project communications from team members, identify blockers, and catch up on progress across multiple projects.

## Core Features

### 1. Project Management
- Define projects with names and descriptions
- Associate team members to projects
- Configure keywords/phrases per project for message matching
- Associate specific Slack channels to projects

### 2. Slack Integration
- Connect to Slack API
- Monitor specific channels (configurable)
- Collect all channel activity (not just @mentions)
- Store messages for processing
- Forward-looking only (no historical data import for MVP)

### 3. AI-Powered Project Association
Use LLM to analyze messages and associate them to projects based on:
- Channel association (if project has dedicated channel)
- Team member participation (who's in the conversation)
- Keywords/phrases configured per project
- Contextual understanding of message content

### 4. Daily Summaries (On-Demand)
Generate summary for a specific project showing:
- Progress updates mentioned
- Any blockers or issues raised
- Key decisions or discussions
- Activity level indicator (to spot stalled projects)

### 5. CLI Interface
Commands:
- `imanager projects list` - List all projects
- `imanager projects create` - Add new project
- `imanager projects update` - Update project config
- `imanager summary <project_name> [date]` - Generate summary (defaults to today)
- `imanager sync` - Fetch latest Slack messages

## Technical Architecture

### Stack
- **Framework**: Ruby on Rails (API/CLI mode)
- **Database**: MySQL 8.0 (running in devcontainer)
- **Language**: Ruby 3.3
- **AI/LLM**: Anthropic Claude API or OpenAI GPT-4

### Data Model

```
Projects
- id
- name
- description
- keywords (JSON array)
- team_member_ids (JSON array)
- slack_channel_ids (JSON array)
- created_at
- updated_at

TeamMembers
- id
- name
- slack_user_id
- created_at
- updated_at

SlackChannels
- id
- channel_id (Slack's ID)
- channel_name
- created_at
- updated_at

Messages
- id
- slack_message_id (unique)
- channel_id
- user_id (references TeamMembers)
- content (text)
- timestamp
- thread_ts (for threading)
- created_at
- updated_at

ProjectMessages (join table)
- id
- project_id
- message_id
- confidence_score (decimal, 0-1)
- association_reason (enum: channel/keyword/member/context)
- created_at
- updated_at

Summaries
- id
- project_id
- date
- summary_content (text)
- metadata (JSON: message_count, participants, etc.)
- created_at
- updated_at
```

### Architecture Flow

1. **Sync Process (manual via CLI)**
   ```
   Slack API → Fetch new messages → Store in DB
   ```

2. **Classification Process (background job)**
   ```
   New messages → Claude/OpenAI API → Analyze against projects →
   Create ProjectMessage associations
   ```

3. **Summary Generation (on-demand via CLI)**
   ```
   Get project messages for date → Claude/OpenAI API →
   Generate structured summary → Store & display
   ```

### Key Gems

- `slack-ruby-client` - Slack API integration
- `anthropic` or `ruby-openai` - LLM integration
- Rails commands - CLI interface (not Thor, use native Rails)
- `sidekiq` - Background job processing (for classification)
- `mysql2` - MySQL database adapter

## Implementation Phases

### Phase 1: Foundation (Week 1)
- [x] Initialize devcontainer with Ruby/Rails
- [ ] Create Rails app with MySQL
- [ ] Set up database schema and migrations
- [ ] Create ActiveRecord models with associations
- [ ] Basic CLI commands for project CRUD

**Deliverables:**
- Working Rails app in devcontainer
- Database schema with all tables
- Basic project management via CLI

### Phase 2: Message Collection (Week 1-2)
- [ ] Slack API authentication setup
- [ ] Implement sync command to fetch messages
- [ ] Store messages from designated channels
- [ ] Basic message display/query in CLI
- [ ] Handle pagination and rate limits

**Deliverables:**
- Ability to authenticate with Slack
- Sync command that fetches and stores messages
- View messages for a channel/date range

### Phase 3: AI Integration (Week 2-3)
- [ ] Set up Claude/OpenAI API credentials
- [ ] Create prompt templates for message classification
- [ ] Implement background job for classification
- [ ] Associate messages to projects with confidence scores
- [ ] Tune prompts for accuracy based on test data

**Deliverables:**
- Messages automatically classified to projects
- Confidence scoring system working
- Background processing of new messages

### Phase 4: Summary Generation (Week 3-4)
- [ ] Create prompt templates for summaries
- [ ] Implement summary generation command
- [ ] Format output for CLI readability
- [ ] Store summaries for historical reference
- [ ] Refine summary format based on feedback

**Deliverables:**
- `imanager summary` command working
- Human-readable summaries highlighting:
  - Progress updates
  - Blockers
  - Activity levels
  - Key participants

## What Makes This a True MVP

### Included (MVP Scope)
- Single data source (Slack only)
- Manual sync (not real-time)
- CLI interface (no web UI)
- On-demand summaries (not automatic)
- Specific channels (not all channels)
- Forward-looking only (no historical import)

### Explicitly Excluded (Future Enhancements)
- Email integration
- GitHub integration
- Real-time message streaming
- Web dashboard
- Automatic daily digest emails
- Historical data import
- Multi-user support
- Slack bot interface
- Mobile app

## Configuration

### Environment Variables
```
SLACK_API_TOKEN=<slack_bot_token>
ANTHROPIC_API_KEY=<claude_api_key>
# OR
OPENAI_API_KEY=<openai_api_key>

DATABASE_HOST=mysql80
DATABASE_PORT=3306
DATABASE_NAME=imanager_development
DATABASE_USERNAME=root
DATABASE_PASSWORD=root
```

### Slack App Setup
Required scopes:
- `channels:history` - Read messages from public channels
- `channels:read` - List public channels
- `users:read` - Get user information

## Success Metrics

For MVP, success means:
1. Can sync messages from 3+ Slack channels
2. AI correctly associates 80%+ of messages to projects
3. Summaries accurately reflect day's activity
4. Can identify stalled projects (no activity in N days)
5. Can identify blockers mentioned in discussions
6. Daily workflow takes <5 minutes to catch up on all projects

## Next Steps After MVP

1. Add email integration (Gmail API)
2. Add GitHub integration (PR activity, issue comments)
3. Build web dashboard for easier visualization
4. Implement automatic daily digest emails
5. Add real-time Slack bot for instant updates
6. Historical data import capability
7. Multi-user support for team leads
8. Sentiment analysis on team communications
