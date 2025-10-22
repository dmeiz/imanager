# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

imanager is a CLI application for engineering managers to track Slack
communications across projects, with AI-powered message classification and
daily summaries.

**See plan/index.md for**: Full architecture, data models, implementation phases, and project vision.

## Development Environment

This project runs in a **devcontainer**:
- Ruby 3.3 / Rails 7.1 / MySQL 8.0
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

**Key Gems**: slack-ruby-client, anthropic/ruby-openai, sidekiq, mysql2

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

Database config is already set in docker-compose.yml.

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
