---
name: google-calendar-mcp
description: >
  Use this skill whenever the user wants to interact with Google Calendar via the
  google-calendar-mcp MCP server. Trigger for any request involving viewing, creating,
  updating, deleting, or scheduling calendar events — even casual phrasing like "what's
  on my calendar", "add a meeting", "reschedule my event", "clear Thursday", or "set up
  a recurring standup". Also trigger when the user wants to re-authenticate or switch
  Google accounts mid-session. Always use this skill when Google Calendar tools are
  available and the user mentions anything related to their schedule, appointments,
  meetings, reminders, or recurring events.
compatibility:
  required_tools:
    - google-calendar-mcp (MCP server must be connected and configured)
  dependencies:
    - Node.js (for npx install)
    - Google Cloud Project with Calendar API enabled
    - OAuth2 credentials (GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET)
---

# Google Calendar MCP Skill

This skill covers using the `google-calendar-mcp` MCP server to manage Google Calendar
events directly through Claude. The server communicates via STDIO and handles OAuth2
authentication automatically.

## Available Tools

| Tool | Purpose |
|---|---|
| `getEvents` | List/search events with optional time range and result limits |
| `createEvent` | Create a new event (supports all-day, timed, recurring, attendees, color) |
| `updateEvent` | Partially update an existing event without losing existing fields |
| `deleteEvent` | Delete an event by ID |
| `authenticate` | Re-authenticate or switch Google accounts without restarting |

---

## Tool Usage Reference

### getEvents
Retrieve events from the primary calendar (or a specific one).

```json
{
  "calendarId": "primary",         // optional; defaults to primary
  "timeMin": "2025-03-01T00:00:00Z",  // optional ISO 8601
  "timeMax": "2025-03-31T23:59:59Z",  // optional ISO 8601
  "maxResults": 10,                // optional; default 10
  "orderBy": "startTime"           // optional: "startTime" or "updated"
}
```

**Tips:**
- Omit `timeMin`/`timeMax` to get the next N upcoming events.
- Use `orderBy: "updated"` to find recently modified events.
- Empty strings, null, and undefined are safely ignored — Zod defaults apply.

---

### createEvent
Create a new event. All fields except `summary` and the `start`/`end` blocks are optional.

```json
{
  "calendarId": "primary",
  "event": {
    "summary": "Team Standup",
    "description": "Daily sync",
    "location": "Zoom",
    "start": {
      "dateTime": "2025-03-15T09:00:00-05:00",
      "timeZone": "America/Chicago"
    },
    "end": {
      "dateTime": "2025-03-15T09:30:00-05:00",
      "timeZone": "America/Chicago"
    },
    "attendees": [
      { "email": "colleague@example.com", "displayName": "Jane" }
    ],
    "colorId": "5",
    "recurrence": ["RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR"]
  }
}
```

**All-day events:** Use `"date": "2025-03-15"` instead of `dateTime`.

**Color IDs:**
| ID | Color |
|---|---|
| 1 | Lavender |
| 2 | Sage |
| 3 | Grape |
| 4 | Flamingo |
| 5 | Banana |
| 6 | Tangerine |
| 7 | Peacock |
| 8 | Blueberry |
| 9 | Basil |
| 10 | Tomato |
| 11 | Graphite |

**Recurrence (RFC 5545 RRULE examples):**
- Daily: `RRULE:FREQ=DAILY`
- Weekly on Mon/Wed/Fri: `RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR`
- Monthly on the 1st: `RRULE:FREQ=MONTHLY;BYMONTHDAY=1`
- Until a date: `RRULE:FREQ=WEEKLY;UNTIL=20251231T000000Z`
- N times: `RRULE:FREQ=DAILY;COUNT=5`

---

### updateEvent
Fetch + merge approach: the server fetches the existing event first, then merges only
the fields you provide. Safe for partial updates — unspecified fields are preserved.

```json
{
  "calendarId": "primary",
  "eventId": "abc123xyz",
  "event": {
    "summary": "Updated Title",
    "start": {
      "dateTime": "2025-03-15T10:00:00-05:00",
      "timeZone": "America/Chicago"
    },
    "end": {
      "dateTime": "2025-03-15T10:30:00-05:00",
      "timeZone": "America/Chicago"
    }
  }
}
```

**Note:** `eventId` is required. Get it from `getEvents` results.

---

### deleteEvent

```json
{
  "calendarId": "primary",
  "eventId": "abc123xyz"
}
```

Always confirm with the user before deleting, especially for recurring events.

---

### authenticate
Triggers the OAuth2 re-authentication flow. Useful when switching Google accounts
or if the current token has expired.

```json
{}
```

No parameters needed. Claude Desktop will open a browser window for consent.

---

## Workflow Patterns

### "What's on my calendar this week?"
1. Get today's date and compute the week's `timeMin`/`timeMax`.
2. Call `getEvents` with those bounds.
3. Present events in a readable format (title, date/time, location if set).

### "Schedule a meeting with X on Friday at 2pm"
1. Determine the correct Friday date and the user's timezone (ask if unknown).
2. Call `createEvent` with the provided details.
3. Confirm back: event title, date/time, and any attendees.

### "Move my 3pm meeting to 4pm"
1. Call `getEvents` to find the event (filter by timeMin/timeMax around 3pm).
2. Identify the correct `eventId`.
3. Call `updateEvent` with the new `start`/`end` times only.

### "Delete my dentist appointment"
1. Call `getEvents` to locate the event.
2. Confirm with the user: "I found 'Dentist - Dr. Smith' on March 20 at 10am. Delete this?"
3. On confirmation, call `deleteEvent`.

### "Set up a weekly team sync every Monday at 9am"
1. Call `createEvent` with `recurrence: ["RRULE:FREQ=WEEKLY;BYDAY=MO"]`.
2. Confirm the first occurrence and recurrence pattern back to the user.

---

## Setup & Configuration

### One-time Google Cloud Setup
1. Create a project at [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the **Google Calendar API**
3. Create **OAuth 2.0 credentials** (Desktop application type)
4. Note your `client_id` and `client_secret`

### Claude Desktop Config (`claude_desktop_config.json`)
```json
{
  "mcpServers": {
    "google-calendar": {
      "command": "npx",
      "args": ["-y", "@takumi0706/google-calendar-mcp"],
      "env": {
        "GOOGLE_CLIENT_ID": "your_client_id",
        "GOOGLE_CLIENT_SECRET": "your_client_secret",
        "GOOGLE_REDIRECT_URI": "http://localhost:4153/oauth2callback"
      }
    }
  }
}
```

### Remote/Container Environments
If `localhost` isn't accessible, add `USE_MANUAL_AUTH=true` to the `env` block.
This switches to a readline-based flow where you paste the authorization code manually.

### Optional Environment Variables
| Variable | Default | Purpose |
|---|---|---|
| `TOKEN_ENCRYPTION_KEY` | auto-generated | AES-256-GCM token encryption key |
| `AUTH_PORT` | 4153 | OAuth callback server port |
| `AUTH_HOST` | localhost | OAuth callback server host |
| `PORT` | 3000 | MCP server port |
| `HOST` | localhost | MCP server host |
| `USE_MANUAL_AUTH` | false | Manual auth code entry mode |

---

## Error Handling

| Error | Cause | Fix |
|---|---|---|
| `-32602` invalid params | Empty string passed to a required param | Update to v1.0.7+ (handled automatically) |
| `Invalid state parameter` | Re-auth in older version | Update to v1.0.3+; or close port 4153 and restart |
| Auth fails / token expired | Stale token or account switch | Use the `authenticate` tool to re-authenticate |
| `Connection error` | Multiple server instances | Ensure only one instance is running |
| JSON parse errors | Malformed JSON-RPC messages | Update to v0.6.7+ |

---

## Key Notes

- **Timezone**: Always use IANA timezone strings (e.g., `"America/Chicago"`, `"America/New_York"`). Ask the user if unsure.
- **Event IDs**: IDs are returned in `getEvents` results — always use `getEvents` first when you need to update or delete.
- **Recurring events**: Modifying a single instance vs. all future instances is not yet supported — `updateEvent` applies to the event as a whole.
- **Security**: Tokens are stored in memory only (not on disk) and are encrypted with AES-256-GCM.
- **Partial updates are safe**: `updateEvent` merges with existing data, so you only need to pass the fields changing.