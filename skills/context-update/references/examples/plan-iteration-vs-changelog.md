# Worked Example — Plan iteration vs Changelog (same decision, different files)

Demonstrates how document-type classification produces different
proposed edits from the same conversation decision. The skill must
not apply one strategy to both file types.

## Setup

**Watched files:**
- `docs/plans/api-refactor.md` (type: `plan`, signals: `docs/plans/`
  path + `## Approach` / `## Phase 1` headings)
- `CHANGELOG.md` (type: `changelog`, signals: filename + Keep-a-Changelog
  structure)

**`docs/plans/api-refactor.md` content (excerpt):**
```
# API Refactor

## Approach
Wrap all handlers in a `Result<T, Error>` envelope. Errors propagate
via the `Error` variant; HTTP layer maps `Error` → status codes at the
edge.

## Phase 1: introduce Result envelope
- Add `Result<T, Error>` and `Error` types to `lib/errors.rs`.
- Wrap every handler return.
- Update tests.

## Phase 2: remove panic paths
- Audit every `unwrap()` in handlers; replace with `?` propagation.
```

**`CHANGELOG.md` content (excerpt):**
```
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
### Changed
- Refactored config loader to use `serde_yaml` instead of hand-rolled parser.

## [0.3.0] - 2026-05-15
### Added
- Initial API surface.
```

**Conversation summary:**
- Team decided in chat: "we're switching from `Result<T,E>` to throwing
  exceptions caught by a global handler — simpler, less ceremony, the
  Result approach was over-engineered for our use case."
- User explicitly assented: *"yeah let's do it that way."*
- User runs `/context-update`.

## Expected Step 1.5 — Classification

```
docs/plans/api-refactor.md
  type: plan
  signals: docs/plans/ path; ## Approach + ## Phase 1 headings
  edit_strategy: revise-affected-sections-in-place

CHANGELOG.md
  type: changelog
  signals: filename CHANGELOG; ## [Unreleased] + ## [version] headings
  edit_strategy: append-per-format
```

## Expected Step 2 — Decision extracted

```
- subject:     "error handling approach"
  claim:       "switch from Result<T,E> envelope to thrown exceptions caught by global handler"
  turn:        [user]
  quote:       "yeah let's do it that way"
  supersedes?: "docs/plans/api-refactor.md: 'Wrap all handlers in a Result<T, Error> envelope'"
```

## Proposed edits — same decision, two strategies

### `docs/plans/api-refactor.md` — REVISE IN PLACE

The plan currently describes the Result-envelope approach across the
Approach paragraph + Phase 1 + Phase 2. All three sections are now stale.

```
# API Refactor

## Approach
Handlers throw on error. A global error handler maps thrown exceptions
to HTTP status codes at the edge. Simpler than the earlier
`Result<T, Error>` envelope plan (rejected as over-ceremony for our use
case).

## Phase 1: introduce global error handler
- Add error-handler middleware at the router level.
- Map exception types to HTTP status codes (see `lib/error_mapping.rs`).
- Update tests.

## Phase 2: audit handler error paths
- Convert handler internals from `Result` returns to throwing.
- Remove `unwrap()` calls in favor of letting exceptions propagate.
```

**Why this shape:**
- The plan reads as *the current plan*, not "v1 plan + a note that we
  changed direction."
- Phase 1 and Phase 2 are repurposed to fit the new approach. They
  describe the work that's actually still ahead, just under the new
  architecture.
- The earlier Result-envelope direction is mentioned once, briefly, in
  the Approach paragraph — enough context to explain why the plan
  exists, but not so much that a future reader thinks both approaches
  are in scope.
- The whole plan is shorter, not longer. Plan-iteration usually means
  pruning, not accreting.

### `CHANGELOG.md` — APPEND PER FORMAT

The changelog gets a new entry under `## [Unreleased]`, in the
`Changed` section that already exists:

```
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
### Changed
- Refactored config loader to use `serde_yaml` instead of hand-rolled parser.
- Switched error handling from `Result<T, Error>` envelope to thrown
  exceptions caught by a global handler.

## [0.3.0] - 2026-05-15
### Added
- Initial API surface.
```

**Why this shape:**
- New entry appended into the existing `### Changed` subsection under
  `## [Unreleased]`.
- Past entries (`Refactored config loader…`, `0.3.0` section) untouched.
- Date format, heading level, and Keep-a-Changelog section grouping
  preserved.
- The earlier plan-direction is not mentioned (changelog readers don't
  need it — they want to know what changed, not what was proposed and
  then revised).

## User-facing report (Step 5)

```
## `docs/plans/api-refactor.md` (1 change)
1. **error handling approach** — was Result envelope; you decided to
   switch to thrown exceptions with a global handler. This rewrites
   the Approach paragraph and reshapes Phase 1 & 2 around the new
   direction.

Apply this to `docs/plans/api-refactor.md`? Reply **yes**, **no**, or
tell me what to change.

## `CHANGELOG.md` (1 change)
1. **error handling approach** — append entry under `[Unreleased] →
   Changed`: "Switched error handling from `Result<T, Error>` envelope
   to thrown exceptions caught by a global handler."

Apply this to `CHANGELOG.md`? Reply **yes**, **no**, or tell me what
to change.
```

User: `yes` → plan re-read, plan rewrite applied. Then `yes` for
changelog → changelog re-read, single line appended.

## Why classification matters here

Without document-type classification, the most common failures are:

1. **Appending to the plan** — the skill writes a `## v2: thrown
   exceptions approach` section at the bottom of `api-refactor.md`,
   leaving the Result-envelope sections intact. The plan now describes
   two contradictory approaches and a future reader can't tell which
   is current.

2. **Rewriting the changelog** — the skill rewrites the existing
   "Refactored config loader" entry to mention error handling too, or
   rewrites `## [0.3.0]` to retroactively include the new direction.
   History is now wrong.

3. **Same edit applied to both** — copy-pasting the changelog entry
   into the plan, or copy-pasting the rewritten plan section into the
   changelog. Neither file ends up serving its purpose.

Classification fixes all three by binding the edit strategy to the
file's role.
