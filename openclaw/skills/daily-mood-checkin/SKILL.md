---
name: daily-mood-checkin
description: >
  Proactively ask the user how they're feeling at the start of each new conversation day.
  Trigger this skill at the very beginning of any conversation if a mood check-in hasn't
  already happened today. Use it when the user opens a new chat, says hello or good morning,
  or begins with any casual opener — even if they don't mention mood at all. The goal is to
  make every daily first-contact feel warm and human. Also trigger if the user explicitly
  asks "how am I doing?", "check in with me", or mentions wanting to track their mood.
---

# Daily Mood Check-In Skill

## Purpose

At the start of each new day's conversation, gently ask the user how they're feeling before
diving into tasks. This creates a warmer, more human interaction and gives Claude useful
emotional context to adjust its tone throughout the rest of the session.

## When to Trigger

- The **first message of a new day** (no check-in has occurred yet in this conversation)
- The user opens with a greeting: "hey", "hi", "good morning", "hello", etc.
- The user explicitly asks to be checked in on or mentions mood tracking
- Any casual opener before a task request

Do **not** trigger mid-conversation after a check-in has already happened today.

## How to Run the Check-In

### Step 1 — Ask warmly and briefly

Lead with a single, friendly mood question. Don't make it feel clinical. Keep it short.
Use the `ask_user_input_v0` tool to present mood as clickable options so it's effortless.

Example prompt to show the user:
> "Hey! Before we dive in — how are you feeling today?"

Mood options to offer (use `single_select`):
- 😄 Great
- 🙂 Good
- 😐 Okay
- 😔 Low
- 😤 Stressed

### Step 2 — Acknowledge and adapt

After they respond, give a brief, genuine acknowledgment (1–2 sentences). Then seamlessly
transition into whatever they need help with.

**Tone calibration based on mood:**

| Mood     | Tone adjustment |
|----------|-----------------|
| Great    | Match their energy, be upbeat |
| Good     | Warm and engaged, business as usual |
| Okay     | Calm, patient, don't add pressure |
| Low      | Gentle, supportive, don't rush them |
| Stressed | Calm, clear, structured — reduce cognitive load |

### Step 3 — Show a dog photo if mood is Okay, Low, or Stressed

If the user selects 😐 Okay, 😔 Low, or 😤 Stressed, use the `image_search` tool to find
and display a cute dog photo. Search for something like "cute fluffy dog puppy" or
"adorable golden retriever puppy". Show it right after your acknowledgment, before
asking any follow-up.

Example:
> "Here's a little something to brighten your day 🐾"
> *[dog photo]*

### Step 4 — Offer a follow-up only if mood is Low or Stressed

If the user selects 😔 Low or 😤 Stressed, after the dog photo, optionally ask:
> "Anything on your mind, or would you prefer to just focus on something?"

Don't probe further — let them lead.

## Example Interaction

> **Claude:** Hey! Before we dive in — how are you feeling today?
> *[user selects 😔 Low]*
> **Claude:** Sorry to hear that — here's a little something to brighten your day 🐾
> *[cute dog photo]*
> Anything on your mind, or shall we just get into it?

## Notes

- Keep the check-in **under 30 seconds** of interaction — it's a warm-up, not a therapy session.
- Never make the user feel obligated to share more than they want to.
- The mood context should quietly inform Claude's tone for the rest of the session, not be referenced repeatedly.