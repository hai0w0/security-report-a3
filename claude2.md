# claude2.md — Session knowledge handoff

Purpose: this file captures working knowledge from this session that is
**not** already durably recorded in `CLAUDE.md`, `prompt.md`, or the report
itself, so a fresh or compacted session can resume without re-deriving it.
This file is not authoritative instructions — `CLAUDE.md` and the student's
current message always win in a conflict. Read `CLAUDE.md` and `prompt.md`
too; this file only fills the gaps.

## Where things stand

**All three assignment sections are now fully written, evidence-verified,
and the document builds clean: 0 errors, 0 overfull boxes, 0 unresolved
references, 31 pages.** The report is content-complete; what remains before
submission is the QA/polish pass in "Suggested next steps" below, not new
report content.

- **Section 1 (Q1.1–Q1.5, SQL injection, 50 marks)** — `sections/section1.tex`,
  every sub-answer verified against genuine screenshots in `figures/`.
- **Section 2 (Q2.1–Q2.4, XSS, `Labsetup-xss.zip`, 40 marks)** —
  `sections/section2.tex` — stored XSS alert, cookie theft with an added
  "impact of obtaining the cookie" analysis, the completed HTTP-forgery worm
  skeleton with derived `sendurl`/`samyGuid` values, and the full worm
  executed against Alice with before/network/after evidence.
- **Section 3 (AI security, Q3.1–Q3.2, 10 marks)** — `sections/section3.tex`
  — MNIST Jacobian-based Saliency (stronger) attack turning a 3 into an 8 via
  `https://kennysong.github.io/adversarial.js/` (no VM/Docker involved), and
  a Q3.2 analysis grounded in the student's own Week 6 lecture slides 17–22
  (`slides/` folder in the repo root — slide 19's "Gradient-based methods
  (GradArgmax)" panel is the specific one the brief points to; the analysis
  draws the analogy between that graph-classification gradient/saliency
  method and JSMA's per-pixel Jacobian approach used in Q3.1).
- The scaffold `sections/appendix.tex` file still exists on disk but is no
  longer `\input` by `security_report.tex` (removed on the student's
  confirmation, since the brief never required an appendix) — don't
  re-add it without asking again.
- Both the SQL injection lab (`Labsetup-sql-3`) and the XSS lab
  (`Labsetup-xss`) are set up and have been run successfully on the
  student's `seed@VM` (a SEED Ubuntu VM, reached via its own terminal —
  browser and Docker engine are on the same machine, so no host-routing
  workarounds are needed there). **The two labs cannot run at the same
  time** — see `lab-setup-guide.md` for the full explanation and the
  switching procedure; that file is the primary day-to-day reference for
  both labs, with `section1-lab-setup.md` and `section2-lab-setup.md` holding
  the fuller diagnostic history behind it. Section 3 needed neither lab.

## Key documents already in this repo — read these, don't recreate them

- `CLAUDE.md` — authoritative writing/workflow rules for the report answers.
  Always follow it; it already encodes the Q1.1 quality model, evidence
  discipline, structure-per-answer, and build/QA checklist.
- `prompt.md` — the original task brief and constraints for this whole
  assignment-help engagement (scope, what not to fabricate, etc.).
- `section1-lab-guide.md` — step-by-step exploit instructions for Q1.1–Q1.5:
  exact payloads, expected behaviour, troubleshooting, screenshot checklist
  and filenames.
- `section1-lab-setup.md` / `section2-lab-setup.md` — the detailed, narrative
  setup/diagnostic history for each lab (every real error hit and its fix).
  `lab-setup-guide.md` is the condensed, day-to-day quick reference covering
  both labs together, including the network/container-name conflict between
  them and the browser-caching gotcha when switching — read that one first.
- `sections/section1.tex`, `sections/section2.tex` — the finished report
  content for Sections 1 and 2. There is no standalone `section2-lab-guide.md`
  — the Q2.1–Q2.4 exploit walkthroughs happened directly in chat rather than
  being written to a separate guide file first.

## Verified facts and payloads (checked against genuine screenshots — safe to reuse, but always re-verify against actual evidence if asked to touch these again)

- `credential` table column order: `ID, Name, EID, Salary, birth, SSN,
  PhoneNumber, Address, Email, NickName, Password`. Boby `ID=2`, Ted `ID=5`,
  Alice `ID=1`.
- **Q1.1**: Username `Ted'#`, Password blank → logs in as Ted. Browser
  leaves `'` unencoded in the address bar and only percent-encodes `#` as
  `%23` (confirmed from the actual screenshot's URL — do not assume both get
  encoded).
- **Q1.2**: Edit Profile, `NickName = ', Salary=1605 WHERE ID=2 --` (the
  working payload uses `--` with a trailing space, confirmed via screenshot
  — an earlier attempt without the trailing space silently failed, because
  `unsafe_edit_backend.php` never checks whether its query succeeded) →
  Boby's Salary becomes `1605` (`SALARY_1` for student `s4041605`).
- **Q1.3**: Edit Profile, `NickName=Tran Dinh Hai`,
  `Email=s4041605@rmit.edu.vn` (the student's **real** RMIT email — replaces
  an earlier guessed `@student.rmit.edu.au` placeholder from before evidence
  existed), `Address=RMIT`, `PhoneNumber=' WHERE ID=2#` → updates Boby's
  nickname/email/address via the *last*-field injection technique (so the
  earlier, legitimate-looking field values also land on Boby's row).
- **Q1.4**: source-identification only, no live payload/screenshot needed
  (the brief has no "Demonstrate" clause for it). Two vulnerable statements:
  `unsafe_view_order.php`'s unchecked write of `$_POST["favourite"]`/
  `$_POST["order"]` into `preference.favourite`; `unsafe_tasks_view.php`'s
  unquoted read-back of that value into `order by tasks.` plus its
  `explode(";")`/`foreach` loop, which executes every fragment as an
  independent query (the app implements stacked-query execution itself).
- **Q1.5**: Set View Preference, dropdown `favourite=Hours`, `order` field:
  ```
  ; select tasks.Name as taskname, credential.Name as ownername, tasks.Hours, tasks.Amount, tasks.Description, tasks.Type from tasks, credential where tasks.owner=credential.ID and tasks.owner=userIdMaxTasks()
  ```
  View Tasks then renders two tables. Confirmed by screenshot:
  `userIdMaxTasks()` resolved to **Alice** (`ID=1`), who has 4 declared
  tasks in the seed data — more than any other user.
- **Elgg accounts (Section 2)**: `admin/seedadmin`, `alice/seedalice`,
  `boby/seedboby`, `charlie/seedcharlie`, `samy/seedsamy` — confirmed from
  page 6 of the brief and the `elgg.sql` seed dump.
- **Elgg has two separate profile fields the assignment's "About me" wording
  could mean**: a rich-text **About me** editor (form field name
  `description`) and a plain-text **Brief description** field (form field
  name `briefdescription`). Only Brief description executes an injected
  `<script>` tag — About me does not (student-confirmed by testing both).
  This lab's customised `output/text.php` and `engine/lib/input.php` (under
  `Labsetup-xss/Labsetup/image_www/elgg/`) are what disable the
  encoding/sanitisation that makes Brief description exploitable; `dropdown.php`
  and `url.php` are similarly patched but unused by any Q2.x answer so far.
- **Q2.1**: `<script>alert('Attack with XSS by s4041605');</script>` in
  Samy's Brief description → fires on Samy's own profile immediately after
  saving, and fires for Alice merely by opening the Members listing page
  (not just `profile/samy` directly — Elgg's Members list also renders each
  user's Brief description).
- **Q2.2**: `<script>alert(document.cookie);</script>` in the same field →
  each viewer's own `Elgg=...` session cookie appears in their own alert
  (Samy's and Alice's differ, confirmed by screenshot), proving the cookie
  is readable via `document.cookie` and therefore not `HttpOnly`.
- **Q2.3**: legitimate profile-edit POST goes to
  `http://www.seed-server.com/action/profile/edit` (`sendurl`); Samy's GUID
  is `59` (`samyGuid`), read from the `guid` field of a captured request
  while Samy edited his own profile; `desc` is the student number,
  `s4041605`, per the brief. The browser sends this request as
  `multipart/form-data`, while the skeleton's own XHR declares
  `application/x-www-form-urlencoded` — both work because Elgg's PHP action
  reads `$_POST` regardless of encoding, provided `Content-Type` matches the
  body actually sent.
- **Q2.4**: the completed Q2.3 script has to be minified onto one line to
  fit the Brief description input (every `//` comment stripped first, since
  a comment would otherwise silence the rest of the line, and one semicolon
  added after `Ajax.open(...)` that line-per-statement JS relied on ASI to
  supply). Alice's GUID turned out to be `56` (visible in the forged
  request's own form data, confirmed via her Network tab, Initiator
  `members:41 (xhr)`) — different from Samy's `59`, so the worm's `if` guard
  correctly proceeded. Result: Alice's About me field changed to `s4041605`
  automatically, with full before/network-capture/after evidence.

## LaTeX/build gotchas discovered this session (not obvious from source alone)

- This VM's Docker only has the standalone `docker-compose` binary (v1.27.4)
  — use the hyphenated form, not `docker compose`.
- **`listings`' plain `language=SQL` only recognises `--` as a comment, not
  MySQL's `#`.** Mixing `#` into that dialect makes the lexer mis-colour
  text after it as a string (red) instead of a comment (grey/italic),
  because the injected payload leaves an odd, mismatched quote count that
  confuses the lexer. **The fix that actually works: use
  `language={[MySQL]SQL}`** for any listing containing a `#`-based comment
  — this dialect understands `#` natively and needs no other intervention.
  (Do **not** reach for `escapeinside`/`moredelim` tricks — both were tried
  and abandoned this session; `[MySQL]SQL` is the clean, correct fix and is
  already in use in `section1.tex`.)
- **The shared `drtable` environment in `intellectus-designreport.sty` is
  fundamentally broken and must not be used.** `tabularx`'s column
  specification cannot be passed through a `\newenvironment` parameter —
  confirmed with an isolated minimal reproduction that fails even with a
  plain `{lll}` spec (no `X` columns needed to trigger it; the error is
  `Runaway argument? ... File ended while scanning use of \TX@get@body`).
  Instead, write `tabularx` directly wherever a table is needed:
  ```latex
  {\footnotesize
  \begin{tabularx}{\linewidth}{<colspec>}
  \toprule
  ... rows, \\ separated, & between cells ...
  \bottomrule
  \end{tabularx}
  \par}
  ```

## Writing-style preferences the student gave this session (on top of `CLAUDE.md`)

- **Never use "i.e." or "e.g." anywhere in the report** — spell it out in
  full instead (e.g. "for example" or "namely", but see previous rule — do
  not literally write "e.g." either).
- For a multi-stage exploit explanation, the student preferred: numbered
  `\paragraph{Step N: ...}` sections ending in a separate
  `\paragraph{Conclusion.}`, rather than one dense block (used in Q1.5's
  rewrite).
- When comparing two or more things side by side (such as the two fragments
  produced by a stacked-query split), use a small table instead of a bullet
  or enumerate list.
- A long single-line SQL statement that would otherwise be hard to read
  should be reformatted across multiple lines at clause boundaries (`select`
  / `from` / `where` / `order by` each on their own line), with an explicit
  note that the real statement has no actual line breaks — this is a
  readability reflow only, never a change in meaning.
- Before writing any answer, actually open and view every screenshot the
  student says they've placed in `figures/` at full resolution — do not
  write from the plan or from what a payload was "supposed to" produce.

## Suggested next steps

All report content is now written (see "Where things stand"). What's left is
polish and final submission prep, not new answers:

1. Ask whether to retroactively apply the "Steps + comparison table + no
   i.e./e.g." polish to Q1.1–Q1.4 for consistency with the Q1.5 rewrite (this
   was suggested after Section 1 and still not actioned).
2. Before final submission: a full visual QA pass per `CLAUDE.md`'s "Build
   and quality assurance" section — the build itself is already confirmed
   clean (0 errors/overfull/unresolved refs, 31 pages, stale-marker scan
   clean), but nobody has yet visually inspected *every* page end-to-end in
   one pass (cover, full TOC, every answer page, every figure, headers/
   footers/page numbers consistency) — most pages were checked individually
   as each question was written, not as a final connected read-through.
3. The assignment brief also asks for a video recording per section
   ("Write a report ... as well as a video recording to demonstrate") — this
   report only covers the written report deliverable. Check with the student
   whether the recordings still need to be made/edited/packaged; that is
   outside this session's scope so far.
4. Confirm submission packaging: the brief wants "a single ZIP file
   (PDF/Word Doc + demo video)" uploaded to Canvas — nothing in this repo
   builds that zip yet.

---

## Prompt to paste into a new or compacted session

```
Read CLAUDE.md and claude2.md in this project directory before doing
anything else, then continue the Assignment 3 report work from where the
previous session left off.
```
