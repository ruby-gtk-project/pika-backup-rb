# Component inventory — pika-backup → pika-backup-rb

Survey step for the full-parity port. Upstream is `origin/main` in this repo
(Rust + gtk-rs + libadwaita, GtkBuilder `.ui` templates). The port lives on
`ruby` under `lib/pika_backup/`.

Method: the `component-identification` skill. Upstream was exported with
`git archive origin/main` into a scratch tree (never checked out), the
declarative UI was read first (35 `<template>` roots across 35 `.ui` files,
3304 lines), then `component-scan.sh` was run with the GIR symbol table, then
every widget-bearing `.rs` file was read for the widgets, CSS classes, signals
and actions the `.ui` cannot show.

Scan totals, upstream: **858 widget rows** across 107 files, **142 CSS class
attachments**, **111 distinct signals**, **20 action references**.

Port state, re-checked at this pass (through `e989cadc`, "Fix launch_help's
uncaught exception and extend the drive script"): **18 of 48 components
exist** (37.5%) — `lib/pika_backup/` holds 18 `.rb` files (the 13 from the
prior pass, plus `app_window.rb`, `overview_page.rb`, `overview_row.rb` from
`7d2613b5`, and `error_message.rb` + `ui_utils.rb` + `setup_types.rb` from
`78ae80e8`; `setup/{types,actions}.rs` counts as one upstream unit and is only
half-ported) plus `style.css` and the 17 upstream SVG icons. Every section
heading below carries its state: *(ported)* for the ones that exist, nothing
for the 30 that do not. `application.rb` now builds a real `AppWindow`
instead of a placeholder `Adwaita::StatusPage`, but `app.setup` still has no
`SetupDialog` to present (see `.reports/component-parity.md`), so the entire
onboarding flow, both remaining detail/archives/schedule tabs and every modal
dialog are still unported.

## Shape of the port

Upstream splits almost every component in two — `foo.rs` (subclass,
`#[template_child]`, callbacks) beside `foo.ui` (tree, CSS, signals), and
sometimes further into `foo/display.rs` and `foo/events.rs`. The house style
merges each such set into **one** `lib/pika_backup/<thing>.rb`. The tables
below list the whole set per component.

Four upstream mechanisms have no Ruby equivalent and must be rewritten rather
than translated:

- **`GtkBuilder` property bindings** (`bind-source=`/`bind-property=`) are used
  heavily — `PkDialogPage`, `PkSpinnerPage`, `PkCheckDialog`,
  `PkPreferencesDialog`, `PkSetupLocationPage`, `PkEncryptionSettings`. In Ruby
  these become explicit `bind_property` calls or `notify::` handlers.
- **`<lookup type="…" name="display">` expressions** on three `AdwComboRow`s
  (frequency, weekday, prune preset). Ruby has no `Gtk::PropertyExpression`
  over a custom GObject property; these need a `Gtk::StringList` plus an index
  map, or a factory.
- **Custom GObject subclasses with properties and signals** — upstream defines
  13 of them (`PkDialogPage`, `PkSpinnerPage`, `PkFolderRow`, `PkStatusRow`,
  `PkStatusIcon`, `PkEncryptionSettings`, `PkOverviewRow`,
  `PkSetupTransferOption`, the three enum wrapper objects, plus the setup
  pages' `continue` signal). The port expresses these as plain Ruby classes
  with memoized widgets and Ruby callbacks.
- **`app.shortcuts`** is never registered in upstream source — libadwaita picks
  up `shortcuts-dialog.ui` from the GResource path automatically. The port has
  no GResource, so both the dialog and the action must be built by hand.

## Application and window

### `pika-backup/src/app.rs`, `src/action.rs` → `lib/pika_backup/application.rb` — the application object *(ported — shell only: menu, actions, accels, icons, stylesheet; a placeholder `Adwaita::StatusPage` stands in for the overview page)*

Not a widget; holds every app-level action and accelerator.

| Action | Parameter | What it does |
|---|---|---|
| `app.about` | — | presents the About dialog |
| `app.setup` | — | presents `SetupDialog` |
| `app.help` | — | launches `help:pika-backup` |
| `app.quit` | — | `try_quit` → unmount archives, background permission, abort confirmation |
| `app.backup-preferences` | — | presents `PreferencesDialog` for the active config, only while the detail page is visible |
| `app.remove` | — | `OverviewPage#remove_backup` |
| `app.backup.start` | `s` config id | starts a backup |
| `app.backup.show` | `s` config id | views that config and activates the window |
| `app.start-backup` | `s` | D-Bus duplicate of `backup.start` |
| `app.show-overview` | — | D-Bus; pops to overview |
| `app.show-schedule` | `s` | D-Bus; shows the schedule page |
| `app.shortcuts` | — | **implicit upstream** (libadwaita auto-wires it); must be added |

Accelerators: `app.help` → `F1`; `app.quit` → `<Ctrl>Q`, `<Ctrl>W`.
Startup also forces the `Adwaita` icon theme and sets the default window icon.
Non-widget sibling behaviour: `gio::Notification` for "Backup Operation
Running", and a `Quit` shell status message.

### `pika-backup/src/widget/app_window.{rs,ui}` → `lib/pika_backup/app_window.rb` — the main window *(ported — see Gap 1 in `.reports/component-parity.md`)*

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.ApplicationWindow` | 1 | `devel` (only when `APPLICATION_ID_SUFFIX` is set) | `close-request` → `try_quit`, `map` | 782×665 default, 360×294 minimum, title "Pika Backup" |
| `Adw.ToastOverlay` | 1 | — | — | id `toast`; every `show_notice` toast lands here |
| `Adw.NavigationView` | 1 | — | `notify::visible-page` → reload overview | holds the two pages |
| `PkOverviewPage` | 1 | — | — | → `overview_page.rb` |
| `PkDetailPage` | 1 | — | — | → `detail_page.rb` |
| `Gtk.ShortcutController` | 1 | — | — | scope `managed` |
| `Gtk.Shortcut` | 3 | — | — | `<Ctrl>N`→`app.setup`, `<Ctrl>?`→`app.shortcuts`, `<Ctrl>,`→`app.backup-preferences` |

Conditional: on `map`, if exactly one backup config exists the window opens
straight on the detail page; also re-runs the borg version check and redoes
size estimates for backups that were already running.

### `data/resources/shortcuts-dialog.ui` → `lib/pika_backup/shortcuts_dialog.rb` — keyboard shortcuts *(ported)*

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.ShortcutsDialog` | 1 | — | — | no backing source file upstream |
| `Adw.ShortcutsSection` | 1 | — | — | title "General" |
| `Adw.ShortcutsItem` | 5 | — | — | `<Ctrl>N` Set Up New Backup; `app.shortcuts`; `app.quit`; `<alt>Left` Back; `F10` Open Menu |

### `pika-backup/src/widget/dialog/about.rs` → `lib/pika_backup/about_dialog.rb` — About *(ported)*

`Adw.AboutDialog` built entirely in code: app name/icon/version/website/issue
URL, developer name, 2 developers, 2 artists, copyright, translator credits, a
long two-section `comments` blob with markup, 2 `add_link` entries (Open
Collective, GitHub Sponsors) and a generated `debug_info` string (versions,
sandbox state, OS release, Flatpak info, user and global autostart files).

### `data/resources/style.css` → `lib/pika_backup/style.css` — stylesheet *(ported)*

207 lines defining 33 classes the widgets above and below reference:
`accent-icon`, `card`, `container`, `content`, `description`, `dialog-page`,
`dialog-pill`, `dimmed`, `disk-usage`, `error`, `error-icon`, `folder-button`,
`full`, `header`, `high`, `info-card`, `large-row-icon`, `location-row`, `low`,
`ok-icon`, `overview-list`, `overview-location-box`, `overview-row`,
`password-quality`, `popover-label`, `row-icon`, `status-icon`, `tag`,
`tag-box`, `title`, `warning`, `warning-icon`. A port that drops this file
loses the disk-usage bar, the status icon colours and every tag pill.

## Overview

### `src/widget/overview.{rs,ui}` → `lib/pika_backup/overview_page.rb` — the backup list *(ported — see Gap 2 in `.reports/component-parity.md`)*

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.NavigationPage` | 1 | — | — | title "Pika Backup" |
| `Adw.ToolbarView` | 1 | — | — | |
| `Adw.HeaderBar` | 1 | — | — | |
| `Gtk.Button` | 1 | — | `clicked` → present `SetupDialog` | id `add_backup`, `list-add-symbolic`, tooltip "Setup Backup" |
| `Gtk.MenuButton` | 1 | — | — | id `primary_menu_button`, `open-menu-symbolic`, primary, menu `app_menu` |
| `Adw.ViewStack` | 1 | — | — | empty state ↔ list |
| `Adw.StatusPage` | 1 | — | — | **empty state**: `overview-symbolic`, "No Backup Configured" / "Add a new configuration to start creating backups" |
| `Gtk.Button` | 1 | `pill`, `suggested-action` | `clicked` → present `SetupDialog` | id `add_backup_empty`, "_Setup Backup" |
| `Adw.PreferencesPage` + `Adw.PreferencesGroup` | 1 each | — | — | the non-empty branch |
| `Gtk.ListBox` | 1 | `overview-list` | `map` → rebuild list | id `main_backups`, selection none |

Menu model `app_menu` — 3 items: "_Keyboard Shortcuts" `app.shortcuts`,
"_Help" `app.help`, "_About Pika Backup" `app.about`.

Repeater: one `PkOverviewRow` per backup config, rebuilt on `map`; status and
schedule status refreshed asynchronously per row.
Conditional: `remove_backup` refuses with an error dialog when an operation is
running ("Repository in Use") or the repo is mounted for browsing ("Repository
Open for Browsing"), otherwise asks a confirmation ("Remove Backup Setup?" /
"Removing the setup will not delete any archives" / "_Cancel" / "_Remove
Setup") before deleting the config and its stored password.

### `src/widget/overview/row.{rs,ui}` → `lib/pika_backup/overview_row.rb` — one backup in the list *(ported — status-tracking/scheduling backends it would read from are not ported)*

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.ListBoxRow` | 1 | `overview-row` | — | not activatable itself |
| `Gtk.ListBox` | 1 | `boxed-list` | — | inner list, selection none |
| `Adw.ActionRow` | 1 | — | `activated` → view this config | id `location_row` |
| `Gtk.Image` | 1 | — | — | id `location_icon`, 64px, gicon from `repo.icon()` |
| `Gtk.Box` | 2 | `overview-location-box` (inner) | — | prefix layout |
| `Gtk.Label` | 2 | `heading`; `subtitle` | — | config title, repo subtitle |
| `Adw.WrapBox` | 1 | `tag-box`, `caption` | — | id `include_box` |
| `Gtk.Image` | 2 | `dim-label` | — | `go-next-symbolic` chevrons |
| `PikaStatusRow` | 2 | — | `activated` (schedule row) → schedule page | `status`, `schedule_status` |

Repeater: one `LocationTag` per included path into `include_box`.

## Detail

### `src/widget/detail.{rs,ui}` → `lib/pika_backup/detail_page.rb` — the three-tab detail view

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.NavigationPage` | 1 | — | `hidden`, `showing`, `grab_focus` overridden | title "Backup" |
| `Adw.BreakpointBin` + `Adw.Breakpoint` | 1 each | — | — | `max-width: 480sp` drops the header title widget and reveals the switcher bar |
| `Adw.ToolbarView` | 1 | — | — | id `page_detail` |
| `Adw.HeaderBar` | 1 | — | — | id `detail_header_bar` |
| `Adw.ViewSwitcher` | 1 | — | — | policy wide |
| `Gtk.MenuButton` | 2 | — | — | `pending_menu` (hidden; popover explains "Archives are being mounted…", contains `Adw.Spinner`) and the `view-more-symbolic` actions menu with an `F10` `Gtk.Shortcut` |
| `Gtk.Popover` + `Gtk.Label` | 1 each | — | — | pending explanation |
| `Adw.Spinner` | 1 | — | — | id `pending_menu_spinner` |
| `Adw.ViewStack` | 1 | — | `notify::visible-child` → `on_visible_child_notify` | 3 pages |
| `Adw.ViewStackPage` | 3 | — | — | "_Backup"/`drive-harddisk-symbolic`, "_Archives"/`drawer-symbolic`, "_Schedule"/`schedule-symbolic` |
| `Adw.ViewSwitcherBar` | 1 | — | — | revealed by the breakpoint |

Menu model `detail_menu` — 2 items: "Backup Preferences"
`app.backup-preferences`, "Remove Backup Setup" `app.remove`.

### `src/widget/detail/backup.{rs,ui}` + `backup/{display,events,execution}.rs` → `lib/pika_backup/backup_page.rb` — the Backup tab

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.PreferencesPage` | 1 | — | `map` | template root |
| `Adw.PreferencesGroup` | 4 | — | — | repo, buttons, includes, excludes |
| `Adw.ActionRow` | 1 | — | `activated` → `StorageDialog` | id `detail_repo_row` |
| `Gtk.Image` | 1 | `large-row-icon` | — | id `detail_repo_icon`, gicon from repo |
| `Gtk.Button` | 1 | `flat` | `clicked` → eject disk | id `backup_disk_eject_button`, `media-eject-symbolic`, tooltip "Eject Backup Disk" |
| `Gtk.Box` | 1 | `tag-box` | — | id `backup_disk_disconnected` |
| `Gtk.Label` | 1 | `tag` | — | "Disconnected" |
| `PikaStatusRow` | 1 | — | `activated` → `BackupInfoDialog` | id `detail_status_row` |
| `Gtk.Image` | 1 | — | — | id `detail_hint_icon`, hidden while running |
| `Gtk.Button` | 1 | `pill`, `suggested-action` | `clicked` → start backup | id `backup_button`, "Back Up _Now", 210px |
| `Gtk.Button` | 1 | `pill` | `clicked` → abort dialog | id `abort_button`, "_Abort…", hidden unless running |
| `Gtk.SizeGroup` | 1 | — | — | horizontal, over both buttons |
| `Gtk.Button` | 3 | `flat` | `clicked` → file / folder / exclude choosers | `add_include_file_button` `document-new-symbolic`, `add_include_folder_button` `folder-new-symbolic`, `add_exclude_button` `list-add-symbolic` |
| `Gtk.ListBox` | 2 | `boxed-list` | — | `include_list`, `exclude_list`, selection none |
| `Adw.ActionRow` | 2 | `error` (include placeholder only) | — | **empty states**: "No Files Included in Backup", "Nothing Excluded From Backup" |
| `PkBackupInfoDialog` | 1 | — | — | declared in the `.ui` as `detail_dialog` |

Repeaters built in `backup/display.rs`:
- one `Adw.ActionRow` per included path, with a symbolic `Gtk.Image` prefix
  (`row-icon`) and a `flat` `Gtk.Button` `edit-delete-symbolic` suffix
  (tooltip "Remove Directory"). The empty path renders as "Home" / "Usually
  contains all personal data".
- one `Adw.ActionRow` per exclude rule, titled by description and subtitled by
  kind, with a `row-icon` image prefix, a `flat` `document-edit-symbolic`
  edit button **only** for fnmatch/regex patterns (tooltip "Edit Pattern",
  opens `ExcludeDialog#present_edit_exclude`), and a `flat`
  `edit-delete-symbolic` delete button (tooltip "Remove From List").

Dynamic visibility: eject button only when the drive is ejectable and no
operation runs; "Disconnected" tag only when the drive is absent;
backup/abort buttons swap on the spinner status.

### `src/widget/detail/archives.{rs,ui}` + `archives/{display,events,cache}.rs` → `lib/pika_backup/archives_page.rb` — the Archives tab

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.PreferencesPage` | 1 | — | — | template root |
| `Adw.PreferencesGroup` | 3 | — | — | location, integrity check, archive list |
| `Adw.PreferencesRow` | 1 | — | — | non-activatable location header |
| `Gtk.Image` | 1 | — | — | id `location_icon`, 64px |
| `Gtk.Label` | 4 | `heading`; `subtitle`; —; `subtitle` | — | title, subtitle, "{n} Available", "{n} Total" |
| `Gtk.LevelBar` | 1 | `disk-usage` | — | id `fs_usage`, hidden until `df` resolves |
| `Adw.ActionRow` | 1 | — | — | "Archive _Prefix" / "Added in front of all archive names", `document-text-symbolic` |
| `Gtk.Label` | 1 | `dim-label` | — | id `prefix_label`, shows prefix or "None" |
| `Gtk.Button` | 1 | `flat` | `clicked` → `ArchivePrefixDialog` | id `prefix_edit_button`, `document-edit-symbolic` |
| `Adw.ActionRow` | 1 | — | `activated` → `PruneDialog` | id `cleanup_row`, "_Cleanup Archives" / "Delete some older archives", `user-trash-symbolic` |
| `PikaStatusRow` | 1 | — | `activated` → `CheckResultDialog` | id `check_status_row` |
| `Adw.ButtonRow` | 2 | — | `activated` → `CheckDialog` / abort | `check_button_row` "_Check Now" (`go-next-symbolic` end icon), `check_abort_button_row` "_Abort…" |
| `Gtk.Stack` | 2 | — | — | `reloading_stack` (button ↔ spinner, 0ms), `list_stack` (list ↔ placeholder) |
| `Gtk.Button` | 2 | `flat` | `clicked` → refresh / eject | `refresh_archives_button` `view-refresh-symbolic` "Refresh", `eject_button` `media-eject-symbolic` "Stop Browsing Saved Files" |
| `Adw.Spinner` | 1 | — | — | id `reloading_spinner` |
| `Gtk.ListBox` | 2 | `boxed-list` | — | `list`, `list_placeholder`, selection none |
| `Adw.ActionRow` | 1 | — | — | **empty state**: "No Archives Available" |
| `PkCheckResultDialog` | 1 | — | — | declared in the `.ui` |

Repeater built in `archives/display.rs` — one `Adw.ExpanderRow` per archive,
`numeric` class, title the localised start time, subtitle "host, user", and
inside it:

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.Box` + `Gtk.Label` | 1 each | `tag-box`; `tag` | — | "Incomplete Archive", only for `.checkpoint` archives |
| `Adw.ActionRow` + `Gtk.Label` | 2–3 | `dim-label` on the label | — | "Name", "Duration", and "Comment" only when non-empty |
| `Adw.ActionRow` | 1 | — | `activated` → mount and open | "Browse Saved Files", `folder-open-symbolic` prefix, `go-next-symbolic` suffix |
| `Adw.ActionRow` | 1 | — | `activated` → `DeleteArchiveDialog` | "Delete Archive", `edit-delete-symbolic` prefix, `go-next-symbolic` suffix |

### `src/widget/detail/schedule.{rs,ui}` + `schedule/event.rs` → `lib/pika_backup/schedule_page.rb` — the Schedule tab

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.PreferencesPage` | 1 | — | — | template root |
| `Adw.PreferencesGroup` | 3 | — | — | status, scheduled backups, delete old archives |
| `Gtk.ListBox` | 1 | `boxed-list` | — | id `status_list`, holds the status row plus problem rows |
| `PikaStatusRow` | 1 | — | — | id `status_row` |
| `Adw.ExpanderRow` | 2 | — | `notify::enable-expansion`; — | `schedule_active` "Regularly Create Backups" (enable switch, expanded), `prune_detail` "Details" |
| `Adw.ComboRow` | 3 | — | `notify::selected-item` ×3 | `frequency` "Frequency", `preferred_weekday_row` "Preferred Weekday", `prune_preset` "Preserved Archives" / "Amount and time span of retained archives" — all three use `<lookup name="display">` expressions |
| `Adw.ActionRow` | 2 | — | — | `preferred_time_row` "Preferred Time"; "Regularly Cleanup Archives" / "Remove old archives after creating new backups" |
| `Gtk.MenuButton` | 1 | `flat` | — | id `preferred_time_button`, opens the time popover |
| `Gtk.Popover` | 1 | — | `closed` | id `preferred_time_popover` |
| `Gtk.SpinButton` | 2 | — | `output` ×2 | `preferred_hour` (0–23), `preferred_minute` (0–59), vertical, numeric |
| `Gtk.Label` | 1 | — | — | ":" |
| `Adw.SpinRow` | 6 | — | `notify::value` ×6 | `preferred_day` (1–31) and "Keep Hourly/Daily/Weekly/Monthly/Annual" |
| `Gtk.Switch` | 1 | — | `notify::active` | id `prune_enabled` |
| `Gtk.Revealer` | 1 | — | — | id `prune_save_revealer`, slide-up |
| `Gtk.Button` | 1 | `suggested-action` | `clicked` → save prune config | id `prune_save`, "Save Configuration" |
| `Gtk.Adjustment` | 8 | — | — | not widgets; back the spin buttons and rows |

Also listens on `gio::NetworkMonitor` `notify::network-metered` and
`notify::network-available`, and on the navigation view's `visible-page`.

### `src/widget/detail/schedule/status.rs` → `lib/pika_backup/schedule_status.rb` — schedule status rows

Not a template: builds a main `PikaStatusRow` plus a variable list of problem
rows, all `schedule-symbolic`. Titles: "Scheduled Backups Disabled",
"Hourly/Daily/Weekly/Monthly Backups Enabled", "Backup Past Due", "Scheduled
Backups Unavailable", "Waiting for Backup to Start", with subtitles from
"Next backup in …" plus "Will not start until requirements are met."
Problem rows: metered connection, another backup running, browsing,
on battery, device missing, network missing, plus a hint row. Levels map to
`ok-icon`/`warning-icon`/`error-icon`/spinner on the status icon.

### `src/widget/detail/schedule/frequency.rs` → `lib/pika_backup/frequency.rb` — combo model *(ported)*

`PikaBackupScheduleFrequency` GObject with a `display` property; 4 values
(hourly, daily, weekly, monthly).

### `src/widget/detail/schedule/weekday.rs` → `lib/pika_backup/weekday.rb` — combo model *(ported)*

`PikaBackupWeekday` GObject with a `display` property; 7 values.

### `src/widget/detail/schedule/prune_preset.rs` → `lib/pika_backup/prune_preset.rb` — combo model *(ported)*

`PikaBackupPrunePreset` GObject with a `display` property; "Keep Many",
"Keep Some", "Custom", and the keep-counts each preset implies.

## Shared widgets

### `src/widget/status_row.rs` → `lib/pika_backup/status_row.rb` — the status row (`PikaStatusRow`) *(ported)*

`Adw.ActionRow` subclass, `numeric` class, one-line subtitle, a `StatusIcon`
added as prefix, with `icon-name` and `level` bound through to the icon. Used
8× across the app (overview row ×2, backup page, archives page, schedule page,
backup info dialog, check result dialog, schedule problem rows).

### `src/widget/status_icon.rs` → `lib/pika_backup/status_icon.rb` — the status icon (`PkStatusIcon`) *(ported)*

`Gtk.Box` subclass containing a `Gtk.Stack` over a `Gtk.Image` (`status-icon`)
and an `Adw.Spinner` (`row-icon`, 24×24). `level` swaps the image's class
between `ok-icon`, `warning-icon`, `error-icon`, nothing, or shows the spinner.

### `src/widget/location_tag.rs` → `lib/pika_backup/location_tag.rb` — a path/exclude tag *(ported)*

Built in code: `Gtk.Box` with class `tag`, an optional symbolic `Gtk.Image`,
and a middle-ellipsised `Gtk.Label`. Used by the overview row, the transfer
option row (twice).

### `src/widget/folder_row.{rs,ui}` → `lib/pika_backup/folder_row.rb` — folder picker row (`PkFolderRow`) *(ported)*

`Adw.ActionRow` subclass, activatable, accessible role button, a
`folder-open-symbolic` `Gtk.Image` suffix. `activate` opens the folder chooser
("Backup Location"); setting a file adds the `property` class and the basename
as subtitle, clearing it removes the class.

### `src/widget/encryption_settings.{rs,ui}` → `lib/pika_backup/encryption_settings.rb` — encryption block (`PkEncryptionSettings`)

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.Box` | 1 | `encryption-settings` | — | template root, vertical |
| `Adw.PreferencesGroup` | 2 | — | — | switch group, revealed group |
| `Adw.SwitchRow` | 1 | — | `notify::active` → `on_switch_active` | "Use Encryption", off by default |
| `Gtk.Revealer` | 1 | — | — | bound to the `encrypted` property |
| `Adw.PasswordEntryRow` | 2 | — | `changed` ×2 → `password_value_changed` | "Encryption Password", "Repeat Password" |
| `Gtk.LevelBar` | 1 | `password-quality` | — | continuous, max 7 |
| `Gtk.Label` | 1 | `dim-label` | — | id `validation_label`, single line, ellipsised |

Exposes `encrypted`, `valid` and `description` properties the setup and
preferences pages bind against.

### `src/widget/navigation/dialog_page.{rs,ui}` → `lib/pika_backup/dialog_page.rb` — dialog page base (`PkDialogPage`) *(ported)*

`Adw.NavigationPage` subclass with class `dialog-page`, used as the parent of
8 setup pages. `Adw.ToolbarView` → `Adw.HeaderBar` (title hidden, title
buttons bound to `can-close`) → `Gtk.ScrolledWindow` (no h-scroll) →
`Adw.Clamp` → a `container` `Gtk.Box` holding a `title-2 header` `Gtk.Label`,
a hidden `dim-label description` subtitle `Gtk.Label`, and a `content`
`Gtk.Box` that subclasses append into. Carries `labelled-by` /
`described-by` accessibility relations and a `default-widget` property.

### `src/widget/navigation/spinner_page.{rs,ui}` → `lib/pika_backup/spinner_page.rb` — spinner page base (`PkSpinnerPage`) *(ported)*

`Adw.NavigationPage` subclass, class `spinner-page`, `can-pop` false.
`Adw.ToolbarView` → `Adw.HeaderBar` (no title buttons, `Adw.Bin` title
widget) → `Adw.StatusPage` with an `Adw.SpinnerPaintable`, title and
description bound from the page.

## Dialogs

### `src/widget/dialog/archive_prefix.{rs,ui}` → `lib/pika_backup/archive_prefix_dialog.rb`

`Adw.Dialog` 500 wide, "Archive Prefix". `Adw.ToolbarView` +
`Adw.HeaderBar` + `Adw.PreferencesPage` with two groups: a `card info-card`
`Gtk.Box` holding a `heading accent` label "Archive Prefixes" and 3
explanatory labels, then an `Adw.EntryRow` "Archive Prefix". Bottom bar:
`pill suggested-action` `Gtk.Button` "Save" → `on_save`.

### `src/widget/dialog/backup_info.{rs,ui}` → `lib/pika_backup/backup_info_dialog.rb`

`Adw.Dialog` 500×400, "Backup Info". Scrolled `Adw.Clamp` (max 500) over a
`numeric` box containing: a `boxed-list` `Gtk.ListBox` with a `PikaStatusRow`;
a `Gtk.ProgressBar`; a `boxed-list` `Gtk.ListBox` `stats` with 4
non-activatable `Adw.ActionRow`s — "Amount Saved"/"Size of all files",
"Number of Files Saved", "Backup Space Used"/"Newly used space in this
backup", "Current File" — each with a `dim-label` `Gtk.Label` value (the path
label is monospace, 0.9 scale, 2 lines, middle-ellipsised); and a selectable
`dim-label` error `Gtk.Label`.

### `src/widget/dialog/check.{rs,ui}` → `lib/pika_backup/check_dialog.rb`

`Adw.Dialog` 430 wide, "Archives Integrity Check". Two
`Adw.PreferencesGroup`s with descriptions ("This operation will check all
archives for data integrity…" and the repair warning), each holding an
`Adw.ActionRow` with a `Gtk.CheckButton` prefix bound bidirectionally to the
dialog's `verify_data` / `repair` properties — "Verify Data"/"Perform full
data verification" and "Repair"/"Repair errors. This can lead to data loss".
Bottom: `pill suggested-action` "Perform Check" → `run`.

### `src/widget/dialog/check_result.{rs,ui}` → `lib/pika_backup/check_result_dialog.rb`

`Adw.Dialog` 500×400, "Integrity Check Result". Scrolled `Adw.Clamp` over a
`numeric` box with a `boxed-list` `Gtk.ListBox` + `PikaStatusRow`, and a
selectable wrapping `dim-label` `Gtk.Label` for the detail text.

### `src/widget/dialog/delete_archive.{rs,ui}` → `lib/pika_backup/delete_archive_dialog.rb`

`Adw.Dialog` 430 wide, "Delete Archive". A group whose description warns the
deletion is irretrievable, a `boxed-list` `Gtk.ListBox` with two `property`
`Adw.ActionRow`s ("Archive Name", "Archive Date"), and a bottom
`pill destructive-action` "Delete Archive" → `on_delete`.

### `src/widget/dialog/device_missing.{rs,ui}` → `lib/pika_backup/device_missing_dialog.rb`

`Adw.Dialog` whose title is the caller's purpose string. A box with a
`dim-label` "The following backup location needs to be connected:", a bold
`name_label`, and an `icon_box` into which a 128px `Gtk.Image` (the repo's
gicon) is appended at runtime. Watches `gio::VolumeMonitor` `mount-added`
and closes itself when the matching volume appears; closing sends `nil`
to the waiting caller.

### `src/widget/dialog/encryption_password.{rs,ui}` → `lib/pika_backup/encryption_password_dialog.rb`

`Adw.AlertDialog` "Encryption Password Required" with responses `cancel`
"_Cancel" and `apply` "Co_ntinue" (suggested, default), and an extra-child
`Gtk.PasswordEntry` (placeholder "Password", 260 wide, peek icon,
activates-default).

### `src/widget/dialog/exclude.{rs,ui}` → `lib/pika_backup/exclude_dialog.rb`

`Adw.Dialog` 500 wide holding an `Adw.NavigationView` with two pages.

**Root page** "Exclude From Backup": 3 `Adw.ActionRow`s with
`go-next-symbolic` suffixes — "Exclude Folders" (`folder-symbolic`,
`activated` → multi-folder chooser), "Exclude Files"
(`text-x-generic-symbolic`, `activated` → multi-file chooser), "Exclude
Pattern" (`folder-saved-search-symbolic`, "Define regular expression or Unix
filename patterns", `activated` → push the pattern page) — plus two groups
filled at runtime: "Suggested Exclusions" and "Unreadable Paths" / "These
locations were identified as unreadable from a previous backup" (hidden when
empty).

**Pattern page** "Exclude Pattern": an `Adw.ComboRow` "Pattern Type" over a
`Gtk.StringList` ("Unix Filename Pattern", "Regular Expression"), a
`monospace` `Adw.EntryRow` "Pattern", a `card info-card` box with a
`heading warning` "BorgBackup Patterns" label and a markup explanation
linking the Borg docs, and a bottom `pill suggested-action` button whose
label is "Add" or "Save" depending on edit mode → `on_add_pattern_button_clicked`.

Repeaters: one `Adw.ActionRow` per predefined exclusion with a
`selection-mode` `Gtk.CheckButton` prefix (`toggled` → update config) and a
`flat` `dialog-information-symbolic` `Gtk.MenuButton` suffix whose
`Gtk.Popover` holds a selectable "Exclusion Rules" `Gtk.Label`; one
`Adw.ActionRow` per unreadable path with a `Gtk.CheckButton` prefix
(tooltip "Add Exclusion Rule").

### `src/widget/dialog/preferences.{rs,ui}` → `lib/pika_backup/preferences_dialog.rb`

`Adw.PreferencesDialog`, `can-close` false (it validates on close attempt).
One page "General" (`network-server-symbolic`) with 5 groups:

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.EntryRow` | 4 | `monospace` on 3 | `clicked` on the two test buttons | "Title"; "Command Line Arguments"; "Pre-Backup Shell Command"; "Post-Backup Shell Command" — all bound bidirectionally to dialog properties, and each gets the `error` class when validation fails |
| `Adw.ButtonRow` | 1 | — | `activated` → `change_password` | "Change Encryption Password", `go-next-symbolic` |
| `Adw.SwitchRow` | 1 | — | — | "Run on Battery" / "Allow scheduled backups when device is battery powered" |
| `Gtk.MenuButton` | 1 | `circular` | — | `dialog-information-symbolic`, opens the shell-commands popover |
| `Gtk.Popover` + `Gtk.ScrolledWindow` + `Gtk.Label` | 1 each | `popover-label` | — | 300 wide, markup help for shell commands |
| `Gtk.Button` | 2 | `flat` | `clicked` ×2 | `play-large-symbolic`, "Run With Test Values" |

Plus a standalone `Adw.NavigationPage` "Change Encryption Password"
(`hidden` → reset) holding a `Gtk.Stack` over:
- a `PkDialogPage` `dialog-page` containing `PkEncryptionSettings`
  (`notify::encrypted` → swap buttons) and a `Gtk.Stack` of three states:
  an `Adw.Bin` (no button), a `pill suggested-action` "_Change Password", and
  a `pill destructive-action` "_Remove Password";
- an `Adw.ToolbarView` with a title-button-less `Adw.HeaderBar` and a
  `Gtk.Overlay` over an `Adw.StatusPage` "Changing Encryption Password" driven
  by an `Adw.SpinnerPaintable`, with a `pill opaque dialog-pill` "_Cancel".

### `src/widget/dialog/prune.{rs,ui}` → `lib/pika_backup/prune_dialog.rb`

`Adw.Dialog` "Delete Archives", follows content size, a `Gtk.Stack`
(360 min, not v-homogeneous) over two `Adw.ToolbarView`s:
- **spinner**: `Adw.StatusPage` "Checking for Old Archives" with an
  `Adw.SpinnerPaintable`;
- **decision**: a group warning the deletion is irretrievable, with three
  `Adw.ActionRow`s — "Delete Archives", "Keep Archives", "Not Considered" /
  "Archives with different prefix" — each with a `dim-label` count
  `Gtk.Label`, and two bottom buttons sharing `on_apply`:
  `pill suggested-action` "Apply" and `pill destructive-action`
  "Delete Archives".

### `src/widget/dialog/storage.{rs,ui}` → `lib/pika_backup/storage_dialog.rb`

`Adw.Dialog` "Backup Location", follows content size. Three groups, each
hidden until it applies: **Disk** (`property` `Adw.ActionRow`s "Volume",
"Device", "Path"), **Remote** ("URL"), **Space** ("Total", "Free" plus a
`disk-usage` `Gtk.LevelBar`). All subtitles selectable.

### `src/widget/dialog/unmount_archives.{rs,ui}` → `lib/pika_backup/unmount_archives_window.rb`

`Adw.Window` 450×500, no title, modal and transient over the main window.
`Adw.StatusPage` "Closing Archives" / "Closing Archives Still Open for
Browsing" with an `Adw.SpinnerPaintable`, whose child is a hidden
`error_info` `Gtk.Box` holding a `card warning` box with a long explanatory
`Gtk.Label` and a `boxed-list` `Gtk.ListBox`. Repeater: one `Adw.ActionRow`
per failing unmount, with an `info-outline` `Gtk.MenuButton` whose
`Gtk.Popover` holds the wrapping error `Gtk.Label`; rows are added and
removed as unmounts fail and succeed, polling every 300ms.

## Setup wizard

### `src/widget/dialog/setup.{rs,ui}` → `lib/pika_backup/setup_dialog.rb` — the wizard shell

`Adw.Dialog` "Setup" 640×600 holding an `Adw.NavigationView` (360×150 min)
with 9 child pages, signals `notify::visible_page` → `on_visible_page_notify`
and `popped` → `on_popped`, and a binding that forwards the visible page's
`default-widget` to the dialog. Each page's `continue` signal is wired to a
handler on the dialog.

### `src/widget/dialog/setup/repo_kind.{rs,ui}` → `lib/pika_backup/setup_repo_kind_page.rb`

`PkDialogPage` "Set Up Backup Repository" with one separate-rows group and two
`Adw.ButtonRow`s (`go-next-symbolic`): "Create New Repository" →
`on_create_new`, "Use Existing Repository" → `on_use_existing`.

### `src/widget/dialog/setup/location_kind.{rs,ui}` → `lib/pika_backup/setup_location_kind_page.rb`

`PkDialogPage` whose title/subtitle switch on the `repo_action` property
("Create New Repository" vs "Use Existing Repository" plus a long subtitle).
Two `Gtk.Box` groups, only one visible at a time, each with a separate-rows
`Adw.PreferencesGroup` holding two `Adw.ActionRow`s — "Location on Disk"
(`drive-harddisk`, `large-row-icon`) and "Remote Location"
(`network-server`, `large-row-icon`), both with `go-next-symbolic` suffixes
and `activated` → `on_row_activated` — plus a `boxed-list` `Gtk.ListBox`
(`init_repo_list` / `add_repo_list`) filled from `gio::VolumeMonitor`.
Emits a custom `continue` signal with (action, location kind, file).

Repeater: one `Adw.ActionRow` per mount (built by
`utils.new_action_row_with_gicon`, so a `large-row-icon` `Gtk.Image` prefix)
with a `go-next-symbolic` suffix, title "name – size" (plus " / subpath" for
discovered repos) and subtitle "drive – Free space: n". Rows are added on
`mount-added` and removed on `mount-removed`; `grab_focus` goes to the first
local row when shown.

### `src/widget/dialog/setup/location.{rs,ui}` → `lib/pika_backup/setup_location_page.rb`

`PkDialogPage` "Configure Repository", the most complex setup page.

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.PreferencesGroup` | 2 | — | — | `location_group_local`, `location_group_remote` (hidden by default) |
| `Gtk.EventControllerFocus` | 4 | — | `notify::contains-focus` → `validate` | behaviour, not widgets |
| `PkFolderRow` | 1 | — | `notify::file` → `on_folder_changed` | accessibility `required` |
| `Adw.EntryRow` | 3 | — | `notify::text` → `validate` ×2 | "Repository Name", "Repository URL", and a hidden `non_journaling_warning` row |
| `Adw.ActionRow` | 2 | — | `activated` → `push_advanced_options` | "Advanced Options" with bound subtitle, `go-next-symbolic` |
| `Gtk.Label` | 9 | `warning` (bold), `dim-label`, `heading` ×2, `monospace subtitle` ×3 | — | the journaling warning and the two info cards |
| `Adw.PreferencesRow` | 2 | — | — | the two non-activatable info cards |
| `Gtk.Box` | 2 | `info-card` | — | card bodies |
| `Adw.WrapBox` | 2 | — | — | spread, justify-last-line |
| `Gtk.Button` | 2 | `pill` | `clicked` → `on_click_borg_server_info` / `on_click_network_share_info` | "More Information" ×2 |
| `Gtk.Stack` | 1 | — | — | id `button_stack`, not h-homogeneous |
| `Gtk.Button` | 2 | `pill`, `suggested-action` | `clicked` → `on_add_button` / `on_continue_button` | "_Connect", "_Continue", sensitivity bound to `can-continue` |
| `PkSetupAdvancedOptionsPage` | 1 | — | `notify::command-line-args` | declared in the `.ui` |

Card copy that must survive the port: "Locations with BorgBackup Support",
the `ssh://` explanation and example, "SMB and SFTP Network Shares", the
`sftp://`/`smb://` explanation and two examples, and the non-journaling
filesystem warning.

### `src/widget/dialog/setup/advanced_options.{rs,ui}` → `lib/pika_backup/setup_advanced_options_page.rb`

`PkDialogPage` "Advanced Options" with one group "Command Line Arguments" /
"These arguments will be added to the call of the borg binary. Only long
options, starting with “--”, are supported.", a `monospace` `Adw.EntryRow`
(`notify::text` → `on_command_line_args_changed`) and a `dim-label` wrapping
`validation_label`.

### `src/widget/dialog/setup/encryption.{rs,ui}` → `lib/pika_backup/setup_encryption_page.rb`

`PkDialogPage` "Setup Encryption", subtitle bound from the embedded
`PkEncryptionSettings`, default widget the `pill suggested-action` "_Create"
`Gtk.Button` (sensitivity bound to `valid`, `clicked` → `on_create_clicked`).

### `src/widget/dialog/setup/ask_password.{rs,ui}` → `lib/pika_backup/setup_ask_password_page.rb`

`PkDialogPage` "Encryption Password Required" with an
`Adw.PasswordEntryRow` "Password" (`notify::text` → `validate`) and a
`pill suggested-action` "_Continue" button, insensitive until valid.

### `src/widget/dialog/setup/add_existing.{rs,ui}` → `lib/pika_backup/setup_add_existing_page.rb`

`PkSpinnerPage` "Checking Backup Repository" — the `.ui` is the title only;
everything else comes from the spinner page base.

### `src/widget/dialog/setup/create_new.{rs,ui}` → `lib/pika_backup/setup_create_new_page.rb`

`PkSpinnerPage` "Creating Backup Repository".

### `src/widget/dialog/setup/transfer_settings.{rs,ui}` → `lib/pika_backup/setup_transfer_settings_page.rb`

`PkDialogPage` "Transfer Settings" with a long subtitle, a separate-rows
group holding an `Adw.ButtonRow` "Skip" (`go-next-symbolic`, `activated` →
`on_skip_button`), and a repeater: one `PkSetupTransferOption` per
deduplicated archive prefix found on the repository. Emits `continue` with
the chosen archive parameters or nil.

### `src/widget/dialog/setup/transfer_option.{rs,ui}` → `lib/pika_backup/setup_transfer_option_row.rb`

`Adw.ActionRow` subclass, class `overview-row`, activatable.

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.Box` | 5 | — | — | prefix layout |
| `Gtk.Image` | 4 | `status-icon accent-icon`; —; —; `dim-label` | — | `computer-symbolic`, `system-users-symbolic`, `tag-symbolic`, `go-next-symbolic` |
| `Gtk.Label` | 5 | `title-4`; —; —; `caption-heading` ×2 | — | hostname, username, prefix, "Files to Back Up", "Exclude From Backup" |
| `Adw.WrapBox` | 2 | `tag-box`, `caption` | — | `include_box`, `exclude_box` |

Repeaters: one `LocationTag` per include into `include_box` and per exclude
into `exclude_box`.

### `src/widget/dialog/setup/transfer_prefix.{rs,ui}` → `lib/pika_backup/setup_transfer_prefix_page.rb`

`PkDialogPage` "Archive Prefix", `can-close` false, `can-pop` true, with a
long subtitle about prefix uniqueness, an `Adw.EntryRow` "Archive Prefix"
(activates-default) and a `pill suggested-action` "_Save" button →
`on_submit_button`.

### `src/widget/dialog/setup/{types,actions}.rs` → `lib/pika_backup/setup_types.rb`, `lib/pika_backup/setup_actions.rb` *(half-ported — `setup_types.rb` exists; `setup_actions.rb` (repo create/peek/transfer/init, needs the borg backend) does not)*

Non-widget support for the wizard: the `SetupAction` / `SetupLocationKind`
enums, URL parsing with its user-facing errors ("Incomplete URL or borg
syntax", "The remote location must have a specified path.", "Invalid remote
location: “{}”"), command-line argument parsing, archive parameter extraction,
and the repo creation / peek / transfer / init flows.

## Cross-cutting UI

### `src/error.rs` → `lib/pika_backup/error_message.rb` — error presentation *(ported)*

Every failure in the app surfaces here. When the window is mapped and some
toplevel is active it shows an `Adw.AlertDialog` (heading = primary text, body
= secondary text, `prefer-wide-layout`, optional markup body, single response
`close` "Close"), with both texts ellipsised to 510 characters. Otherwise it
sends a `gio::Notification` instead. Also the "Backup with id “{}” already
exists." / "Could not find backup configuration with id “{}”." messages and
the keyring-unavailable explanation.

### `src/utils.rs` → `lib/pika_backup/ui_utils.rb` — shared dialogs, toasts and helpers *(ported)*

- `ConfirmationDialog` — `Adw.AlertDialog` with `cancel`/`accept` responses
  and an optional destructive accent; used for "Remove Backup Setup?",
  "Abort Backup?" and every borg question prompt ("Warning" / "Abort" /
  "Continue", destructive).
- `folder_chooser_dialog` — modal `Gtk.FileDialog` with accept label "Select".
- `show_notice` — `Adw.Toast` with timeout 0 into the window's toast overlay,
  falling back to a notification when the window is unmapped.
- `new_action_row_with_gicon` — activatable `Adw.ActionRow` with a
  `large-row-icon` image prefix.
- `clear(listbox)` — removes every row whose widget name does not start with
  `-`, which is how the setup lists keep their static rows.
- `StatusLevel` — the ok/neutral/warning/error/spinner enum the status icon
  renders.

### `src/backup_status.rs` → `lib/pika_backup/backup_status.rb` — status display model

Produces the title/subtitle/graphic triples that `StatusRow` renders, for
both backup status and check status. Not a widget, but every status row in the
app reads from it.

### `src/repo.rs` → `lib/pika_backup/repo.rb` — device and mount flow

Presents `DeviceMissingDialog` when a removable repo is absent, drives
`gio::Volume#mount` with a `Gtk.MountOperation` parented on the main window,
and surfaces "Failed to Mount".

### `src/shell.rs`, `src/utils/notification.rs`, `src/status.rs`, `src/operation.rs` → `lib/pika_backup/shell.rb`, `notification.rb`, `status.rb`, `operation.rb`

Background/shell status messages, desktop notifications, the quit guard and
operation tracking. No widgets, but they decide when toasts, notifications and
the pending menu appear.

### `src/toast_size_estimate.rs` → `lib/pika_backup/toast_size_estimate.rb`

Shows the "Backup location “{}” might be filling up…" notice toast after a
size estimate, and records unreadable paths for the exclude dialog's
"Unreadable Paths" group.

## Translations

- `po/LINGUAS` — 38 languages: bg ca cs da de el en_GB eo es eu fa fi fr gl he
  hi hr hu id is it ka kk ko nl oc pl pt pt_BR ro ru sl sr sv tr uk vi zh_CN.
- `po/POTFILES.in` — 180 entries; every `.rs` and `.ui` above is listed, plus
  `data/app.desktop.in`, `data/app.Monitor.desktop.in`,
  `data/app.metainfo.xml.in` and `data/resources/shortcuts-dialog.ui`.
- `help/` — 11 translated help languages (bg cs da de el eu hu nl pt_BR ru sl
  sr sv tr uk) over 9 Mallard pages reached by `app.help`.
- Target: `po/` carried over with a Ruby gettext catalogue; the port has none
  yet.

No GSettings schema exists upstream — configuration is JSON under the app
config directory (`pika-backup-common/src/config/*`). There is no `.gresource`
XML either: `pika-backup/src/lib.rs` embeds `data/resources` with
`gvdb_macros::include_gresource_from_dir!`, which is what makes libadwaita
find `shortcuts-dialog.ui` automatically.

## Out of scope for the UI port (noted for completeness)

`pika-backup-common/` (borg process driving, config, schedule requirements,
password handling) and `pika-backup-monitor/` (the autostarted D-Bus monitor
that fires scheduled backups and sends notifications) are separate binaries
with no widgets. The monitor's notifications are user-facing and will need an
equivalent eventually, but no `lib/*.rb` is proposed for them in this pass.

## Blockers to resolve before writing widget code

1. **`Adwaita::Application` is broken in the Ruby bindings** — already worked
   around in `application.rb` (a `Gtk::Application` with an
   `Adwaita::ApplicationWindow`). Upstream subclasses `adw::Application`, so
   anything that relies on `AdwApplication` behaviour — notably the automatic
   `app.shortcuts` action and resource-based shortcuts dialog — must be built
   by hand.
2. **`Adw.ShortcutsDialog` / `Adw.ShortcutsSection` / `Adw.ShortcutsItem`** are
   libadwaita 1.8; confirm they exist in this fork's bindings before porting
   the shortcuts dialog, and fall back to `Gtk::ShortcutsWindow` if not.
3. **`Adw.WrapBox`** (libadwaita 1.7) is used in 4 places (overview row,
   transfer option ×2, location page ×2). Needs a binding check; a `Gtk::Box`
   or `Gtk::FlowBox` substitute changes the tag layout.
4. **`Adw.ButtonRow`** (1.6) is used 6× and **`Adw.SpinnerPaintable`** /
   **`Adw.Spinner`** (1.6/1.7) 5×. Same check.
5. **`Adw.BreakpointBin` + `Adw.Breakpoint` with a `max-width: 480sp`
   condition and two setters** — the detail page's adaptive behaviour. Verify
   `Adwaita::Breakpoint` condition parsing and `add_setter` in Ruby.
6. **GtkBuilder property bindings and `<lookup>` expressions** have no Ruby
   equivalent in the house style; 20+ bindings and 3 combo expressions must be
   rewritten as explicit `bind_property` or handlers.
7. **Custom GObject properties and signals** — 13 subclasses, and the setup
   pages communicate exclusively through a custom `continue` signal with
   boxed/enum parameters. The port needs a plain-Ruby replacement (callbacks
   or procs) since defining new GObject signals from Ruby is unreliable.
8. **No backend** — borg process driving, the secret-service keyring, the
   `ashpd` background portal, `gio::VolumeMonitor`, `df`, and the D-Bus
   monitor all sit behind these widgets. Several components (device missing,
   unmount archives, prune, check, setup add-existing/create-new) cannot be
   driven end to end without at least a stub backend.
9. **`Gtk::VERSION` does not exist** in these bindings; the constant is
   `Gtk::Version`, which matters for the About dialog's debug info.
10. **`.reports/` scan caveat** — the component scan's TSV came back with NUL
    padding and stale rows from an earlier run in the shared scratchpad. The
    totals quoted above were taken from the de-NUL'd file; re-run the scan
    into a fresh path before using it for a parity diff.
