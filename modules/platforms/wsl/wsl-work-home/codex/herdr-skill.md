---
name: herdr
description: Control Herdr, a terminal multiplexer for coding agents. Use only when the user explicitly asks to inspect or control Herdr panes, tabs, workspaces, commands, or agents.
---

# Herdr

Herdr manages workspaces, tabs, and panes for coding agents. This skill is
usable only from an agent running inside a Herdr-managed pane.

## Safety gate

Before any Herdr command that inspects or changes a session, run:

```sh
test "${HERDR_ENV:-}" = 1
```

If that fails, explain that the agent is not running inside Herdr and stop.

## Discover the live CLI

The installed binary is authoritative. Read the relevant help before using a
command:

```sh
herdr --help
herdr agent
herdr pane
herdr workspace
herdr tab
herdr integration
```

Use JSON responses and the opaque IDs they return. Do not infer IDs from the
sidebar or from examples. Herdr injects `HERDR_WORKSPACE_ID`, `HERDR_TAB_ID`,
and `HERDR_PANE_ID` into managed panes.

Useful read-only discovery commands include:

```sh
herdr workspace list
herdr pane current --current
herdr pane list --workspace "$HERDR_WORKSPACE_ID"
herdr agent list
```

Prefer `--current`, an explicit pane ID, or a unique live agent name over the
focused UI pane. Keep the user's focus by using `--no-focus` for background
work.

## Starting and prompting agents

An agent must be started in an existing available shell pane. Splitting panes
or creating a workspace is a topology decision; preserve the current tab and
directory unless the user asks for something else.

```sh
herdr pane split --current --direction right --cwd "$PWD" --no-focus
herdr agent start reviewer --kind codex --pane <pane-id>
herdr agent prompt reviewer "Review the current diff." --wait --timeout 120000
```

Read state and output through the agent surface:

```sh
herdr agent get reviewer
herdr agent read reviewer --source recent-unwrapped --lines 120
herdr agent wait reviewer --until blocked --timeout 120000
```

Use `herdr agent send-keys` only for intentional interactive controls such as
escape or interrupt. If output is on an alternate screen and cannot be read,
ask the agent to write its complete response to a temporary Markdown file and
then read that file directly.

## Boundaries

Do not close workspaces, tabs, panes, or sessions you did not create. Never
stop the Herdr server from an active session unless the user explicitly asks.
Codex is detected from its live terminal screen; its integration supplies
native session identity for restore, but does not replace screen-state
detection.
