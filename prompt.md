# Assignment 3 Security Testing Report — Codex Working Prompt

## Purpose

Use this file as the persistent working brief for creating and maintaining Tran
Dinh Hai's INTE2547-2580 Security Testing Assignment 3 report. Read this entire
file before inspecting, editing, building, or reviewing the report.

The objective is to produce a polished, accurate, evidence-backed LaTeX report
using the supplied RMIT navy/red design. The Assignment 3 brief, rubric, genuine
lab results, screenshots, commands, and the student's instructions are the
sources of truth. Never invent technical results or evidence to make the report
look complete.

## Project identity

- Student: Tran Dinh Hai
- Student ID: s4041605
- Course: INTE2547-2580 Security Testing
- Deliverable: Assignment 3 report
- Lecturer currently shown on the cover: Dr. Sreenivas Tirumala
- Submission type currently shown: individual assignment
- Main source file: security_report.tex
- Compiled deliverable: security_report.pdf
- Intended LaTeX engine: XeLaTeX

Verify all metadata against the Assignment 3 brief when it becomes available.
Update metadata only when the brief or student confirms a change.

## Current state

This directory is a standalone Assignment 3 template derived from the completed
Assignment 2 report design. It includes:

- the geometric Security Testing cover adapted to display Assignment 3;
- the RMIT navy/red typography, header, footer, captions, tables, and listings;
- a modular sections directory;
- a starter question and answer block;
- genuine-evidence figure placeholders;
- a reusable component library under examples;
- a compiled four-page placeholder PDF.

At the time this prompt was created, the actual Assignment 3 brief, rubric,
questions, answers, and Assignment 3 evidence were not present. The visible
Q1.1 text and TODO content are scaffolding, not real assignment content.

Do not infer Assignment 3 questions from Assignment 2. Do not copy Assignment 2
answers, commands, outputs, screenshots, IP addresses, keys, rules, or findings
unless the Assignment 3 brief explicitly requires the same material and the
student confirms that it is valid evidence for the new submission.

## Source-of-truth order

Use the following priority when information conflicts:

1. The student's current explicit instruction.
2. The official Assignment 3 brief and rubric supplied in this directory.
3. Genuine Assignment 3 lab evidence supplied by the student.
4. Verified student-authored notes and draft answers.
5. Existing template conventions and examples.
6. External authoritative references, only when research is required.

Do not treat this prompt, the component examples, TODO text, filenames, or
placeholder captions as evidence about Assignment 3.

## First actions in every new session

1. Read this file completely.
2. Inspect the directory without modifying anything.
3. Locate the Assignment 3 brief, rubric, draft answers, screenshots, command
   transcripts, configuration files, and any existing PDF.
4. Inspect security_report.tex, template-commands.tex, the files in sections,
   the figures directory, and README.md.
5. Determine which content is verified, which is draft, and which is missing.
6. If the brief is available, extract its exact questions, marking criteria,
   formatting requirements, word limits, evidence requirements, and submission
   constraints before editing.
7. If the brief is absent, tell the student that it is required and ask them to
   provide it. Continue only with safe template maintenance; do not invent the
   report structure or substantive answers.
8. Before a major edit, briefly state what will change and what evidence or
   assumptions the change relies on.

## Security-testing and evidence safeguards

This is authorized university coursework. Keep all work within the scope of the
course lab, supplied targets, and the student's explicit authorization.

Never fabricate or guess:

- scan results, open ports, services, vulnerabilities, CVEs, or severity;
- target IP addresses, subnet values, hostnames, usernames, or passwords;
- encryption keys, initialization vectors, hashes, tokens, or flags;
- firewall rules, packet counters, IDS alerts, or log entries;
- commands claimed to have been executed;
- terminal output, screenshots, timestamps, or test success;
- references, quotations, page numbers, or rubric requirements.

Do not run intrusive scans, exploitation, destructive commands, credential
attacks, or tests against systems outside the explicitly authorized lab scope.
Ask before any action that could alter lab state, delete data, disrupt services,
or contact an external target.

If genuine evidence is missing, preserve a clearly labelled placeholder and
record the gap. A visibly incomplete report is preferable to falsified evidence.

Treat supplied command output and screenshots as historical evidence. Do not
silently rewrite, crop, recolor, or “correct” evidence in a way that changes its
meaning. If an apparent inconsistency exists, explain it to the student and ask
for confirmation.

Never expose secrets unnecessarily. If genuine evidence contains credentials,
private keys, access tokens, or unrelated personal information, tell the student
and propose a minimally redacted presentation that preserves the assessed
result.

## Report writing standard

Write in clear, professional academic English at the student's level. Prefer
direct explanations over inflated language. Each answer should:

- begin by answering the question directly;
- explain why the answer is correct;
- connect commands or configurations to their purpose;
- interpret the relevant output instead of merely pasting it;
- connect evidence to the claim it supports;
- distinguish observation from inference;
- state limitations or uncertainty honestly;
- use the exact values shown in genuine evidence.

Preserve the student's verified wording and technical claims unless the student
requests substantive editing or a clear grammatical correction does not change
meaning. Do not make the report sound artificially generic or detached from the
actual lab work.

Keep question wording exactly as supplied by the brief. Do not paraphrase the
question in the body. A concise descriptive version may be used only for the
Table of Contents entry.

Avoid unnecessary introductions, repeated conclusions, filler paragraphs, and
topic headings between every question. Unless the brief requires otherwise,
retain the compact question-and-answer structure used by the template.

## LaTeX project structure

Keep responsibilities separated:

- security_report.tex: document metadata, cover, PDF metadata, section
  inclusion order, contents page, and appendix inclusion.
- template-commands.tex: reusable Assignment 3 question and answer commands.
- sections/sectionN.tex: substantive questions and answers for the matching
  assignment section.
- sections/appendix.tex: supporting material permitted by the brief.
- figures/: genuine Assignment 3 screenshots and diagrams plus the cover image.
- intellectus-designreport.sty: shared visual design, geometry, listings,
  figures, captions, tables, header, and footer.
- examples/component-examples.tex: copyable examples only; it is not report
  content and must not be included in the final submission.
- README.md: build and editing quick reference.

Create additional section files when the brief requires them and include each
file explicitly from security_report.tex. Use predictable names such as
sections/section2.tex and sections/section3.tex.

Do not place substantive answers directly in security_report.tex.

## Required question format

Use the reusable question command:

    \drquestion{Q1.1}{Concise contents description}{%
      Paste the exact Assignment 3 question here.
    }

Then begin the response with:

    \dranswer

The first argument is the official question identifier. The second argument is
a short, descriptive Table of Contents entry. The third argument is the exact
question text.

Do not manually reproduce the heading format when the command can be used.
Keep question identifiers, contents entries, captions, and labels consistent.

## Figures and screenshots

Store genuine Assignment 3 evidence in figures/ using descriptive names, for
example:

    figures/q1-1-snort-alert.png
    figures/q2-3-nmap-result.png
    figures/q3-2-firewall-counters.png

Insert genuine evidence with:

    \drfigure{figures/q1-1-snort-alert.png}{Snort alert generated during the Q1.1 test.}{fig:q1-1-snort-alert}

Until the genuine file exists, use:

    \drfigurestub{Snort alert required for Q1.1.}{fig:q1-1-snort-alert}

Every figure must have:

- a meaningful caption stating what is shown;
- a unique, stable label;
- explanatory text in the answer describing what the evidence demonstrates;
- a legible crop and sufficient resolution;
- values consistent with the surrounding answer.

Do not add decorative screenshots. Include evidence because it proves a
required step, output, configuration, or result.

When replacing a placeholder, preserve its caption intent and label unless the
brief or evidence requires a precise correction.

## Commands, source code, and output

Use listings for commands and code:

    \begin{lstlisting}[language=bash]
    sudo command --option value
    \end{lstlisting}

Only present a command as executed when genuine output, a screenshot, a command
history, or the student's confirmation supports that claim. Otherwise label it
as a proposed command or leave a TODO requesting evidence.

Keep command syntax and output faithful to the source. Do not silently replace
student-specific interfaces, paths, IP addresses, rule IDs, or version-specific
options. If a command appears technically wrong, distinguish between:

- faithfully reporting what was executed;
- explaining why the observed result occurred; and
- proposing a corrected follow-up command.

Never present proposed output as observed output.

## Tables

Use the existing navy header and alternating pale-row style. Start from the
component example in examples/component-examples.tex. Keep tables inside the
text width, use concise cells, and move long explanations into prose when a
table becomes cramped.

Every table must have a descriptive caption. Avoid tables that merely repeat
nearby prose.

## References and external research

First check whether the brief requires a particular citation style. Do not add a
bibliography, reference section, or citation package unless required by the
brief or requested by the student.

When external research is needed:

- prefer official documentation, standards, vendor manuals, primary research,
  and recognized security authorities;
- verify current facts online when versions, vulnerabilities, standards, or
  product behavior may have changed;
- cite the exact source supporting each technical claim;
- use stable links and access dates if the required style calls for them;
- avoid relying on search snippets, low-quality tutorials, or unverifiable
  summaries;
- do not overquote sources.

Use \url{} or another breakable URL mechanism for long links so they stay
inside the page margins.

## Design invariants

Preserve the established visual design unless the student explicitly requests a
redesign:

- A4 paper with explicit margins from intellectus-designreport.sty;
- navy/red RMIT visual language;
- Arial or the configured fallback sans-serif font;
- geometric full-page cover;
- unnumbered cover;
- Arabic page numbering with the Table of Contents beginning at page 1;
- RMIT header and right-aligned page number;
- numbered, captioned figures and tables;
- per-section figure and table numbering;
- red answer labels;
- styled code listings;
- concise descriptive contents entries.

Do not add a List of Figures, List of Tables, declaration page, introductory
section, or additional front matter unless the Assignment 3 brief requires it
or the student asks.

The cover background file still contains the original Assignment 2 artwork.
security_report.tex non-destructively covers that line and typesets
ASSIGNMENT 3. Do not edit or overwrite the source JPEG merely to change the
number. If the student name, lecturer, course title, or cover layout changes,
update the cover carefully and visually inspect it.

## Editing workflow

For substantive report work:

1. Inventory all supplied files and evidence.
2. Extract the brief and rubric into a checklist.
3. Map every official question and rubric criterion to a section file.
4. Scaffold the exact questions before drafting answers.
5. Reuse verified student wording and evidence.
6. Draft direct answers with explanation and evidence interpretation.
7. Add figures, listings, tables, and references only where supported.
8. Mark unresolved evidence requirements with visible TODO or figure stubs.
9. Build and inspect the report.
10. Report what is complete, what changed, and what genuine evidence is still
    required.

Make focused edits. Preserve unrelated student work and existing evidence. Do
not delete or overwrite user files simply to simplify the directory.

## Build process

Run builds from the project root:

    xelatex -interaction=nonstopmode -halt-on-error security_report.tex
    xelatex -interaction=nonstopmode -halt-on-error security_report.tex
    xelatex -interaction=nonstopmode -halt-on-error security_report.tex

Alternatively:

    latexmk -xelatex security_report.tex

Build three passes, or until the Table of Contents, references, bookmarks, and
page labels stabilize.

Treat the following as failures:

- LaTeX errors;
- missing files;
- undefined references;
- unresolved rerun warnings;
- overfull horizontal or vertical boxes;
- clipped figures, tables, listings, headers, or footers;
- broken contents entries or page numbers.

Underfull boxes are review signals. Fix them when they create a visible defect,
especially in tables.

## Visual quality assurance

After substantive edits, render and inspect at least:

- the cover;
- the Table of Contents;
- a dense prose page;
- a page containing code or a table;
- a page containing a figure or placeholder;
- the final page;
- every page near a layout warning.

Verify:

- the cover says Assignment 3 and contains no visible remnants of Assignment 2
  on the assignment-number line;
- headers, footers, and page numbers are consistent;
- all text remains inside the A4 text block;
- screenshots are legible and not stretched;
- captions match their figures;
- table rows and code lines do not overflow;
- section and question breaks are not awkward;
- contents entries are concise and point to the correct pages;
- no submission content is hidden behind a placeholder or clipped at a page
  boundary.

Before calling the report submission-ready, search the source and PDF for:

- TODO;
- PLACEHOLDER;
- “Replace this text”;
- missing-evidence captions;
- Assignment 2 references that should not be present;
- stale question numbers;
- missing or duplicate labels.

## Completion criteria

The report is complete only when:

- every official Assignment 3 question appears exactly once;
- every rubric requirement is addressed or explicitly identified as pending;
- every technical claim is supported by reasoning, genuine evidence, or a
  suitable authoritative reference;
- all screenshots and outputs are genuine and legible;
- metadata is correct;
- the appendix contains only permitted supporting material;
- all temporary TODO text and unused placeholders are removed;
- XeLaTeX completes cleanly with stabilized references;
- visual inspection finds no clipping, overflow, broken hierarchy, or awkward
  pagination.

At handoff, report:

- the final PDF path and page count;
- the files changed;
- the counts of errors, overfull boxes, missing files, and unresolved warnings;
- any remaining evidence gaps or student decisions;
- whether the report is a draft or submission-ready.

Never describe a draft with missing evidence as submission-ready.

## Communication with the student

Lead with the result or blocker. Keep updates concise and concrete. When
evidence is missing, name the exact question and the exact screenshot, command
output, explanation, or value required.

Ask only questions that cannot be answered from the brief, rubric, repository,
or genuine evidence. Make safe assumptions for formatting, but never assume
technical results.

When offering corrections, explain the evidence and reasoning so the student
can verify the change.

## Suggested first request in a new Codex session

The student may say:

    Read prompt.md completely, inspect the current Assignment 3 project, and
    continue the report using only the supplied brief and genuine evidence.
    Tell me what is present, what is missing, and the next concrete step.

If AGENTS.md is present and active, Codex should read this file automatically
before work. Even then, explicitly requesting “read prompt.md” is a useful
confirmation at the start of an important editing session.

