# Topic file format

Shared by the maintain skill and anyone writing a topic. Keep each topic file under 150 lines; split a topic that outgrows it and update the index in `../SKILL.md`.

## Relationship to mame-review

[mame-review](~/source/mame-ai-tips/mame-review/) (rb6502; `RULES.md`, `STYLE.md`, `SYSTEMS.md`, `DATAFILES.md`, `SUBMISSION.md`) is the review checklist: terse rules with IDs (`C-2`, `D-6`, `L-1`). A topic is the **writing companion** to it:

- cite a mame-review rule by ID instead of restating it; one clause of context is enough
- carry what mame-review lacks: a working **Do** snippet, the **Legacy forms** an agent meets in old code, **Since** history, and APIs mame-review does not cover
- a topic rule that contradicts mame-review is resolved by tier and the disagreement noted in the rule

## Authority tiers

When sources disagree, the lower tier number wins. Tag every piece of evidence with its tier.

- **T1** — `[[deprecated]]` attributes, `#error`/`static_assert` guards, and comments in core headers (`src/emu`, `src/lib/util`)
- **T2** — in-tree docs (`docs/source`) and mame-review rules, cited by ID (`[T2] mame-review C-2`). Where the two disagree, the docs win and the disagreement is noted. mame-review's own cited commits and PRs count as evidence without re-checking.
- **T3** — core maintainer commits in `src/emu` / `src/lib/util`
- **T4** — human maintainer review comments on merged PRs
- **T5** — majority practice in files added during the last year

A T5 observation that contradicts T1–T4 is recorded as a deviation, never as the rule.

## Skeleton

````markdown
# <Topic>

<One line: what this topic covers. mame-review rules that govern it: <IDs>.>

## TL;DR

- <3–6 bullets, each a Do>

## Rules

### <Rule name>

**Do**

```cpp
<minimal snippet>
```

<1–3 lines of explanation, only where the snippet is not self-evident.>

**Legacy forms**: <old patterns to recognize, inline code>
**Since**: <hash (date)>, or `established` with the earliest evidence
**Evidence**: [T1] `src/emu/x.h` — <what it shows>; [T2] mame-review D-6; [T5] <count/observation>
**Key symbols**: `SYMBOL_A`, `symbol_b`

## Superseded

<Rules that were once current: the old rule, "superseded by <rule> in <hash>". Kept so agents recognize them.>

## Examples

- `path/to/file.cpp` @ `<hash>` — <what it demonstrates; note any part that deviates>
````

## Conventions

- Evidence cites file + symbol, with a hash when it points at history. Avoid bare line numbers; they rot.
- **Key symbols** are exact identifiers the scan greps for to detect renames and removals.
- At most 2 examples per topic, pinned to the last commit that touched the file.
