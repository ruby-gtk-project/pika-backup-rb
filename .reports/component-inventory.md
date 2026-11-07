# Component inventory — pika-backup-rb full-parity port

Surveyed against `origin/main` (upstream Rust/gtk-rs, GPLv3) from the `ruby`
branch. Scope: every user-facing component — windows, pages, dialogs, rows,
menus, shortcuts, actions, empty/error states — plus its `.ui` file, any
GSettings schema, GResource manifest and the `po/` catalogue.

No GSettings schema exists upstream (config lives in
`pika-backup-common/src/config/*.rs`, not `gschema.xml`), so there is none to
port. There is also no `.gresources.xml` manifest to speak of beyond
`data/meson.build`'s resource list — covered under "Resources" below.

Legend for **Exists?**: `yes` = a `lib/pika_backup/*.rb` file already covers
this upstream file; `partial` = a related file exists but does not yet cover
this upstream file's behavior; `no` = nothing yet.

## Application shell

| Upstream file | → `lib/` path | Kind | Exists? |
|---|---|---|---|
| `pika-backup/src/app.rs` | `lib/pika_backup/application.rb` | application (actions, accelerators, primary menu) | partial — `setup`, `backup-preferences` and other not-yet-reached actions are not ported |
| `pika-backup/src/main.rs` | `lib/pika_backup.rb` (entry point) | entry point | yes |
| `pika-backup/src/lib.rs` | — | module wiring only | n/a |
| `pika-backup/src/error.rs` | `lib/pika_backup/error_message.rb` | error/message model | partial — only the pure-UI `Message`/`UserCanceled` variants; borg-specific `Error`/`Combined` variants intentionally not ported yet |
| `pika-backup/src/utils.rs` | `lib/pika_backup/ui_utils.rb` | shared UI helpers (confirmation dialog, toasts, string/path helpers) | partial — borg process plumbing, config-id lookup traits, background-portal request and `show_borg_question` not ported (depend on unported backend) |
| `pika-backup/src/utils/ext.rs` | — | extension methods | no |
| `pika-backup/src/utils/notification.rs` | — | desktop notification helper | no — `error_message.rb` has a stub notification path only |
| `pika-backup/src/utils/df.rs`, `duration.rs`, `config_io.rs`, `flatpak_info.rs`, `password_storage.rs`, `repo_cache.rs`, `borg.rs` | — | non-UI backend utilities | no (backend, not a visual component, but feeds display state) |
| `pika-backup/src/action.rs` | — | app action enum | no |
| `pika-backup/src/dbus.rs`, `backup_status.rs`, `status.rs`, `operation.rs`, `repo.rs`, `shell.rs`, `globals.rs`, `toast_size_estimate.rs`, `prelude.rs` | — | backend/state (not widgets) | no |

## Main window

| Upstream file | → `lib/` path | Kind | Exists? |
|---|---|---|---|
| `pika-backup/src/widget/app_window.rs` + `.ui` | `lib/pika_backup/app_window.rb` | window (`Adw.ApplicationWindow`, nav split view) | yes |
| `pika-backup/src/widget.rs` | — | module wiring only | n/a |
| `pika-backup/src/widget/navigation.rs` | — | module wiring only | n/a |
| `pika-backup/src/widget/navigation/dialog_page.rs` + `.ui` | `lib/pika_backup/dialog_page.rb` | reusable `Adw.NavigationPage` wrapper for dialogs | yes |
| `pika-backup/src/widget/navigation/spinner_page.rs` + `.ui` | `lib/pika_backup/spinner_page.rb` | loading/spinner page | yes |

## Overview page (list of configured backups)

| Upstream file | → `lib/` path | Kind | Exists? |
|---|---|---|---|
| `pika-backup/src/widget/overview.rs` + `.ui` | `lib/pika_backup/overview_page.rb` | page (`Adw.NavigationPage`, listbox, empty state, primary menu) | yes |
| `pika-backup/src/widget/overview/row.rs` + `.ui` | `lib/pika_backup/overview_row.rb` | row (one configured backup, `Adw.ActionRow`-like) | yes |
| `pika-backup/src/widget/status_row.rs` | `lib/pika_backup/status_row.rb` | status display row (shared by overview + detail) | yes |
| `pika-backup/src/widget/status_icon.rs` | `lib/pika_backup/status_icon.rb` | status icon widget (shared) | yes |

## Detail page (one backup config, with its sub-pages)

| Upstream file | → `lib/` path | Kind | Exists? |
|---|---|---|---|
| `pika-backup/src/widget/detail.rs` + `.ui` | `lib/pika_backup/detail_page.rb` | page (tab/view switcher hosting backup/schedule/archives) | **no** |
| `pika-backup/src/widget/detail/backup.rs` + `.ui` | `lib/pika_backup/detail/backup_page.rb` | sub-page: run/stop backup, include/exclude summary | **no** |
| `pika-backup/src/widget/detail/backup/display.rs` | (same file) | backup-page display logic | **no** |
| `pika-backup/src/widget/detail/backup/events.rs` | (same file) | backup-page signal handlers | **no** |
| `pika-backup/src/widget/detail/backup/execution.rs` | (same file) | backup run/cancel execution logic | **no** |
| `pika-backup/src/widget/detail/schedule.rs` + `.ui` | `lib/pika_backup/detail/schedule_page.rb` | sub-page: schedule configuration | **no** |
| `pika-backup/src/widget/detail/schedule/event.rs` | (same file) | schedule-page signal handlers | **no** |
| `pika-backup/src/widget/detail/schedule/status.rs` | (same file) | schedule-page status display | **no** |
| `pika-backup/src/widget/detail/schedule/frequency.rs` | `lib/pika_backup/frequency.rb` | enum-backed dropdown model (daily/weekly/monthly) | yes |
| `pika-backup/src/widget/detail/schedule/weekday.rs` | `lib/pika_backup/weekday.rb` | enum-backed weekday picker model | yes |
| `pika-backup/src/widget/detail/schedule/prune_preset.rs` | `lib/pika_backup/prune_preset.rb` | enum-backed prune-preset model | yes |
| `pika-backup/src/widget/detail/archives.rs` + `.ui` | `lib/pika_backup/detail/archives_page.rb` | sub-page: archive list, mount/unmount, delete | **no** |
| `pika-backup/src/widget/detail/archives/cache.rs` | (same file) | archive list cache/model | **no** |
| `pika-backup/src/widget/detail/archives/display.rs` | (same file) | archive row display logic | **no** |
| `pika-backup/src/widget/detail/archives/events.rs` | (same file) | archive-page signal handlers | **no** |

## Dialogs

| Upstream file | → `lib/` path | Kind | Exists? |
|---|---|---|---|
| `pika-backup/src/widget/dialog.rs` | — | module wiring only | n/a |
| `pika-backup/src/widget/dialog/about.rs` | `lib/pika_backup/about_dialog.rb` | `Adw.AboutDialog` | yes |
| `pika-backup/src/widget/dialog/preferences.rs` + `.ui` | `lib/pika_backup/dialog/preferences_dialog.rb` | `Adw.PreferencesDialog` | **no** |
| `pika-backup/src/widget/dialog/archive_prefix.rs` + `.ui` | `lib/pika_backup/dialog/archive_prefix_dialog.rb` | prompt dialog (archive-name prefix) | **no** |
| `pika-backup/src/widget/dialog/backup_info.rs` + `.ui` | `lib/pika_backup/dialog/backup_info_dialog.rb` | info dialog (backup result summary) | **no** |
| `pika-backup/src/widget/dialog/check.rs` + `.ui` | `lib/pika_backup/dialog/check_dialog.rb` | "check repository" confirmation dialog | **no** |
| `pika-backup/src/widget/dialog/check_result.rs` + `.ui` | `lib/pika_backup/dialog/check_result_dialog.rb` | check-result report dialog | **no** |
| `pika-backup/src/widget/dialog/delete_archive.rs` + `.ui` | `lib/pika_backup/dialog/delete_archive_dialog.rb` | delete-archive confirmation (`Adw.AlertDialog`) | **no** |
| `pika-backup/src/widget/dialog/device_missing.rs` + `.ui` | `lib/pika_backup/dialog/device_missing_dialog.rb` | error-state dialog (backup drive not connected) | **no** |
| `pika-backup/src/widget/dialog/encryption_password.rs` + `.ui` | `lib/pika_backup/dialog/encryption_password_dialog.rb` | password prompt dialog | **no** |
| `pika-backup/src/widget/dialog/exclude.rs` + `.ui` | `lib/pika_backup/dialog/exclude_dialog.rb` | exclude-rules editor dialog | **no** |
| `pika-backup/src/widget/dialog/prune.rs` + `.ui` | `lib/pika_backup/dialog/prune_dialog.rb` | prune settings dialog | **no** |
| `pika-backup/src/widget/dialog/storage.rs` + `.ui` | `lib/pika_backup/dialog/storage_dialog.rb` | storage/repository info dialog | **no** |
| `pika-backup/src/widget/dialog/unmount_archives.rs` + `.ui` | `lib/pika_backup/dialog/unmount_archives_dialog.rb` | unmount-all-archives confirmation dialog | **no** |

### Setup wizard (add/create backup repository — a dialog with many internal pages)

| Upstream file | → `lib/` path | Kind | Exists? |
|---|---|---|---|
| `pika-backup/src/widget/dialog/setup.rs` + `.ui` | `lib/pika_backup/dialog/setup/setup_dialog.rb` | wizard dialog (navigation view, hosts all setup pages) | **no** |
| `pika-backup/src/widget/dialog/setup/types.rs` | `lib/pika_backup/setup_types.rb` | enum-backed setup-flow type model | yes |
| `pika-backup/src/widget/dialog/setup/actions.rs` | `lib/pika_backup/dialog/setup/setup_actions.rb` | shared wizard navigation actions | **no** |
| `pika-backup/src/widget/dialog/setup/location_kind.rs` + `.ui` | `lib/pika_backup/dialog/setup/location_kind_page.rb` | wizard page: local vs. remote choice | **no** |
| `pika-backup/src/widget/dialog/setup/location.rs` + `.ui` | `lib/pika_backup/dialog/setup/location_page.rb` | wizard page: folder chooser | **no** |
| `pika-backup/src/widget/dialog/setup/repo_kind.rs` + `.ui` | `lib/pika_backup/dialog/setup/repo_kind_page.rb` | wizard page: new vs. existing repo choice | **no** |
| `pika-backup/src/widget/dialog/setup/create_new.rs` + `.ui` | `lib/pika_backup/dialog/setup/create_new_page.rb` | wizard page: create new repository | **no** |
| `pika-backup/src/widget/dialog/setup/add_existing.rs` + `.ui` | `lib/pika_backup/dialog/setup/add_existing_page.rb` | wizard page: add existing repository | **no** |
| `pika-backup/src/widget/dialog/setup/encryption.rs` + `.ui` | `lib/pika_backup/dialog/setup/encryption_page.rb` | wizard page: set encryption password | **no** |
| `pika-backup/src/widget/dialog/setup/ask_password.rs` + `.ui` | `lib/pika_backup/dialog/setup/ask_password_page.rb` | wizard page: enter password for existing repo | **no** |
| `pika-backup/src/widget/dialog/setup/advanced_options.rs` + `.ui` | `lib/pika_backup/dialog/setup/advanced_options_page.rb` | wizard page: advanced repo options | **no** |
| `pika-backup/src/widget/dialog/setup/transfer_option.rs` + `.ui` | `lib/pika_backup/dialog/setup/transfer_option_page.rb` | wizard page: transfer settings from existing config | **no** |
| `pika-backup/src/widget/dialog/setup/transfer_prefix.rs` + `.ui` | `lib/pika_backup/dialog/setup/transfer_prefix_page.rb` | wizard page: archive-prefix transfer option | **no** |
| `pika-backup/src/widget/dialog/setup/transfer_settings.rs` + `.ui` | `lib/pika_backup/dialog/setup/transfer_settings_page.rb` | wizard page: settings transfer confirmation | **no** |

## Shared/composite widgets

| Upstream file | → `lib/` path | Kind | Exists? |
|---|---|---|---|
| `pika-backup/src/widget/encryption_settings.rs` + `.ui` | `lib/pika_backup/encryption_settings.rb` | composite widget (encryption method chooser) | **no** |
| `pika-backup/src/widget/folder_row.rs` + `.ui` | `lib/pika_backup/folder_row.rb` | row widget (included/excluded folder display) | yes |
| `pika-backup/src/widget/location_tag.rs` | `lib/pika_backup/location_tag.rb` | tag/badge widget (repo location type) | yes |

## Shortcuts window

| Upstream file | → `lib/` path | Kind | Exists? |
|---|---|---|---|
| `data/resources/shortcuts-dialog.ui` | `lib/pika_backup/shortcuts_dialog.rb` | `Gtk.ShortcutsWindow` (standalone `.ui`, no backing `.rs`) | yes |

## Resources, schemas and translations

| Upstream item | Kind | Exists in `ruby` branch? |
|---|---|---|
| `data/app.metainfo.xml.in` | AppStream metadata (About dialog content, release notes) | no — not checked for a `ruby`-side equivalent; `about_dialog.rb` should source its data from here eventually |
| `data/app.desktop.in` | desktop launcher entry | no |
| `data/resources/style.css` | custom GTK CSS (used by status icons/rows) | no — not ported; `status_icon.rb`/`status_row.rb` CSS classes should be checked against this file |
| `data/resources/icons/**/*.svg` | symbolic icon resources | no |
| GSettings schema | — | none exists upstream; nothing to port |
| GResource manifest (`data/meson.build` resource list) | build-time only, not a runtime component | n/a for a Ruby port |
| `po/*.po` + `po/POTFILES.in` (34 languages) | translation catalogue | no — `ruby` branch has no `po/` directory at all; no `_()`/`gettext` calls were observed in ported `lib/` files either |

## Totals

- Upstream widget-bearing source files (`.rs` + `.ui` under `pika-backup/src/widget/`, plus the standalone `data/resources/shortcuts-dialog.ui`): **73**
- Distinct components/pages/dialogs identified: **~45** (counting each `.rs`+`.ui` pair, and each sub-file like `backup/execution.rs` as part of its owning page's component rather than a separate one)
- Already ported (`yes`): **17** lib files covering application shell basics, main window, overview page + row, status row/icon, schedule's three enum models, folder row, location tag, about dialog, shortcuts dialog, dialog-page/spinner-page nav wrappers, setup-flow type model, error message model, and UI utils (all three of the last partial)
- Not yet ported (`no`): the entire **detail page and its three sub-pages** (backup/schedule/archives execution+display+events), **13 of 14 dialogs** (only About exists), the **entire 13-page setup wizard**, **encryption_settings** composite widget, app-level **AppStream/desktop/CSS/icon resources**, and the **po/ translation catalogue** (not started at all).
