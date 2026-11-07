# Component identification — audit note

| | |
|---|---|
| Upstream | `origin/main` @ `253c7c4666d215eff2dc00a01409d1c6f299df6b` |
| Port | `ruby` @ `6ea638d7110f944a994138c4ca966f05c8d81d2c` |

The full per-file inventory already lives at `.reports/component-inventory.md`
(751 lines, one `##`/`###` section per upstream component, widget/CSS/signal
tables for every one). This note does not duplicate it — it re-checks it
against the current tree and records what has drifted and what it leaves out.

## It is stale against the current tree

`component-inventory.md` was last regenerated at commit `4e641366`
("Inventory upstream components"). Two commits have landed since and are not
reflected in its "ported" tags:

- `6f5d815f` is what the file was checked against (13 components).
- `7d2613b5` ("Port the main window and overview page") added
  `app_window.rb`, `overview_page.rb` and `overview_row.rb` — their headings
  (lines 81, 126, 152) still carry no `*(ported)*` tag and `application.rb`'s
  heading still says a placeholder `Adwaita::StatusPage` stands in for the
  overview page, which is no longer true: `application.rb` now builds a real
  `AppWindow`.
- `6ea638d7` ("Harden the drive script and fix the spec entry point") touched
  no widget file.

Current `lib/pika_backup/*.rb` count: 15 files (confirmed by `find lib -name
'*.rb'`), against the inventory's own count of 48 upstream components. The
inventory's headline number ("13 of 48") undercounts the current state by 2
and should read **15 of 48 (31%)** — the direction of the drift is
conservative here, but a drifted document is still a document a reader can't
trust at the line level, and the next agent to touch it inherits the wrong
baseline unless it is corrected before being treated as ground truth.

## What it leaves out

- It records totals ("858 widget rows … 142 CSS class attachments … 111
  distinct signals … 20 action references") but the scan artifact itself
  (`components.tsv` from `component-scan.sh`) is not checked into `.reports/`,
  so the totals cannot be re-derived or spot-checked without re-running the
  scan. Blocker #10 in the document's own "Blockers" section already flags
  that an earlier scan run came back NUL-padded with stale rows; the
  de-NUL'd file that the quoted totals were taken from is likewise not saved
  anywhere, so the totals in this document are asserted, not reproducible.
- `detail_page.rb`, `backup_page.rb`, `archives_page.rb`, `schedule_page.rb`
  and every dialog/setup-wizard page are documented as upstream components
  (good — the inventory does not drop them from the table) but none of the
  13 custom GObject subclasses the document's own "Shape of the port"
  section calls out (`PkEncryptionSettings`, `PkEncryptionSettings`'s
  `<lookup>` combo expressions, etc.) have been re-verified against a built
  binding check; the document still phrases them as open blockers (#2–#7),
  which is correct for the current state but means no component built after
  this pass has had its binding risk re-assessed in writing.

## Verdict

Identification is substantively done and candid about what is missing — this
is the one of the five reports with the least new material to add, because
the pre-existing document already does the hard survey work honestly. The
action item is mechanical: re-run `component-scan.sh` against the current
`ruby` HEAD and `origin/main`, update the three headings above, correct the
headline ratio to 15/48, and check the de-NUL'd scan TSV into `.reports/` so
the totals stop being an unverifiable assertion.
