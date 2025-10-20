## Description

iManager helps engineering managers track project communications from team
members, identify blockers, and catch up on progress across multiple projects.

The app will:

- Fetches Slack messages from various channels that I'm a member of
- Associates messages to projects
- Summarizes the messages about a project for the day

I will use the app to:

- Catch up on progress of each project
- Determine if there hasn't been any movement on a project (in which case I would to follow up with an engineer)
- Determine if there was a blocker that I should weigh in on

## Scope

This is an MVP whose goal is to explore using LLMs to analyze messages,
associate them with projects, and generate daily summaries.

We'll focus on fetching messages and associating them to projects.

## Data Model

### Project

Attributes:
- name
- description

Associations:
- Has and belongs to many people
- Has many messages

### Person

Attributes:
- name
- slack_user_id

Associations:
- Has and belongs to many projects

### Messages

Attributes:
- slack_message_id (unique)
- channel_id
- user_id (references TeamMembers)
- content (text)
- timestamp
- thread_ts (for threading)

Associations:
- Belongs to team person
- Belongs to project

### SlackChannel

Attributes:
- channel_id (Slack's ID)
- channel_name

## Tech Stack

- **Framework**: Ruby on Rails (API/CLI mode)
- **Database**: MySQL 8.0 (running in devcontainer)
- **Language**: Ruby 3.3
- **AI/LLM**: Anthropic Claude API or OpenAI GPT-4

