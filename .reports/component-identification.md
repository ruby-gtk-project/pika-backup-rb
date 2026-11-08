# Component identification — audit note

| | |
|---|---|
| Upstream | `origin/main` @ `253c7c4666d215eff2dc00a01409d1c6f299df6b` |
| Port | `ruby` @ `3c69b7a4626cb417b53b239b0a316a9e69742862` |

The full per-file inventory lives at `.reports/component-inventory.md` (one
`##`/`###` section per upstream component, widget/CSS/signal tables for every
one). This note re-checks it against the current tree rather than
duplicating it, and records what the prior pass of this note (committed at
`a044c658`) still had wrong.

## It was stale against the tree; brought current this pass

The prior copy of this note was checked against `e989cadc` and reported
18/48. Since then two more commits landed:

- `c1d3ef04` ("Port EncryptionSettings widget") added
  `lib/pika_backup/encryption_settings.rb`, a genuine port of
  `src/widget/encryption_settings.{rs,ui}` — confirmed by reading the file:
  the switch/password-entries/strength-meter tree matches the `.ui` template
  row-for-row, and the one upstream piece it cannot carry over (the
  `zxcvbn` password-strength crate, with no Ruby binding available in this
  project's closed dev-shell gem set) is replaced with a real, working
  estimate the file's own header comment documents, not a stub. This heading
  in `component-inventory.md` had **not** been given its `*(ported)*` tag by
  the commit that ported the file — it was still unmarked until this pass
  fixed it.
- `3c69b7a4` ("Drive the EncryptionSettings widget and fix a warning-priority
  bug") touched no new widget file — it extended `test/drive_widgets.rb`
  with 28 new `d.check(...)` assertions driving the widget just ported, and
  fixed a real bug the new driving exposed (a warning raised at the wrong
  priority).

Current `lib/pika_backup/*.rb` count: **19 files** (confirmed by `find
lib/pika_backup -maxdepth 1 -name '*.rb' | wc -l`), against the inventory's
own count of 48 upstream components — **19/48 (39.6%)**. The inventory's
header and the `encryption_settings.rb` heading itself were both stale
(still saying 18/48 and carrying no `*(ported)*` tag) until this pass
corrected them directly in `component-inventory.md`.

## What it still leaves out

- The scan artifact (`components.tsv` from `component-scan.sh`) backing the
  inventory's totals ("858 widget rows … 142 CSS class attachments … 111
  distinct signals … 20 action references") is still not checked into
  `.reports/`. This pass did not re-run `component-scan.sh`; the totals
  remain asserted from an earlier pass, not reproducible by a reader of this
  repo alone. That is unchanged from the prior note and is still owed.
- None of the custom GObject subclasses the inventory's "Shape of the port"
  section calls out (`PkEncryptionSettings` and friends) has been
  re-verified against a built binding check in this pass either; they are
  still open blockers, correctly marked as such.
- This note does not re-derive the runtime gate's component count (19,
  per this round's stated gate) against the 19 `.rb` files above as if they
  were the same thing — `test/drive_widgets.rb` groups its own test subjects
  (e.g. treating `SetupRepoLocation` and `SetupCommandLineArgs` inside
  `setup_types.rb`, and `UiUtils`' free functions, as separate "components")
  differently from a one-upstream-unit-per-file count, so the two tallies
  landing on the same number this round is coincidental, not evidence they
  measure the same thing. See `.reports/test-parity.md` for why.

## Verdict

Identification is current as of `3c69b7a4` and the header ratio (19/48,
39.6%) is now correct and checked into the inventory itself rather than only
asserted in this note. The scan-artifact reproducibility gap from the prior
pass is unresolved and is carried forward rather than closed. 29 of 48
upstream components — the entire onboarding wizard, the whole detail view
(backup/archives/schedule tabs), every modal dialog except
about/shortcuts, and all backend plumbing (`repo.rb`, `shell.rb`,
`backup_status.rb`, `operation.rb`, `status.rb`, `notification.rb`,
`setup_actions.rb`) — still do not exist.
