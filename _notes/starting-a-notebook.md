---
title: "Starting a notebook"
date: 2026-05-29
permalink: /notes/starting-a-notebook/
lang: en
alternate: /zh/notes/starting-a-notebook/
description: "What this notebook is for: working notes with claims you can check, not polished announcements."
excerpt: "A public engineering notebook earns its keep when each note carries one useful claim, a concrete decision, and enough evidence that a skeptical reader can verify both."
---

This section is a public engineering notebook. It is not a blog of announcements, and it is not a polished essay series. It is the place where a working decision gets written down while the trade-off is still sharp — so a later reader, including me, can see *what was claimed* and *what would falsify it*.

Put the most decision-relevant evidence first, then make its limits easy to find. This page is older: it was the seed that said the section would exist. That is no longer enough. Below is the editorial contract the notebook actually runs on.

## Why keep it public

Private scratch is fine for thought that is still forming. A public note has a different job. It has to survive a cold reader who has not watched the work happen.

That means the note is not "what I learned today." It is a small, checkable argument: a claim about software that can be held next to code, a release decision, a gate, or a measurement. The constant-time [warrant note]({{ '/notes/constant-time-warrant/' | relative_url }}) is the template in reverse: the hard part is not defining constant-time; it is transferring warrant for a claim about *this* code. The notebook is for claims of that kind — smaller ones included.

## What earns a note

A note belongs here when it has at least three pieces:

1. **One useful claim** — something a reader can agree or disagree with, not a mood.
2. **A concrete engineering decision** — a gate threshold, a skipped release, a trait boundary, a disclosure choice.
3. **Evidence a stranger can follow** — a path into the repo, a public tag, a measurement provenance, a linked case study.

Examples already on the site:

- How a constant-time claim transfers warrant — [A constant-time claim is a trust problem, not a comprehension problem]({{ '/notes/constant-time-warrant/' | relative_url }}).
- Why a release that changes no output bytes does not deserve a version number — [Skipping the releases that change nothing]({{ '/notes/releases-that-change-nothing/' | relative_url }}), tied to the [gm-crypto-rs release history]({{ '/projects/gm-crypto-rs/releases/' | relative_url }}).
- How a constant-time CI gate is wired, and what it costs on every PR — [The constant-time CI gate]({{ '/notes/constant-time-ci-gate/' | relative_url }}).
- When sharing code is not yet a reason to share a package — [Sharing code is not the same decision as sharing a package]({{ '/notes/extraction-trigger/' | relative_url }}).
- When `unsafe` is an opt-in surface rather than a default — [Unsafe as opt-in]({{ '/notes/unsafe-opt-in/' | relative_url }}).

If those three pieces are not there yet, the thought stays private until they are.

## What does not belong

- **Status-only updates** — "shipped X," "still working on Y," with no decision or evidence.
- **Generic lessons** — advice that would fit any project without naming a constraint.
- **Release notes that already have a home** — version tables and crate history live on the project pages; a note only appears when the *policy* behind a skip or a gate needs its own argument.
- **Meta about the notebook itself** — after this page, the section should not keep explaining that it exists. The lede on the [notes index]({{ '/notes/' | relative_url }}) carries that role for first-time visitors.

## A worked example

The gm-crypto-rs line that skips crates.io versions is easy to misread as "lazy shipping." The real rule is narrower: if a cycle changes no runtime output byte and only hardens tests, tooling, or process, it merges without a published version. That rule is stated under Evidence on the [case study]({{ '/projects/gm-crypto-rs/' | relative_url }}) and spelled out as an argument in the releases note — including the gaps a reader can check on crates.io. The notebook is for that middle layer: not the version table alone, and not a vague essay on "shipping discipline," but the claim + the rule + the places to verify it.

## The promise to the reader

Notes may be provisional. Numbers age; gates move; a private snapshot can become a public tag. What should not be provisional is the honesty of the frame: if something is a detection event rather than a proof, the note says so; if source is private, the note does not pretend a visitor can open it; if a release was skipped, the note does not call the work "unpublished" as if it were still coming.

Write it down while it is still annoying. That is when the detail is sharp — and when a later, calmer edit can still keep the claim checkable.
