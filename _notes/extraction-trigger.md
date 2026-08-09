---
title: "Sharing code is not the same decision as sharing a package"
date: 2026-08-09
permalink: /notes/extraction-trigger/
lang: en
alternate: /zh/notes/extraction-trigger/
description: "Two systems sharing a render pipeline isn't a reason to extract it into its own package today. A pre-decided, written-down trigger is - and the two get confused more often than they should."
excerpt: "The reflexive move when two things share code is to extract it into its own package. That's the wrong test. The right one is a trigger, decided and named before anyone needs it."
---

Two things sharing code is a fact about the code. Whether they should share a
*package* is a distribution decision, and the two get conflated the moment
"extract it" starts to feel like the obviously correct next step — clean,
tidy, the kind of change a reviewer nods at without asking why now.

[The explainer engine]({{ '/projects/explainer-engine/' | relative_url }})
needed the same render pipeline a desktop batch-render GUI in the same
repository already had: the same job model, the same subprocess runner, the
same command-line construction. The reflexive move is a new top-level
package — installed by both, imported by neither application layer directly.
I looked at what that would actually buy today, and it was less than it
looks.

## What extraction would cost, and what it wouldn't buy

Moving the shared code out from under the GUI's package is mechanical: a
handful of import lines, zero behavior change. What it would not do is
decouple installation. Both consumers ship from one distribution today, so
nothing downstream can install the render pipeline without also pulling in
the GUI's Qt dependency — whether the import path points at the GUI's own
namespace or a neutral one. Renaming fixes a smell, not a constraint. That's
a real motive for a refactor. It's a weak one to spend a session on before
something forces the question.

## What the decision actually pins down

The part worth writing down wasn't "leave it where it is" — that's a
non-decision, indistinguishable from not having thought about it. It was
drawing the boundary precisely enough to enforce, and naming the one
exception instead of letting it stay implicit. This repository is private,
so there's no line to click through the way there would be for a public one;
what follows is quoted verbatim rather than paraphrased, because a paraphrase
is the wrong thing to offer as evidence for a claim nobody can go check
themselves:

> `app/render` is the shared render core. `app/ui` and `explainer/` may
> depend on it; nothing may depend back on `app/ui` or `explainer/`.
>
> The core is Qt-free EXCEPT `app/render/worker.py`, which is explicitly the
> GUI-side Qt adapter (QThread). `explainer/` must never import
> `app.render.worker`, and no other core module may import it either (it is
> not part of the core API).

"Qt-free except one named file" is a different kind of claim than "we try to
keep the core Qt-free" — the first is checkable, the second is a mood. An
automated check parses every file for its real imports — plain `import`
statements, `from ... import`, constant-string dynamic imports — and fails
the build if `explainer/` reaches for anything under the GUI's namespace
outside the render core, if anything in the core imports Qt except the one
named exception, or if anything in the core reaches back into the GUI layer.
The boundary isn't a comment anyone can drift past; it's a rule anyone has
to fail past.

## The trigger, decided before it's needed

The part that matters more than the boundary is what happens when it stops
being enough. Rather than leave that call for whoever hits it first — under
whatever deadline they're hitting it under — the decision names the trigger
now:

> Extraction trigger (pre-decided, do not re-litigate): extract
> `render_core/` when a NEW consumer of the core appears beyond the current
> two (`app/ui`, `explainer/`), or when the distribution splits (e.g.
> shipping the explainer without Qt deps). It is a ~1h mechanical move.

Neither condition has fired. A third consumer isn't close, and one packaging
file still ships both entry points. So the code stays where it is, and the
engine keeps importing from a namespace that visibly belongs to the GUI —
which will keep reading a little odd until the trigger does. That's a
disclosed cost, not an oversight: the alternative was spending real time on
mechanical churn today against a benefit that isn't available to collect
yet.

The trade generalizes past the Qt specifics. "Should this be extracted" has
a sharper form than it's usually asked in — not "would this be cleaner,"
which is almost always yes, but "what, specifically, would have to become
true for the current shape to be wrong." Decided once, while calm, so a
later session checks a condition instead of re-arguing an architecture from
scratch under whatever pressure made the question feel urgent.
