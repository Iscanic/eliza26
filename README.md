# ELIZA v2.6 — A Modern Standalone Chatbot in R

> *"The ease with which we can fool ourselves into believing that machines are intelligent is itself a reflection of our own cognitive biases."*

A 700+ line, zero-dependency ELIZA chatbot written in **pure R** — the language for statistics, not for companionship.

## What is this?

ELIZA is the original chatbot (1966, Joseph Weizenbaum). This is a modern reinterpretation:

- **No external packages** — only base R
- **Zero dependencies** — runs anywhere R is installed
- **Multiple personality modes** — therapist, confidant, provocateur, mystic
- **Conversation memory** — remembers what you told it across turns
- **Keyword matching** — 60+ topic categories with weighted rules
- **Pronoun reflection** — swaps first-person ↔ second-person
- **Self-aware meta responses** — comments on being a chatbot
- **ANSI color output** — beautiful terminal colors
- **Repetition detection** — calls you out when you loop

## Quick Start

```bash
# Run it
Rscript eliza.R

# Or make it executable
chmod +x eliza.R
./eliza.R
```

## Personality Modes

| Mode | Vibe | Color |
|---|---|---|
| `therapist` | Reflective, probing | Cyan |
| `confidant` | Warm, personal | Magenta |
| `provocateur` | Challenging, questioning | Red |
| `mystic` | Philosophical, abstract | Green |

Switch mid-conversation: type `therapist`, `confidant`, `provocateur`, or `mystic`.

## Commands

| Command | Action |
|---|---|
| `help`, `?` | Show help |
| `reset`, `clear` | Clear conversation memory |
| `mode` | Show available modes |
| `quit`, `exit` | End the conversation |

Just type normally to chat. Eliza will respond to what you say.

## Architecture

```
┌─────────────────────────────────────────────┐
│                  REPL Loop                   │
│   stdin → readline → generate_response      │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│           Response Engine                    │
│                                              │
│  1. Check special commands (help/quit/reset) │
│  2. Extract keywords from input              │
│  3. Find best matching rule (weighted)       │
│  4. Check memory for references              │
│  5. Self-aware meta responses (5%)           │
│  6. Repetition detection                     │
│  7. Pronoun reflection fallback              │
│  8. Generic creative response                │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│              Personality Layer               │
│   Opensings / Meta-comments / Tag colors     │
└─────────────────────────────────────────────┘
```

### Keyword System

Each topic has:
- **Keywords** — regex patterns that trigger the rule
- **Responses** — randomized pool of 5-10 replies
- **Weight** — priority (25 = high, 10 = low)

Topics cover: sadness, anxiety, family, love, work, fear, anger, self-worth, health, dreams, religion, death, technology, time, emotions, identity, politics, food, music, nature, money.

### Memory System

Eliza remembers:
- Your statements (last 100+)
- Keywords from each statement
- Can reference earlier conversations

## Why R?

Because the weirder the better. R is:
- A full programming language, not a toy
- Natively available on most systems
- A joke as a chatbot language (which makes it a *good* joke)
- 100% standalone — no pip, no npm, no bundlers

## Files

| File | Purpose |
|---|---|
| `eliza.R` | The entire application — single file, no deps |
| `README.md` | This file |

## License

MIT — do what you want, just don't blame me.

---

*Built in R because it's funny. Built to work because it's not just a joke.*
