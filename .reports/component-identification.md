# Component identification — audit note

| | |
|---|---|
| Upstream | `origin/main` @ `253c7c4666d215eff2dc00a01409d1c6f299df6b` |
| Port | `ruby` @ `e989cadc05c6667b19ede4c237bc66cd3aad0461` |

The full per-file inventory lives at `.reports/component-inventory.md` (one
`##`/`###` section per upstream component, widget/CSS/signal tables for every
one). This note re-checks it against the current tree rather than
duplicating it, and records what the prior pass of this note (committed at
`b15d2e73`) still had wrong.

## It was stale against the tree; brought current this pass

The prior copy of this note was checked against `6ea638d7` and already
flagged the inventory as undercounting by 2 (13 vs. the true 15). Since then
two more commits landed and are now folded into `component-inventory.md`
directly, with `*(ported)*` tags added, rather than re-described here:

- `78ae80e8` ("Port error/message handling, shared UI helpers, and setup
  value types") added `error_message.rb`, `ui_utils.rb` and `setup_types.rb`.
  The first two are full ports of their upstream file (`src/error.rs`,
  `src/utils.rs`); `setup_types.rb` is **half** of `setup/{types,actions}.rs`
  — `setup_actions.rb` (repo create/peek/transfer/init, which needs the
  borg/config backend) does not exist, so that heading is tagged
  "half-ported," not "ported."
- `e989cadc` ("Fix launch_help's uncaught exception and extend the drive
  script") touched no new widget file — it fixed a bug in `application.rb`'s
  existing `launch_help` and extended `test/drive_widgets.rb`'s coverage of
  components that already existed.

Current `lib/pika_backup/*.rb` count: **18 files** (confirmed by `find
lib/pika_backup -maxdepth 1 -name '*.rb' | wc -l`), against the inventory's
own count of 48 upstream components — **18/48 (37.5%)**, now written into
`component-inventory.md`'s header directly instead of living only in this
note.

## What it still leaves out

- The scan artifact (`components.tsv` from `component-scan.sh`) backing the
  inventory's totals ("858 widget rows … 142 CSS class attachments … 111
  distinct signals … 20 action references") is still not checked into
  `.reports/`. This pass did not re-run `component-scan.sh`; the totals
  remain asserted from the prior pass, not reproducible by a reader of this
  repo alone. That is unchanged from the prior note and is still owed.
- None of the 13 custom GObject subclasses the inventory's "Shape of the
  port" section calls out (`PkEncryptionSettings` and friends) has been
  re-verified against a built binding check in this pass either; they are
  still open blockers, correctly marked as such.
- This note does not re-derive the runtime gate's component count (20) against
  the 18 `.rb` files above — `test/drive_widgets.rb` also drives
  `SetupRepoLocation`, `SetupCommandLineArgs` and `UiUtils`' free functions as
  separate "components" in its own accounting, which is a driver-script
  count, not an upstream-unit count, and the two should not be read as the
  same number. See `.reports/test-parity.md` for why.

## Verdict

Identification is current as of `e989cadc` and the header ratio (18/48,
37.5%) is now correct and checked into the inventory itself rather than only
asserted in this note. The scan-artifact reproducibility gap from the prior
pass is unresolved and is carried forward rather than closed.
