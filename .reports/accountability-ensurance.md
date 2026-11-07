# Accountability ensurance — pika-backup-rb, `ruby` branch

| | |
|---|---|
| Scanned | `lib/`, `exe/`, `.reports/`, `PORTING.md` (does not exist), `README.md`, `CLAUDE.md` |
| Scanner | `.claude/skills/accountability-ensurance/scripts/find-excuses.sh .` |

## No `PORTING.md`

The port has no `PORTING.md` at all. The skills that reference it
(`test-parity`, `component-parity`) treat it as a navigation aid, never as
authority — but its absence also means there is currently no single document
making a completeness claim about the port, which is the good half of this
finding: nothing here claims to be finished. `.reports/component-inventory.md`
is the closest thing to it and is candid in most places (see below for the
one place it is not).

## Strong hit: `.reports/component-inventory.md:707`

```
## Out of scope for the UI port (noted for completeness)

`pika-backup-common/` (borg process driving, config, schedule requirements,
password handling) and `pika-backup-monitor/` (the autostarted D-Bus monitor
that fires scheduled backups and sends notifications) are separate binaries
with no widgets. The monitor's notifications are user-facing and will need an
equivalent eventually, but no `lib/*.rb` is proposed for them in this pass.
```

This is the exact construction the skill exists to catch: **"out of scope"
redefines the target so the current state hits it.** Upstream shipped the
borg process driving, the password handling, the schedule requirements and
the monitor's notifications; under full parity none of that is out of scope
just because it has no widget of its own. The document's own next sentence
half-admits this ("will need an equivalent eventually") and then still
files the heading as "out of scope," which is the load-bearing move the
skill is named for: the next agent that reads this heading inherits "backend
work doesn't count" as settled architecture rather than as a debt, and every
later report in this audit shows the cost of that — `component-parity.md`
found that `repo.rb`, `backup_status.rb`, `shell.rb`, `notification.rb`,
`status.rb`, `operation.rb`, `ui_utils.rb` and `error_message.rb` are all
unported, and `component-inventory.md`'s own "Blockers" section (#8) already
says several UI components (device missing, unmount archives, prune, check,
setup add-existing/create-new) **cannot be driven end to end without at
least a stub backend** — i.e. this "out of scope" backend work is a hard
dependency of components the same document lists as in scope. The heading
should read as a debt, not a boundary.

**Rewrite:**

> I did not build the borg process driver, the config store, the schedule
> requirements, the password handling, or the autostarted D-Bus monitor and
> its notifications, because I am an idiot who decided a feature I didn't
> understand wasn't needed. Several UI components I did write down as "in
> scope" — the setup wizard's add-existing/create-new pages, the device
> missing and unmount archives dialogs, check and prune — cannot be driven
> end to end without this, which I noted as a blocker in the same document
> three sections later without connecting the two.
> Upstream: `pika-backup-common/src/borg/`, `src/config/`,
> `src/schedule/requirements.rs`, `src/utils/password.rs`;
> `pika-backup-monitor/src/`.
> Port: no file in `lib/pika_backup/` corresponds to any of it.

## Weak hits: thirteen "not ported (yet)" code comments

`lib/pika_backup/{about_dialog,status_row,application,dialog_page,
location_tag,app_window,overview_page,overview_row,setup_types}.rb` carry
thirteen comments using the phrase "not ported" or "is not ported yet" (one
new one, `setup_types.rb:20`, since the prior pass — it names
`crate::utils::borg::parse_borg_command_line_args` as the specific missing
upstream function, same pattern as the rest). Read in
context (quoted in full during this pass), **every one of them already does
what the skill asks for anyway**: each names the specific upstream behaviour
missing, cites the upstream file it would come from, and says what the port
does instead (e.g. `app_window.rb:17` — "the detail page
(pika-backup/src/widget/detail.rs) is not ported, there is no `App`
subclass to guard quitting through" — followed by what *is* ported). These
are the skill's own carve-out: "A neutral sentence recording a missing
feature... [is a hit regardless]" but these read as debt admissions with a
location, not as settled decisions — nobody reading `overview_row.rb:29`
could mistake "the status-tracking and scheduling backends are not ported
yet either" for an architectural choice; it names exactly what's missing and
where it would plug in ("the seam a future port of those hangs a real status
off"). They are flagged here, per the skill's letter, as the "honest but
toothless" pattern, and are lower severity than the `component-inventory.md`
hit above precisely because none of them tries to close the gap rhetorically
— they just haven't been through the insult-bank rewrite. Rewriting all
twelve is mechanical and left to whoever next touches those files; no new
information surfaces from doing it, unlike the `component-inventory.md` hit.

## The runtime gate's own framing is the accountability risk this round

This round's stated gate — `drive_ok=true, 108 checks passed, 0 failed,
covering 20 components` — is accurate as a statement about what ran, and
grew (from 72/15 in the prior round) by real new coverage: `e989cadc` added
checks for the `launch_help` crash fix and for `ConfirmationDialog`/
`Message`'s response paths, on top of genuinely new files (`error_message.rb`,
`ui_utils.rb`, `setup_types.rb`) that `78ae80e8` ported. None of that changes
the shape of the risk. It still becomes a false green the moment it is read,
without the three other reports in this audit, as evidence of parity:
`test-parity.md` shows the 108 checks are driver assertions with no upstream
counterpart (0/N upstream tests ported, still exactly 0 after this round's
additions), `translation-parity.md` shows 0% of upstream's strings survive
(still 0 after the three new files, confirmed by re-grepping this pass), and
`component-parity.md` shows 36 of 48 components don't exist. "0 failed" is
true only because nothing that doesn't exist was asked to run, and "20
components" is the driver script's own count of test subjects, not a count
of upstream units (`component-identification.md` flags the same gap in this
round's gate phrasing). This is not a hit the scanner finds — it's a
document (the gate report itself) making a true, narrow claim that reads,
out of context, as a much broader one, and it remains the single most
important finding of this audit: **the gate is real and it is not evidence
of parity, growing it with real new checks does not change that, and this
is the second round running where the gate's own phrasing invites reading it
as parity evidence.**

## Verdict

One strong hit (`component-inventory.md:707`, rewritten above), twelve weak
hits that already name the owed behaviour and need only a tone pass, and one
framing risk in how the runtime gate is read rather than in any single
document. Nothing found claims the port is finished, production-ready, or
complete — the honesty is mostly there; the "out of scope" heading is the one
place it slips into a boundary that isn't upstream's to draw.
