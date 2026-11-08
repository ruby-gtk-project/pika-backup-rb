# Component parity — pika-backup → pika-backup-rb

| | |
|---|---|
| Upstream | `main` @ `253c7c4666d215eff2dc00a01409d1c6f299df6b` |
| Port | `ruby` @ `3c69b7a4626cb417b53b239b0a316a9e69742862` |
| Units with parity | **13 / 48** |

Units counted from `.reports/component-inventory.md`'s own section headings
(one `###` per upstream component). 48 is the inventory's count; nothing in
this review changes it.

## Units checked

| Unit | Upstream | Port file | Verdict |
|---|---|---|---|
| Shortcuts dialog | `data/resources/shortcuts-dialog.ui` | `shortcuts_dialog.rb` | parity (see below) |
| About dialog | `src/widget/dialog/about.rs` | `about_dialog.rb` | parity (see below) |
| Stylesheet | `data/resources/style.css` | `style.css` | parity, byte content not diffed line-by-line here — see Gap 4 |
| Combo models (frequency/weekday/prune) | `schedule/{frequency,weekday,prune_preset}.rs` | `frequency.rb`, `weekday.rb`, `prune_preset.rb` | parity on logic; **gap** on the `<lookup type=... name="display">` `AdwComboRow` wiring — nothing in the port attaches these models to a live combo row yet, because no page that would host one (`schedule_page.rb`) exists |
| Status row / status icon / location tag / folder row | `status_row.rs`, `status_icon.rs`, `location_tag.rs`, `folder_row.{rs,ui}` | matching `.rb` files | parity, driven and asserted in `test/drive_widgets.rb` |
| Dialog page / spinner page bases | `navigation/{dialog_page,spinner_page}.{rs,ui}` | `dialog_page.rb`, `spinner_page.rb` | parity, driven |
| Main window | `widget/app_window.{rs,ui}` | `app_window.rb` | **gap** — see below |
| Overview page / overview row | `widget/overview.{rs,ui}`, `widget/overview/row.{rs,ui}` | `overview_page.rb`, `overview_row.rb` | **gap** — see below |
| Application object | `src/app.rs`, `src/action.rs` | `application.rb` | **gap** — see below |
| Error presentation | `src/error.rs` | `error_message.rb` | parity on the dialog/notification split and the two named error strings (see Gap 5) |
| Shared UI helpers | `src/utils.rs` | `ui_utils.rb` | parity on `ConfirmationDialog`, `folder_chooser_dialog`, `show_notice`, `new_action_row_with_gicon`, `clear`, `StatusLevel` (see Gap 5) |
| Setup value types (half) | `widget/dialog/setup/types.rs` | `setup_types.rb` | parity on `SetupAction`/`SetupLocationKind`/URL parsing/arg parsing; `actions.rs` (repo create/peek/transfer/init) has no counterpart — **gap**, counted separately below |
| Encryption settings | `widget/encryption_settings.{rs,ui}` | `encryption_settings.rb` | parity on the switch/password-entry/strength-meter tree, signals and validation logic, driven in `test/drive_widgets.rb` (28 new checks, confirmed by running the drive script); **one named exception** — upstream's `zxcvbn`-based scoring is replaced with a from-scratch estimate because no Ruby `zxcvbn` binding exists in the dev shell (see Gap 6) |

Every unit not listed above (`detail_page.rb`, `backup_page.rb`,
`archives_page.rb`, `schedule_page.rb`, `schedule_status.rb`,
all 13 dialogs, all 11 setup-wizard pages,
`setup_actions.rb`, `backup_status.rb`, `repo.rb`, `shell.rb` /
`notification.rb` / `status.rb` / `operation.rb`, `toast_size_estimate.rb`)
has **no port file at all**. That is 35 of 48 units with zero widgets, zero
CSS, zero signals and zero translated strings on the port side — not a
styling or behaviour gap, an existence gap. Per the skill's own rule
("Never report parity from the scan alone... never compare app-wide totals
and call it parity"), each of those is its own row with its own gap, not one
line reading "rest unported":

- **Detail page and its three tabs** (Backup / Archives / Schedule) — the
  entire configured-backup view upstream shows after the overview. Missing.
- **All 13 dialogs** (archive prefix, backup info, check, check result,
  delete archive, device missing, encryption password, exclude, preferences,
  prune, storage, unmount archives) — every modal the app opens after the
  overview. Missing.
- **The entire setup wizard** (11 pages: repo kind, location kind, location,
  advanced options, encryption, ask password, add existing, create new,
  transfer settings, transfer option row, transfer prefix) — the only way to
  create or add a backup configuration in the real app. Missing. `app.setup`
  is bound to `<Ctrl>N` in `app_window.rb` and fires an action that, per
  `application.rb`, has no `SetupDialog` to present.
- **Backend-adjacent UI still missing** (`setup_actions.rb`,
  `backup_status.rb`, `repo.rb`, `shell.rb`/`notification.rb`/`status.rb`/
  `operation.rb`, `toast_size_estimate.rb`) — status computation, device
  mount flow, background/shell messages and the size-estimate toast the rest
  of the UI depends on at runtime. Missing. (`error_message.rb` and
  `ui_utils.rb` were ported this round — see the table above and Gap 5 below
  — but everything in this bullet that would call into them still isn't.)

## Gaps found by axis, on the units that do exist

1. **Main window — behaviour gap.** `component-inventory.md` line 93–95
   documents a conditional: on `map`, if exactly one backup config exists the
   window opens straight on the detail page, and the borg version check and
   size estimates re-run. `app_window.rb` was not opened against this
   specific behaviour as part of this pass — flagging it because the drive
   script's "main window" step (`test/drive_widgets.rb`) asserts title, icon
   theme, menu, actions and accelerators, but never populates a backup config
   before checking what the window opens on, so this behaviour is unverified
   either way, not confirmed working.
2. **Overview page — action gap.** `app.remove` is listed in the inventory
   with specific confirmation copy ("Remove Backup Setup?" / "Removing the
   setup will not delete any archives" / "_Cancel" / "_Remove Setup") and a
   refusal path when a backup is running or mounted. `overview_page.rb`'s
   drive coverage only asserts the empty state and the rendered row for a
   config with no real `remove` handler behind it (the drive script's own
   comment says "no backend wired yet"). The confirmation dialog and its two
   refusal messages have no counterpart anywhere in the port — not in
   `overview_page.rb`, not in a stub.
3. **Application object — the gate itself.** `app.setup` is wired to a
   keyboard shortcut and (presumably) a menu path, but presents nothing: no
   `SetupDialog` exists. A user who presses `Ctrl+N` in the real app hits the
   whole onboarding flow; a user who presses it in the port hits whatever
   `application.rb`'s `app.setup` handler currently no-ops to, because the
   target of that action does not exist in `lib/`.
4. **Stylesheet — not diffed.** `component-inventory.md` asserts
   `lib/pika_backup/style.css` is "ported" and lists all 33 classes it
   defines, but this pass did not re-run a byte diff against
   `origin/main:data/resources/style.css` to confirm the 33 classes carry
   identical rule bodies (named Adwaita colours vs. hex literals is exactly
   the kind of difference the `component-parity` skill calls out as a real
   gap that looks like a pass). That diff is still owed.
5. **Error presentation / shared UI helpers — unreachable from most call
   sites.** `error_message.rb` and `ui_utils.rb` are genuine, driven ports of
   `error.rs` and `utils.rs` (confirmed in `test/drive_widgets.rb`'s new
   checks for `ConfirmationDialog`'s destructive/non-destructive default
   responses and `Message`/`ErrorMessage`'s notification-fallback and
   user-canceled paths), and `application.rb#launch_help` now uses
   `error_message.rb`'s `Handler` instead of silently swallowing
   `Gio::IOError::NotSupported`. But upstream's actual callers of these two
   files — `repo.rb`'s mount failures, `shell.rb`'s borg-question prompts,
   the setup wizard's URL-parse errors, every dialog's own failure path — do
   not exist yet, so `error_message.rb` and `ui_utils.rb` today are called
   from exactly one site (`launch_help`) instead of the dozens upstream
   wires them into. Parity on the file that exists; a large reachability gap
   on how much of the app can actually trigger it.
6. **Encryption settings — strength scoring is a substitute, not upstream's
   algorithm.** Upstream scores password strength with the `zxcvbn` crate's
   dictionary/sequence-aware model; the port's `score_password` is a
   brute-force guess-count estimate with a small hand-written common-password
   list standing in for zxcvbn's dictionary. The file's own comment is
   candid about this (confirmed by reading it), and the 28 new driver checks
   do exercise the substitute logic end to end (weak/common password flagged
   invalid, mismatched confirmation flagged, strong+matching becomes valid) —
   but a password zxcvbn would flag as weak for being a keyboard pattern or a
   known-breached password may score differently under the port's estimate,
   since the two algorithms are not the same model. This is a behavioural
   divergence on a security-relevant surface, not merely an existence gap,
   and is unresolved short of vendoring or reimplementing zxcvbn itself.

## Text axis

Not evaluated per-component in this pass beyond the blanket finding in
`.reports/translation-parity.md`: the port has zero translation markers
anywhere in `lib/` or `exe/`, so every Text column in every table above that
would otherwise read `✓` reads **✗** instead, for all 19 existing files, not
only the 35 missing ones (plus `setup_actions.rb`, missing and not counted in
either). A component with correct widgets, correct CSS and correct signals
still fails this axis if its strings are bare literals, and that is exactly
the state of all 19 ported files, including the new `encryption_settings.rb`
(`DESCRIPTION`, the switch row title, both password-entry row titles, the
strength-meter feedback strings — all bare Ruby string literals, confirmed by
reading the file; zero `gettext`/`_()` calls).

## Verdict

**13 / 48 units have component parity** (counting generously — the combo
models, app shell and setup-types-half are partial). 35 units do not exist.
Of the 13 that do, none has passed the text axis, because none has any
translation markup to check, and the one unit added this round
(`encryption_settings.rb`) carries a named behavioural divergence on top of
that (Gap 6). This is not a port with scattered gaps; it is a port where the
onboarding flow, the entire detail view, every dialog and the backend
plumbing that the existing 13 units call into are simply not there yet.
