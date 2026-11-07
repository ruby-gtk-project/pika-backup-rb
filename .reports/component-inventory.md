# Component inventory — pika-backup-rb

Surveyed against `origin/main` (Rust/gtk-rs, GNOME World Pika Backup) on 2026-11-07.
Upstream has no `.blp` files; every UI unit is a `.rs` class paired with a
GtkBuilder `.ui` file of the same stem (plus one hand-written
`data/resources/shortcuts-dialog.ui` with no paired `.rs` — it is loaded
directly as a `GtkShortcutsWindow`). There are no GSettings schemas
(`*.gschema.xml`) anywhere upstream, and no GResource manifest beyond the
Meson-driven `data/resources/` bundle (icons, CSS, the shortcuts window) —
nothing in that bundle needs a `lib/*.rb` counterpart beyond what's listed
below. `po/` holds 40 language catalogues plus `POTFILES.in`; translation
parity is out of scope for this inventory (see the `translation-parity` skill).

Legend: **kind** — window / dialog / page / row / menu / shortcuts / settings
/ action-set / empty-state. **exists** — already present in `lib/` on `ruby`.

## App shell

| Upstream | → lib/*.rb | Kind | Exists? |
|---|---|---|---|
| `pika-backup/src/app.rs` | `lib/pika_backup/application.rb` | application (actions, lifecycle, quit guard) | Partial — `application.rb` exists but upstream's `App` subclass (quit-in-progress guard, action setup, status tracking, dbus/borg-mount cleanup on startup) is not ported |
| `pika-backup/src/main.rs` | — (exe entrypoint) | entrypoint | N/A, see `exe/` |
| `pika-backup/src/action.rs` | — | action-set (`win.start-backup(s)`, `win.show-overview`, `win.show-schedule(s)`) | Missing — no GAction definitions in `lib/` |
| `pika-backup/src/widget/app_window.rs` + `app_window.ui` | `lib/pika_backup/app_window.rb` | window | **Exists** (documented as partial: no detail-page routing, no App-backed quit guard, no pre-release header decoration) |
| `pika-backup/src/widget/status_icon.rs` | `lib/pika_backup/status_icon.rb` | widget (status icon) | **Exists** |
| `pika-backup/src/widget/status_row.rs` | `lib/pika_backup/status_row.rb` | row | **Exists** |
| `pika-backup/src/widget/location_tag.rs` | `lib/pika_backup/location_tag.rb` | widget (tag) | **Exists** |
| `pika-backup/src/widget/folder_row.rs` + `folder_row.ui` | `lib/pika_backup/folder_row.rb` | row | **Exists** |
| `pika-backup/src/widget/navigation/dialog_page.rs` + `.ui` | `lib/pika_backup/dialog_page.rb` | page (base class) | **Exists** |
| `pika-backup/src/widget/navigation/spinner_page.rs` + `.ui` | `lib/pika_backup/spinner_page.rb` | page (base class) | **Exists** |
| `data/resources/shortcuts-dialog.ui` | `lib/pika_backup/shortcuts_dialog.rb` | shortcuts window | **Exists** |
| `pika-backup/src/widget/dialog/about.rs` | `lib/pika_backup/about_dialog.rb` | dialog | **Exists** |

## Overview page

| Upstream | → lib/*.rb | Kind | Exists? |
|---|---|---|---|
| `pika-backup/src/widget/overview.rs` + `overview.ui` | `lib/pika_backup/overview_page.rb` | page (+ empty-state status page) | **Exists** (documented partial: no live `BACKUP_CONFIG` store, `add_backup` doesn't open `SetupDialog` since that's unported) |
| `pika-backup/src/widget/overview/row.rs` + `row.ui` | `lib/pika_backup/overview_row.rb` | row | **Exists** |

## Detail page (backup / archives / schedule) — entirely missing

| Upstream | → lib/*.rb | Kind | Exists? |
|---|---|---|---|
| `pika-backup/src/widget/detail.rs` + `detail.ui` | `lib/pika_backup/detail_page.rb` | page (container: ViewStack of backup/archives/schedule + pending menu) | Missing |
| `pika-backup/src/widget/detail/backup.rs` + `backup/display.rs` + `backup/events.rs` + `backup/execution.rs` + `backup.ui` | `lib/pika_backup/backup_page.rb` | page | Missing |
| `pika-backup/src/widget/detail/archives.rs` + `archives/cache.rs` + `archives/display.rs` + `archives/events.rs` + `archives.ui` | `lib/pika_backup/archives_page.rb` | page | Missing |
| `pika-backup/src/widget/detail/schedule.rs` + `schedule/event.rs` + `schedule/status.rs` + `schedule.ui` | `lib/pika_backup/schedule_page.rb` | page | Missing |
| `pika-backup/src/widget/detail/schedule/frequency.rs` | `lib/pika_backup/frequency.rb` | model (combo-row backing object) | **Exists** |
| `pika-backup/src/widget/detail/schedule/weekday.rs` | `lib/pika_backup/weekday.rb` | model | **Exists** |
| `pika-backup/src/widget/detail/schedule/prune_preset.rs` | `lib/pika_backup/prune_preset.rb` | model | **Exists** |

## Dialogs — entirely missing except About

| Upstream | → lib/*.rb | Kind | Exists? |
|---|---|---|---|
| `pika-backup/src/widget/dialog.rs` | — (module init only) | n/a | n/a |
| `pika-backup/src/widget/dialog/archive_prefix.rs` + `.ui` | `lib/pika_backup/dialog/archive_prefix_dialog.rb` | dialog | Missing |
| `pika-backup/src/widget/dialog/backup_info.rs` + `.ui` | `lib/pika_backup/dialog/backup_info_dialog.rb` | dialog | Missing |
| `pika-backup/src/widget/dialog/check.rs` + `.ui` | `lib/pika_backup/dialog/check_dialog.rb` | dialog | Missing |
| `pika-backup/src/widget/dialog/check_result.rs` + `.ui` | `lib/pika_backup/dialog/check_result_dialog.rb` | dialog | Missing |
| `pika-backup/src/widget/dialog/delete_archive.rs` + `.ui` | `lib/pika_backup/dialog/delete_archive_dialog.rb` | dialog | Missing |
| `pika-backup/src/widget/dialog/device_missing.rs` + `.ui` | `lib/pika_backup/dialog/device_missing_dialog.rb` | dialog (error state) | Missing |
| `pika-backup/src/widget/dialog/encryption_password.rs` + `.ui` | `lib/pika_backup/dialog/encryption_password_dialog.rb` | dialog | Missing |
| `pika-backup/src/widget/dialog/exclude.rs` + `.ui` | `lib/pika_backup/dialog/exclude_dialog.rb` | dialog | Missing |
| `pika-backup/src/widget/dialog/preferences.rs` + `.ui` | `lib/pika_backup/dialog/preferences_dialog.rb` | dialog (preferences) | Missing |
| `pika-backup/src/widget/dialog/prune.rs` + `.ui` | `lib/pika_backup/dialog/prune_dialog.rb` | dialog | Missing |
| `pika-backup/src/widget/dialog/storage.rs` + `.ui` | `lib/pika_backup/dialog/storage_dialog.rb` | dialog | Missing |
| `pika-backup/src/widget/dialog/unmount_archives.rs` + `.ui` | `lib/pika_backup/dialog/unmount_archives_dialog.rb` | dialog | Missing |
| `pika-backup/src/widget/encryption_settings.rs` + `.ui` | `lib/pika_backup/encryption_settings.rb` | widget (settings sub-form, used inside setup) | Missing |

## Setup wizard (`SetupDialog`) — entirely missing (13 files)

| Upstream | → lib/*.rb | Kind | Exists? |
|---|---|---|---|
| `pika-backup/src/widget/dialog/setup.rs` + `.ui` | `lib/pika_backup/dialog/setup_dialog.rb` | dialog (multi-page wizard, navigation host) | Missing |
| `pika-backup/src/widget/dialog/setup/types.rs` | `lib/pika_backup/dialog/setup/types.rb` | model (`SetupAction`, `SetupRepoLocation`, etc.) | Missing |
| `pika-backup/src/widget/dialog/setup/actions.rs` | — (behavior, not a widget) | n/a | n/a |
| `pika-backup/src/widget/dialog/setup/location_kind.rs` + `.ui` | `lib/pika_backup/dialog/setup/location_kind_page.rb` | page | Missing |
| `pika-backup/src/widget/dialog/setup/location.rs` + `.ui` | `lib/pika_backup/dialog/setup/location_page.rb` | page | Missing |
| `pika-backup/src/widget/dialog/setup/repo_kind.rs` + `.ui` | `lib/pika_backup/dialog/setup/repo_kind_page.rb` | page | Missing |
| `pika-backup/src/widget/dialog/setup/add_existing.rs` + `.ui` | `lib/pika_backup/dialog/setup/add_existing_page.rb` | page | Missing |
| `pika-backup/src/widget/dialog/setup/create_new.rs` + `.ui` | `lib/pika_backup/dialog/setup/create_new_page.rb` | page | Missing |
| `pika-backup/src/widget/dialog/setup/ask_password.rs` + `.ui` | `lib/pika_backup/dialog/setup/ask_password_page.rb` | page | Missing |
| `pika-backup/src/widget/dialog/setup/encryption.rs` + `.ui` | `lib/pika_backup/dialog/setup/encryption_page.rb` | page | Missing |
| `pika-backup/src/widget/dialog/setup/advanced_options.rs` + `.ui` | `lib/pika_backup/dialog/setup/advanced_options_page.rb` | page | Missing |
| `pika-backup/src/widget/dialog/setup/transfer_option.rs` + `.ui` | `lib/pika_backup/dialog/setup/transfer_option_page.rb` | page | Missing |
| `pika-backup/src/widget/dialog/setup/transfer_prefix.rs` + `.ui` | `lib/pika_backup/dialog/setup/transfer_prefix_page.rb` | page | Missing |
| `pika-backup/src/widget/dialog/setup/transfer_settings.rs` + `.ui` | `lib/pika_backup/dialog/setup/transfer_settings_page.rb` | page | Missing |

## Non-UI support files seen but out of scope for this inventory

`pika-backup/src/{backup_status,dbus,error,globals,operation,repo,shell,status,toast_size_estimate}.rs`,
`pika-backup/src/utils/*.rs`, all of `pika-backup-common/`, and all of
`pika-backup-monitor/` are backend/D-Bus/scheduling logic, not widgets —
listed here only so a later pass doesn't mistake their absence from `lib/`
for a missed *component*. `toast_size_estimate.rs` does drive a user-visible
`Adw.Toast`; it has no counterpart widget file of its own (it's spawned by
`BackupPage`/`detail/backup/*`), so it is folded into the `backup_page.rb`
unit above, not listed separately.

## Summary

- **14** `lib/*.rb` files exist today, all under the app shell / overview page
  / schedule-model units. Each carries an explicit comment on what upstream
  behavior it has *not* yet ported (config store, actions, quit guard,
  detail-page routing) — these are real gaps, not finished work.
- **Missing entirely:** the detail page and its three sub-pages (backup,
  archives, schedule — 4 units, 8 upstream files), all 12 dialogs (12 units,
  ~20 upstream files including `encryption_settings.rs`), and the 13-file
  setup wizard (1 host dialog + 12 pages/models).
- **Action set:** `win.start-backup(s)`, `win.show-overview`,
  `win.show-schedule(s)` from `pika-backup/src/action.rs` have no Ruby
  counterpart yet.
- No GSettings schema and no GResource manifest exist upstream to port.
