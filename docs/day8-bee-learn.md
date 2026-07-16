# Day 8 — AI Integration: BEE & Learn Plugins

## What is Bee

Bee is a Claude Code plugin built by Incubyte that adds spec-driven engineering
discipline on top of AI coding. Plain Claude Code will happily write code
straight from a one-line prompt — no spec, no architecture check, no
guaranteed tests. Bee sits in front of that and asks: how big is this task,
and how risky is it — then it picks the right amount of process for that
specific task.

**The mental model:**

> The developer is the driver. Claude Code is the car. Bee is the GPS.

Bee doesn't take the wheel. It suggests a route (triage → spec → architecture
→ code → test → review) but the developer can always override, skip a step,
or say "just code it."

## Triage: how Bee decides how much process to apply

Bee scores every task on two axes:

| Size | Example | Bee's response |
|---|---|---|
| TRIVIAL | Typo, one-line config change | Fixes it immediately, no ceremony |
| SMALL | Single-file bug, small UI tweak | Quick confirmation, then builds |
| FEATURE | New endpoint, multi-file change | Full: spec → architecture → code → test → verify → review |
| EPIC | New subsystem | Discovery phase first, then phased delivery |

| Risk | Example | Effect |
|---|---|---|
| LOW | Internal tool, easy to revert | Lighter spec, simpler verification |
| MODERATE | User-facing, business logic | Standard spec, thorough tests, review recommended |
| HIGH | Payments, auth, migrations | Deep spec, defensive tests, feature flag + QA |

A typo fix and a payments feature never get the same treatment — that's the
whole point.

## Bee's architecture

- **10 commands** — `/bee:sdd` (main workflow), `/bee:start` (cost/risk-aware
  variant), `/bee:discover` (PM-style requirements interview, produces a PRD,
  writes no code), `/bee:review`, `/bee:qc`, `/bee:architect`, `/bee:onboard`,
  `/bee:migrate`, `/bee:coach`, `/bee:help`.
- **27 specialist agents** — e.g. `context-gatherer` (reads the codebase for
  conventions before anything is built), `spec-builder`, `architecture-advisor`,
  `slice-coder` / `slice-tester` (code and test one vertical slice at a time),
  `sdd-verifier` (quality gate), `reviewer` (final ship recommendation).
- **Artifacts** — specs land in `docs/specs/`, architecture decisions in
  `docs/adrs/`, and session progress in `.claude/bee-state.local.md` so a
  feature survives closing the terminal mid-build.

## What is the Learn plugin

Learn is a separate plugin for learning-by-building: it generates a
project-based curriculum, paces it to your skill level, tracks progress
across sessions, and quizzes you along the way. Its commands live in
`~/.claude/plugins/.../learn/commands/`: `start`, `next`, `explain`, `quiz`,
`review`, `analyze`, `help`. Entry point is `/learn:start`.

## Installing both plugins

```
/plugin marketplace add incubyte/ai-plugins
/plugin install bee@incubyte-plugins
/plugin install learn@incubyte-plugins
```

Both installed cleanly at user scope, so they're available across projects,
not just this repo.

## Exercise: using Bee for a real feature

**Task given to Bee:** add pagination to the `users` GraphQL query.

```
/bee:sdd add pagination to the users GraphQL query
```

**What Bee did, step by step:**

1. **Context gathering** — read `query_type.rb`, the existing user specs, and
   `spec/support/graphql_helpers.rb` to understand existing conventions. It
   noticed the Relay `BaseConnection` / `BaseEdge` boilerplate already existed
   in the codebase, generated but not yet used anywhere.

2. **Architecture question** — Bee paused and asked me to choose a pagination
   style before writing anything:
   - Relay cursor (`first`/`after`, using the existing unused boilerplate) —
     the graphql-ruby idiomatic default, or
   - Simple `limit`/`offset` — easier to reason about, doesn't touch the
     Relay scaffolding.

   I chose **limit/offset** — I wanted to fully understand what got built
   rather than adopt a pattern (Relay cursors) I hadn't learned yet. Bee
   confirmed this integrates fine with Apollo Client later (a `fetchMore` call
   plus a small cache `merge` function), so it doesn't block the Day 9
   frontend work.

3. **Code** — Bee added `limit`/`offset` arguments to the `users` field and a
   resolver that conditionally applies `.limit()` / `.offset()`:

   ```ruby
   argument :limit, Int, required: false
   argument :offset, Int, required: false

   def users(limit: nil, offset: nil)
     query = User.all
     query = query.limit(limit) if limit
     query = query.offset(offset) if offset
     query
   end
   ```

4. **Tests** — Bee wrote three request specs covering limit alone, offset
   alone, and limit+offset combined, asserting exact result sets and ordering
   rather than just counts.

5. **State tracking** — progress was written to `.claude/bee-state.local.md`
   throughout, so the session could have been resumed if I'd closed the
   terminal mid-task.

## AI-assisted workflow, in short

| Step | Who drove it |
|---|---|
| Deciding *what* to build | Me |
| Reading existing code for conventions | Bee (context-gatherer) |
| Architecture decision (Relay vs limit/offset) | Bee proposed, I decided |
| Writing the resolver + tests | Bee |
| Reviewing the diff before commit | Me |

## Reflection: Bee vs. manual coding

The code itself for this task was simple — a few lines of resolver logic I
could have written by hand quickly. Bee's real value showed up before any
code was written: it read the existing codebase first, and paused to ask me
an architecture question (Relay cursors vs. limit/offset) instead of silently
picking one on its own. That's the kind of decision that's easy to miss when
coding solo under time pressure, and having it surfaced explicitly made it a
conscious choice rather than a default.

The tradeoff is speed: Bee's context-gathering and question-asking add a bit
of overhead compared to a direct prompt. For something truly trivial that
overhead isn't worth it — which is exactly why Bee's own triage step exists,
to skip that ceremony for TRIVIAL/SMALL tasks and reserve the full process for
changes where an architecture decision actually matters.
