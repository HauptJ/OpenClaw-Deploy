---
name: mcp-trello
description: >
  Use this skill whenever the user wants to interact with Trello using the mcp-trello MCP server.
  Trigger on any request involving Trello boards, cards, lists, or activity — including creating,
  updating, moving, or archiving cards and lists; checking assigned cards; reviewing recent board
  activity; or managing board members. Also trigger when the user asks to "set up Trello", "find
  my board ID", or "configure the Trello MCP server". Use even if the user just says things like
  "add a card", "show my Trello tasks", "move this to Done", or "what's on my board" — these
  are strong signals to use this skill.
compatibility:
  required_tools:
    - mcp-trello (MCP server must be connected and configured)
  environment_variables:
    - trelloApiKey (required)
    - trelloToken (required)
    - trelloBoardId (optional, but required for board-specific tools)
---

# MCP Trello Skill

This skill guides Claude in using the `mcp-trello` MCP server to read and manage Trello boards, cards, and lists on behalf of the user.

---

## Setup & Configuration

Before using any tools, confirm the server is connected. If tools are unavailable, direct the user to install and configure the server.

### Installation (Smithery — recommended)

```bash
npx -y @smithery/cli install @Hint-Services/mcp-trello --client claude
```

### Manual MCP config

```json
{
  "mcpServers": {
    "trello": {
      "command": "npx",
      "args": ["-y", "@Hint-Services/mcp-trello"],
      "env": {
        "trelloApiKey": "your-api-key",
        "trelloToken": "your-token",
        "trelloBoardId": "your-24-char-board-id"
      }
    }
  }
}
```

### Getting credentials

- **API Key**: https://trello.com/app-key
- **Token**: Generate from the API Key page
- **Board ID**: ⚠️ The board ID is NOT the short code in the URL (e.g. `/b/a1b2c3d4/`). It is a full 24-character ID. Use `getMyBoards` to retrieve it, then copy the `id` field (not `shortLink`).

---

## Available Tools

### Board Management

| Tool | Requires `trelloBoardId`? | Description |
|------|--------------------------|-------------|
| `getMyBoards` | No | List all boards for the authenticated user. Use this first to find the board ID. |
| `getLists` | Yes | Get all lists on the configured board. |
| `addList` | Yes | Add a new list to the board. |
| `archiveList` | Yes | Archive a list (hides it from the board). |
| `getRecentActivity` | Yes | Fetch recent activity/actions on the board. |

### Card Management

| Tool | Requires `trelloBoardId`? | Description |
|------|--------------------------|-------------|
| `getMyCards` | No | Get all cards assigned to the current user across all boards. |
| `getCardsByList` | No (needs `listId`) | Get all cards in a specific list. |
| `addCard` | No (needs `listId`) | Add a new card to a list. |
| `updateCard` | No (needs `cardId`) | Update a card's name, description, due date, labels, or position. |
| `moveCard` | No (needs `cardId`) | Move a card to a different list or board. |
| `archiveCard` | No (needs `cardId`) | Archive (close) a card. |
| `changeCardMembers` | No (needs `cardId`) | Add or remove members from a card. |

---

## Recommended Workflows

### First-time setup: Find your board ID

1. Call `getMyBoards` — no configuration needed beyond API key + token.
2. Identify the target board in the results.
3. Copy the `id` field (24-character string). Add it to the MCP config as `trelloBoardId`.

### Daily task review

1. `getMyCards` — see all cards currently assigned to you.
2. `getLists` — get list IDs for the board.
3. `getCardsByList` on relevant lists for a focused view.

### Moving work through a workflow

1. `getLists` — identify source and destination list IDs.
2. `moveCard` with `cardId` + target `listId`.

### Creating and updating cards

1. `getLists` — get the list ID you want to add to.
2. `addCard` with `listId`, name, and optional description/due date.
3. `updateCard` later to revise details, add labels, or adjust position.

---

## Key Behaviors & Notes

- **Rate limiting is handled automatically**: The server respects Trello's limits (300 req/10s per API key, 100 req/10s per token). Do not retry aggressively on errors.
- **IDs vs. short codes**: Always use full IDs (24 characters) for `cardId`, `listId`, and `boardId`. Short URL codes will not work.
- **`getMyCards` is board-agnostic**: Useful when `trelloBoardId` is not set or when the user wants a cross-board view of their work.
- **Archiving ≠ deleting**: Archived cards and lists are hidden but recoverable from Trello's UI.
- **Member management**: `changeCardMembers` accepts an action (`add` or `remove`) and a member ID (Trello user ID, not username).

---

## Error Handling

| Situation | What to do |
|-----------|-----------|
| Tool not found / MCP not connected | Ask the user to install and configure the server using the setup instructions above. |
| Missing `trelloBoardId` | Remind the user to run `getMyBoards` first to get the 24-character board ID, then add it to their config. |
| 401 Unauthorized | API key or token is invalid or expired. Direct user to https://trello.com/app-key to regenerate. |
| Card/list not found | Confirm the ID is the full 24-character ID, not a short code or display name. |
| Rate limit hit | Wait and retry — the server handles throttling automatically in most cases. |

---

## Tips for Claude

- When the user says "my tasks" or "what do I have to do", start with `getMyCards`.
- When the user references a board by name (not ID), call `getMyBoards` first to resolve the ID.
- When the user says "move this to Done" or similar, call `getLists` first to find the correct list ID for the destination.
- Prefer asking for clarification before archiving or removing members — these actions affect others' work.
- If you need both a list ID and a card ID, fetch lists first, then cards within the relevant list.