# Test parity — pika-backup → pika-backup-rb

| | |
|---|---|
| Upstream | `main` @ `253c7c4666d215eff2dc00a01409d1c6f299df6b` |
| Port | `ruby` @ `e989cadc05c6667b19ede4c237bc66cd3aad0461` |
| Upstream tests | 4 integration-test files + inline `#[test]` units in 5 source files |
| Ported | **0** |
| Gaps | all of them |
| Test command | none — `spec/` has no test files; `test/drive_widgets.rb` exists but is not a test suite in the parity sense (see below) |

## Upstream census

```
git ls-tree -r --name-only origin/main | grep -iE 'test|spec'
```

```
pika-backup/tests/backup_data/...        (fixture data, not tests)
pika-backup/tests/borg_integration.rs    92 lines
pika-backup/tests/exclude_patterns.rs    61 lines
pika-backup/tests/exclude_predefined.rs  83 lines
pika-backup/tests/size_estimate.rs       68 lines
pika-backup/tests/test_common.rs         (shared harness)
```

Plus inline `#[test]` modules found by `git grep -l '#\[test\]' origin/main --
'*.rs'`, in:

```
pika-backup-common/src/borg/invert_command.rs
pika-backup-common/src/schedule/requirements.rs
pika-backup-common/src/utils/password.rs
pika-backup/src/utils/df.rs
pika-backup/tests/size_estimate.rs   (also an integration file, listed once)
```

Individual `#[test] fn` case counts were not tallied one-by-one in this pass
(the full `TEST_PARITY.md` ledger this skill calls for still needs to be
written, case by case, against each of the five files above plus the four
integration files). What is certain without that count: the number of
upstream cases is **well above zero**, and the port's count is **exactly
zero**, so the ledger's bottom line does not depend on the exact upstream
total to be damning.

## Port census

```
find spec -type f
```

```
spec/README.md        — harness documentation, not a test
spec/spec_helper.rb    — RSpec bootstrap, not a test
```

**There is not one `*_spec.rb` file in this repository.** `bundle exec rspec`
would run zero examples. `spec/spec_helper.rb`'s own comment says as much:
"the display-free half — the port's models not ported yet are not under test
here" — that sentence describes a suite that has never had a model to test
checked in yet, which is accurate but does not change the number: 0.

## The runtime gate's "108 checks" is not this suite

The round's gate reports `drive_ok=true, 108 checks passed, 0 failed,
covering 20 components`. Those 108 checks come from `test/drive_widgets.rb`,
a headless GTK driver script (the `ruby-gtk-testing` skill's harness), not
from RSpec and not from any upstream test. Reading the file (confirmed by
`grep -c 'd\.check(' test/drive_widgets.rb` → 108):

- It drives the 18 existing `.rb` files (`frequency.rb`, `weekday.rb`,
  `prune_preset.rb`, `status_row.rb`, `folder_row.rb`, `location_tag.rb`,
  `app_window.rb`, `shortcuts_dialog.rb`, `about_dialog.rb`,
  `overview_page.rb`, `overview_row.rb`, `dialog_page.rb`, `spinner_page.rb`,
  `error_message.rb`, `ui_utils.rb`, `setup_types.rb`, plus `application.rb`
  and `status_icon.rb`) and screenshots the widget-bearing ones. The gate's
  "20 components" is the driver's own count of named test subjects
  (`SetupRepoLocation` and `SetupCommandLineArgs` inside `setup_types.rb`,
  and `UiUtils`' free functions, are each counted as separate "components" by
  the driver though they are not separate upstream units or separate `.rb`
  files) — a driver-script tally, not an upstream-unit tally, and reading it
  as 20/48 upstream components would be wrong in the generous direction.
- Every one of its 108 `d.check(...)` assertions was **written for the
  port**, from scratch, by whoever wrote the driver. None of them is named
  after, or asserts the same property as, an upstream `#[test]` or
  integration test. `borg_integration.rs`, `exclude_patterns.rs`,
  `exclude_predefined.rs` and `size_estimate.rs` test borg process behaviour,
  exclude-pattern matching and disk-size estimation — none of which exists in
  the port yet (no `repo.rb` behaviour, no borg driving code, no exclude
  matcher), so none of it could be driven even if someone tried.
- The driver's own comments acknowledge the scope: `"a backend not wired
  yet"` appears next to checks that assert "does not crash" rather than
  asserting the real behaviour (remove backup, activate the schedule-status
  row). The newest additions (`e989cadc`) add real coverage of
  `launch_help`'s crash fix and of `ConfirmationDialog`/`Message`'s response
  paths — genuine driver tests, still with no upstream `#[test]` counterpart,
  since upstream has no unit test for either (they are `.rs` files with no
  `#[test]` module of their own, confirmed by the `#[test]` grep below).

This is exactly the shape the `test-parity` skill's worked example
(planify-rb, 173 checks against 34 upstream tests, 0/34 parity) describes:
**a larger, green, passing number that has no relationship to the upstream
suite.** 108/108 driver checks passing is real and worth having, but it is
not test parity, it is 108 checks in the `## Extra` bucket this skill's
ledger format reserves for exactly this situation — and treating "108 checks
passed, covering 20 components" as evidence of test parity, as the runtime
gate's phrasing invites, is the false-green this audit was asked to catch.

## Verdict

**0/N upstream tests ported**, where N is at minimum the 4 integration files
plus 5 files' worth of inline unit tests — all currently unportable anyway,
because none of the backend behaviour they test (`pika-backup-common`'s borg
process driving, schedule requirements, password handling, df usage, size
estimation) has a Ruby counterpart in `lib/` yet. The port's "suite that has
never been executed" is not a close call here: there is no suite file to
execute. `TEST_PARITY.md` does not exist at the port root and needs to be
created with the full case-by-case ledger this report only scopes.
