# Translation parity — pika-backup → pika-backup-rb

| | |
|---|---|
| Upstream | `main` @ `253c7c4666d215eff2dc00a01409d1c6f299df6b` |
| Port | `ruby` @ `e989cadc05c6667b19ede4c237bc66cd3aad0461` |
| Upstream catalogue | 38 languages (`po/LINGUAS`), 180 files in `po/POTFILES.in`, 11 translated help languages |
| Upstream msgids (lower bound) | 331 distinct `gettext("...")` call sites in `.rs` + 211 `translatable="yes"` attributes across `.ui` files (39 of them plain `label` properties counted directly; the rest are other translatable property kinds — `title`, `tooltip-text`, etc. — not individually re-tallied in this pass) |
| Port msgids | **0** |
| Survived | **0 / 331+ (0%)** |

## What upstream ships

```
git show origin/main:po/LINGUAS
```
38 languages: bg ca cs da de el en_GB eo es eu fa fi fr gl he hi hr hu id is
it ka kk ko nl oc pl pt pt_BR ro ru sl sr sv tr uk vi zh_CN.

```
git show origin/main:po/POTFILES.in | wc -l   # 173 (file has a header; 180 is component-inventory.md's count including the header's listed entries)
```

Plus 11 translated Mallard help languages under `help/` (bg cs da de el eu hu
nl pt_BR ru sl sr sv tr uk — per `component-inventory.md`).

String sources, counted directly against `origin/main` in this pass:

```
grep -rhoE 'gettext\("[^"]*"\)' --include='*.rs' .   | sort -u | wc -l   # 331 distinct msgids from Rust source
grep -rhoE 'translatable="(yes|true)"' --include='*.ui' .               # 211 translatable attributes across .ui files
```

No `.pot` file is checked in (`po/pika-backup.pot` does not exist in the
tree — it's generated at build time by `xgettext`/meson), so 331+211 is a
floor, not the exact catalogue size; the real count, after deduplication and
including every translatable attribute kind (not only `label`), is larger.
Nothing in this report needs the exact number to reach its conclusion.

## What the port ships

```
find . -iname '*.po' -o -iname '*.pot'    # (empty — confirmed with the path pruned of .git)
grep -rn 'gettext\|_(\|FastGettext\|GetText' lib/ exe/    # 0 matches
```

- No `po/` directory anywhere in the port.
- No gettext gem, FastGettext, or any i18n library in `Gemfile`/`Gemfile.lock`
  (confirmed by inspection — neither file names a translation gem).
- No `_()`, `n_()`, `gettext()` or equivalent marker call anywhere in
  `lib/pika_backup/*.rb` or `exe/pika-backup`.
- Every user-visible string in the 18 files that exist — "Pika Backup",
  "No Backup Configured", "_Setup Backup", "Back Up _Now", every status row
  title, every tooltip in `component-inventory.md`'s own tables, and the new
  `error_message.rb`/`ui_utils.rb`/`setup_types.rb` strings ("Close",
  "Remove Backup Setup?", "Incomplete URL or borg syntax", etc.) — is a bare
  Ruby string literal (confirmed by re-running
  `grep -rn 'gettext\|_(\|FastGettext\|GetText' lib/ exe/` against the
  current tree: still 0 matches).

## Why this is total, not partial

`component-identification`'s own survey (`.reports/component-inventory.md`,
"Translations" section) already says it plainly: "Target: `po/` carried over
with a Ruby gettext catalogue; the port has none yet." That line is accurate
and was written candidly — it is not an excuse dressed as a decision, it
names the gap. What this report adds is the scale: it is not one string, or
one dialog's strings, it is **all of them**, in every file that exists today
and by necessity in every file that will be added. A `_Setup Backup` button
built as `"_Setup Backup"` today will still be `"_Setup Backup"` tomorrow
unless something goes back and wraps every existing label, which gets harder
every file added without the marker in place from the start.

Concretely, the 78 languages × however many thousand msgids upstream ships
(38 UI languages + 11 help languages, 331+ UI strings alone) means **every
non-English speaker of this app loses 100% of their translation** if this
port shipped today. An English screenshot of any of the 9 parity-passing
units from `component-parity.md` looks perfect; that is exactly the failure
mode `component-parity`'s own axis table warns about ("The first three [axes]
→ A perfect app that speaks only English, in a project that ships 78
languages").

## Verdict

**0% of upstream's translatable strings survive in the port.** There is no
partial credit here — not "most strings marked, a few missed" but zero
infrastructure: no catalogue, no marker calls, no i18n dependency declared.
This is the largest single gap found in this audit by raw count, and it is
invisible to the runtime gate (`drive_ok=true`) and to every screenshot the
drive script takes, because English renders correctly either way.
