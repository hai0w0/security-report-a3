# Claude guide for the Assignment 3 report

## Purpose

Use this guide when writing or maintaining Tran Dinh Hai's INTE2547-2580
Security Testing Assignment 3 report. The goal is a concise, professional,
evidence-backed report in the existing RMIT LaTeX design.

This guide controls writing style and workflow. It is not evidence and does
not override the assignment brief or the student's current instruction.

## Source priority

Resolve conflicts in this order:

1. The student's current explicit instruction.
2. Security Testing Assignment 3.pdf and its rubric.
3. Genuine screenshots, outputs, recordings, and lab source supplied here.
4. Verified student notes and existing completed answers.
5. prompt.md, README.md, and the LaTeX template conventions.
6. External authoritative sources when research is genuinely required.

Never infer a technical result from this guide, a placeholder, a filename, or
an expected lab outcome.

## Required preparation

Before editing:

1. Read prompt.md completely.
2. Read README.md and the official assignment PDF.
3. Inspect the relevant section file, lab archive source, and figures.
4. View every screenshot used for the answer at readable resolution.
5. Separate verified observations from explanation and missing evidence.
6. State briefly which answer will change and what evidence supports it.

Do not replace unrelated student work. Do not write substantive answers in
security_report.tex; keep them in sections/sectionN.tex.

## Writing voice

Write clear academic English at the student's level. Sound precise and
confident where evidence is conclusive, but never stronger than the evidence.

- Begin with the direct answer or demonstrated outcome.
- Prefer short, connected paragraphs over a large list of disconnected facts.
- Use first person for actions genuinely performed by the student, such as
  I entered, I submitted, or I observed.
- Use present tense when explaining what source code does.
- Use past tense when describing the recorded experiment.
- Name exact inputs, variables, files, values, and outputs.
- Explain cause and effect rather than merely narrating screenshots.
- Distinguish an observation from an inference.
- End with a short conclusion that directly satisfies the question.

Avoid inflated language, generic introductions, repeated conclusions, and
claims such as clearly, obviously, or as we can see. Do not describe a
screenshot without explaining what claim it proves.

## Structure for each answer

Use this order unless the question requires a different sequence:

1. Direct result: state what was achieved using the exact tested input.
2. Relevant code: reproduce the assignment or application snippet faithfully.
3. Vulnerability analysis: trace untrusted input through the code and identify
   the missing control, such as parameterised queries or output encoding.
4. Constructed operation: show the resulting query, request, or script after
   substituting the verified values.
5. Mechanism: explain syntax and control flow step by step.
6. Evidence: place each screenshot near the claim it supports and interpret it.
7. Conclusion: connect the observed result back to the question.

For a security test, explain this chain:

    attacker-controlled input
        -> vulnerable application operation
        -> changed interpretation by the server or browser
        -> application control-flow decision
        -> observed result

Do not stop after presenting a payload. Explain why every significant token
changes the operation and why the application accepts the result.

## Handling supplied code

When the question gives a code snippet, include it before analysing the
vulnerability. Use a listing rather than trying to typeset programming syntax
as ordinary LaTeX prose.

    \begin{lstlisting}
    supplied code here
    \end{lstlisting}

Preserve variable names, field names, case, and meaningful punctuation. It is
acceptable to normalise curly word-processor quotation marks to valid ASCII
code quotation marks. If the actual lab source differs from the abbreviated
assignment snippet, identify the difference without silently merging them.

Analyse the snippet concretely:

- Identify the source of each user-controlled value.
- Explain any transformation, such as hashing or URL decoding.
- Identify where values are concatenated into an interpreter command.
- State which security boundary is missing.
- Substitute the tested values and show the resulting operation.
- Reduce it to its effective logic after comments or control operators apply.
- Connect the returned value to the subsequent application branch.

Only describe a command or payload as executed when a screenshot, transcript,
history, or explicit student confirmation supports that statement.

## Evidence discipline

Never fabricate or guess:

- commands claimed to have been run;
- payloads claimed to have been submitted;
- database rows, identifiers, hashes, tokens, or credentials;
- scan output, web responses, alerts, logs, or screenshots;
- timestamps, success states, citations, or rubric requirements.

Use the exact values visible in genuine evidence. If evidence is incomplete,
leave a visible TODO that names the precise missing screenshot, output, value,
or student confirmation.

Treat screenshots as historical evidence:

- Do not crop, edit, recolour, or redact them in a way that changes meaning.
- Check that the relevant input, URL, output, user identity, or result is
  legible.
- Use a descriptive caption stating what is shown.
- Refer to the figure in prose and explain what it demonstrates.
- Do not use decorative or redundant screenshots.

Use observations conservatively. A successful profile page can establish that
the application returned and displayed that account. It does not establish an
unseen server state or command unless other evidence supports that claim.

## LaTeX conventions

Keep the official question text unchanged:

    \drquestion{Q1.1}{Concise contents description}{%
      Exact question from the brief.
    }

Start the response with:

    \dranswer

Use listings for code, commands, generated queries, and output:

    \begin{lstlisting}[language=SQL]
    SELECT ...
    \end{lstlisting}

Omit the language option if the local listings package does not support the
language. Keep long lines within the page width and never alter meaningful
syntax merely to improve wrapping.

Insert verified figures with:

    \drfigure{figures/descriptive-name.png}{Meaningful caption.}{fig:unique-label}

Refer to them as Figure~\ref{fig:unique-label}. Labels must be unique and
stable. Replace a figure stub only when the genuine image exists.

Escape LaTeX special characters in prose, including \#, \%, \$, \_, and \&.
Characters inside lstlisting normally remain literal.

Do not add a bibliography, appendix content, declaration, list of figures, or
new front matter unless the brief or student requires it.

## Q1.1 quality model

For the current Q1.1 answer, a professional response should contain all of the
following:

1. The authentication snippet supplied in the assignment, formatted as code.
2. An explanation that username and password originate in GET parameters.
3. An explanation that SHA-1 hashing the password does not protect the query
   because the username remains concatenated into SQL syntax.
4. The verified username input and the fact that the password was blank.
5. The constructed WHERE condition, including the SHA-1 digest of the blank
   password when this is derived from the inspected source.
6. A token-level explanation:
   - Ted selects the intended account name.
   - The apostrophe closes the SQL string literal.
   - The MySQL hash character comments out the remaining password predicate.
   - The effective condition therefore selects Ted by name alone.
7. An explanation of the PHP control flow: a returned row provides a non-empty
   ID, which the application treats as successful authentication before
   creating a session and rendering the profile.
8. Genuine evidence of the submitted input and the resulting Ted profile.
9. A conclusion that the evidence demonstrates login without Ted's password.

When discussing URL encoding, distinguish the typed hash character from its
transport representation. The browser may display percent-23 in the URL, but
PHP receives the decoded hash character used by the SQL payload.

Do not claim that password hashing itself was cracked or bypassed. The password
predicate was removed from the effective query by comment syntax.

## Technical depth

Aim for enough detail that a reader can reproduce the reasoning without
guessing, but do not pad the answer with textbook history. For each technical
claim, ask:

- What exact source or screenshot supports this?
- What does the relevant line of code do?
- How does the tested input change its interpretation?
- What application decision follows?
- What does the evidence prove, and what does it not prove?

Explain mitigations only when the question requests them or when one concise
sentence materially clarifies the vulnerability. Do not let mitigation advice
replace analysis of the demonstrated attack.

## Build and quality assurance

After substantive LaTeX edits:

1. Build with XeLaTeX three times.
2. Treat errors, missing files, unresolved references, rerun warnings, and
   overfull boxes as failures.
3. Inspect the cover, contents, edited answer pages, code listings, figures,
   and final page.
4. Check that screenshots are legible and preserve their aspect ratio.
5. Check that captions, references, headers, footers, and page numbers match.
6. Search source and PDF for stale TODO markers, placeholders, and incorrect
   assignment references.

At handoff, report:

- files changed;
- PDF path and page count;
- error, overfull-box, missing-file, and unresolved-warning counts;
- evidence still required;
- whether the document is a draft or submission-ready.

Never call the report submission-ready while later questions or evidence
remain incomplete.

## Final review checklist

Before accepting an answer, confirm:

- The official question appears once and has not been paraphrased.
- The answer begins directly and follows a coherent causal sequence.
- Supplied code is included and analysed rather than merely pasted.
- Every executed action is supported by evidence.
- Every screenshot is cited and interpreted.
- Observations and inferences are clearly distinguished.
- Exact student-specific and lab-specific values are preserved.
- No output, result, citation, or requirement has been invented.
- LaTeX compiles cleanly and the rendered pages are readable.
