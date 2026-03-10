---
name: gmail-mcp
description: >
  Use this skill whenever the user wants to interact with Gmail via the Gmail MCP server
  (shinzo-labs/gmail-mcp). Trigger this skill for ANY Gmail-related task: reading, searching,
  or listing emails; sending or drafting messages; managing labels, threads, or filters;
  configuring settings like vacation responder, IMAP/POP, delegates, forwarding, or send-as
  aliases; and working with attachments or S/MIME. Also trigger for general inbox management
  tasks like trashing, deleting, or batch-modifying messages. If the user says anything like
  "check my email", "send this to...", "reply to...", "find emails from...", "set up an
  auto-reply", or "manage my Gmail", use this skill immediately.
compatibility:
  tools:
    - tool_search  # Required to load MCP tool schemas before calling any Gmail tool
---

# Gmail MCP Server Skill

This skill covers the full Gmail MCP server provided by [shinzo-labs/gmail-mcp](https://github.com/shinzo-labs/gmail-mcp).
It maps user intent to the correct MCP tools and documents common patterns, gotchas, and
parameter conventions so Claude can reliably accomplish Gmail tasks in a single pass.

---

## ⚠️ Critical: Always Load Tools First

**Before calling ANY Gmail MCP tool, call `tool_search` to retrieve the current parameter
schema.** Do not guess parameter names — they change between versions and guessing causes
silent failures.

```
tool_search(query="gmail messages send list")
tool_search(query="gmail labels threads drafts")
tool_search(query="gmail settings vacation imap delegates")
```

Run one broad search to load the tools you need, then proceed. If a tool call returns
unexpected results, re-run `tool_search` to verify the schema before retrying.

---

## Authentication & Setup (for new users)

The server uses OAuth 2.0. Remind users of the one-time setup if tools return auth errors:

1. **Google Cloud setup (once per org):** Create a project, enable Gmail API, create an OAuth 2.0
   "Desktop app" credential, download `gcp-oauth.keys.json` → save to `~/.gmail-mcp/`.
2. **User auth (once per user):** Run `npx @shinzolabs/gmail-mcp auth` → browser opens for
   Google sign-in → credentials saved to `~/.gmail-mcp/credentials.json`.
3. **Remote/Smithery:** Use `CLIENT_ID`, `CLIENT_SECRET`, and `REFRESH_TOKEN` env vars instead
   of local files.

---

## Tool Reference by Category

### 📬 Messages

| Goal | Tool |
|---|---|
| List inbox / search | `list_messages` |
| Read a message | `get_message` |
| Download attachment | `get_attachment` |
| Send email | `send_message` |
| Add/remove labels on message | `modify_message` |
| Trash a message | `trash_message` |
| Restore from trash | `untrash_message` |
| Permanently delete | `delete_message` |
| Bulk label changes | `batch_modify_messages` |
| Bulk delete | `batch_delete_messages` |

**Search syntax note:** `list_messages` accepts a `q` parameter using standard Gmail search
operators (`from:`, `to:`, `subject:`, `is:unread`, `after:`, `before:`, `label:`, etc.).

### 🧵 Threads

| Goal | Tool |
|---|---|
| List threads | `list_threads` |
| Read a thread (all messages) | `get_thread` |
| Modify thread labels | `modify_thread` |
| Trash / restore / delete thread | `trash_thread` / `untrash_thread` / `delete_thread` |

Use threads when the user wants to see a full conversation rather than individual messages.

### 🏷️ Labels

| Goal | Tool |
|---|---|
| List all labels | `list_labels` |
| Create label | `create_label` |
| Rename / recolor label | `update_label` or `patch_label` |
| Delete label | `delete_label` |

### 📝 Drafts

| Goal | Tool |
|---|---|
| List drafts | `list_drafts` |
| Read a draft | `get_draft` |
| Create draft | `create_draft` |
| Overwrite draft content | `update_draft` |
| Send existing draft | `send_draft` |
| Delete draft | `delete_draft` |

### ⚙️ Settings

| Goal | Tool |
|---|---|
| Vacation / out-of-office responder | `get_vacation` / `update_vacation` |
| IMAP on/off | `get_imap` / `update_imap` |
| POP settings | `get_pop` / `update_pop` |
| Auto-forwarding | `get_auto_forwarding` / `update_auto_forwarding` |
| Language | `get_language` / `update_language` |
| Delegate access | `list_delegates` / `add_delegate` / `remove_delegate` |
| Email filters | `list_filters` / `create_filter` / `delete_filter` |
| Forwarding addresses | `list_forwarding_addresses` / `create_forwarding_address` |
| Send-as aliases | `list_send_as` / `create_send_as` / `verify_send_as` |
| S/MIME | `list_smime_info` / `insert_smime_info` / `set_default_smime_info` |

### 👤 User / Mailbox

| Goal | Tool |
|---|---|
| Get Gmail profile (address, quota) | `get_profile` |
| Set up push notifications | `watch_mailbox` |
| Stop push notifications | `stop_mail_watch` |

---

## Common Workflows

### Read recent unread emails
```
1. tool_search("gmail list messages")
2. list_messages(q="is:unread", maxResults=10)
3. get_message(id=<id>) for each result of interest
```

### Send an email
```
1. tool_search("gmail send message")
2. send_message(to="...", subject="...", body="...")
   # Body is plain text or HTML depending on tool schema
```

### Reply to a thread
```
1. get_thread(id=<threadId>) to retrieve the thread
2. send_message(..., threadId=<threadId>) to reply in-thread
```

### Set vacation responder
```
1. tool_search("gmail vacation settings")
2. update_vacation(enabled=true, startTime=..., endTime=..., responseSubject="...", responseBodyPlainText="...")
```

### Create and apply a label
```
1. create_label(name="My Label")
2. modify_message(id=<messageId>, addLabelIds=[<newLabelId>])
```

### Search and bulk-archive
```
1. list_messages(q="older_than:6m is:read", maxResults=50)
2. batch_modify_messages(ids=[...], removeLabelIds=["INBOX"])
```

---

## Key Parameter Conventions

- **Message IDs** are returned by `list_messages` and are different from thread IDs.
- **Label IDs** (e.g., `INBOX`, `UNREAD`, `SENT`, `TRASH`) are system labels; custom labels
  have alphanumeric IDs returned by `list_labels` or `create_label`.
- **Email body encoding:** The Gmail API uses base64url-encoded message bodies internally.
  The MCP server typically abstracts this — pass plain text or HTML strings and let the tool
  handle encoding. Verify via `tool_search` if unsure.
- **Pagination:** `list_messages` and similar tools return a `nextPageToken`. Pass it as
  `pageToken` in the next call to paginate.
- **`format` parameter on `get_message`:** Options typically include `full`, `metadata`,
  `minimal`, `raw`. Use `full` to read body content; `metadata` for headers only (faster).

---

## Error Handling

| Error | Likely cause | Fix |
|---|---|---|
| `401 Unauthorized` | Expired/missing OAuth token | Re-run `npx @shinzolabs/gmail-mcp auth` |
| `403 Forbidden` | Insufficient OAuth scope | Re-authorize with correct scopes |
| `404 Not Found` | Wrong message/thread/label ID | Re-fetch the ID from a list call |
| Tool returns empty / wrong params | Schema mismatch | Re-run `tool_search` and check param names |

---

## Tips

- When the user says "check email" or "what's in my inbox," start with `list_messages(q="is:unread in:inbox")`.
- For "reply" tasks, always retrieve the thread first to get the `threadId` and the correct `to:` address.
- When creating drafts for review before sending, use `create_draft` and show the draft ID so the user can approve before `send_draft` is called.
- Prefer `trash_message` over `delete_message` unless the user explicitly wants permanent deletion.
- For bulk operations (archive, mark-read, delete), use the `batch_*` tools to stay within API rate limits.