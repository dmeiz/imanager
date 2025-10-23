# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

imanager is a CLI application for engineering managers to track Slack
communications across projects, with AI-powered message classification and
daily summaries.

**See plan/index.md for**: Full architecture, data models, implementation phases, and project vision.

## Development Environment

This project runs in a **devcontainer**:
- Ruby 3.3 / Rails 7.1 / SQLite 3
- All Ruby commands must use: `dev-exec '<command>'`

Examples:
```bash
dev-exec 'bundle install'
dev-exec 'bin/rails db:migrate'
dev-exec 'bin/rake test'
```

## Architecture Quick Reference

**Data Flow**: Slack API → Store messages → Background job (LLM classification) → Associate to projects → Generate summaries on-demand

**Key Models**: Projects ↔ ProjectMessages (with confidence scores) ↔ Messages. See plan.md for complete schema.

**Key Gems**: slack-ruby-client, anthropic/ruby-openai, sidekiq, sqlite3

## Common Commands

### Database

```bash
dev-exec 'bin/rails db:create'
dev-exec 'bin/rails db:migrate'
dev-exec 'bin/rails db:reset'
```

### Testing

```bash
dev-exec 'bin/rake test'
dev-exec 'bin/rake test TEST=test/models/project_test.rb'
```

### Background Jobs

```bash
dev-exec 'bundle exec sidekiq'
```

## Configuration

Required environment variables (set in `.env.development.local`):
```
SLACK_API_TOKEN=xoxb-...
ANTHROPIC_API_KEY=sk-ant-...  # or OPENAI_API_KEY
```

**Database**: SQLite databases are stored as files in `var/` directory:
- `var/development.sqlite3` - Development database
- `var/test.sqlite3` - Test database
- `var/production.sqlite3` - Production database

**Backups**: Simply copy the .sqlite3 file:
```bash
cp var/production.sqlite3 backups/prod_$(date +%Y%m%d).sqlite3
```

## Running in "Production" Mode

To run a separate production instance on your laptop (independent from development):

```bash
# Set environment variables in .env.production.local
# SLACK_API_TOKEN=xoxb-... (can use different token than dev)
# ANTHROPIC_API_KEY=sk-ant-...

# Run Rails server in production mode
RAILS_ENV=production bin/rails server -p 3001

# Run database migrations
RAILS_ENV=production bin/rails db:migrate

# Run console
RAILS_ENV=production bin/rails console
```

Since SQLite uses local files, dev and production run completely independently with no Docker Compose or separate database container needed.

## Key Constraints

- **CLI-only**: Use Rails' native command infrastructure (not Thor)
- **MVP is Slack-only**: No email/GitHub integration
- **Manual sync**: Not real-time
- **Background classification**: Message-to-project association runs async via Sidekiq

## Development Plan

The plan is captured in the plan directory. plan/index.md provides a high-level
overview of the project. Individual development steps are captured in numbered
files, for example:

- 000-slack-fetch.md
