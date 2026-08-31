# Stripeclub

A stripe pattern generator. The second of a set of small design tools, and it
consumes palettes from [Pandatone](https://github.com/bobbymeyer/pandatone)
the way a later tool will consume this one.

## The argument

**A pattern carries no colour.** It is structure: how many slots, how wide
each stripe, in what order, at what angle. Whether a design reads as high-key,
low-key or split is a property of the palette applied to it, not of the
pattern — so a pattern is composed in value and dressed afterwards.

Two consequences the code is built around:

- **The ground is a stripe.** Slot 0 is the ground and takes a stripe of its
  own. There are no blank stripes and nothing shows through.
- **A colorway is a rule, not a list.** It is a palette plus one rule per
  value, so it survives the structure being edited underneath it. A list of
  hex assignments would not.

## What is here

| | |
| --- | --- |
| `Pattern` | Name, slot count, angle. Structure only — two schema tests hold it that way |
| `Value` | A rank, 0 to n−1. Slot 0 is the ground. No luminance, no colour |
| `Sequence` | The repeat unit. Its stripe widths are proportions and sum to one |
| `Stripe` | A width and the value it draws |
| `Colorway` | A pattern wearing a palette, as per-value rules over a snapshot |
| `PaletteSnapshot` | The colours as they were when the palette was chosen |
| `Luminance` | OKLab's L, computed here because Pandatone's brightness is not perceptual |
| `Pandatone::Client` | The v1 API, fetched once a session and filtered locally |
| `SvgPattern` | A colorway as an SVG `<pattern>`. The reference form |
| `ValueScale` | A pattern with no palette, drawn in value, paper to ink |

Build order and what is left: `Step N` in the task list. Steps 1–4 are done —
structure, Pandatone, colorways with Auto-Value-Match, and the axis-aligned
SVG render. Angle and Snap To Tiling are next.

## Styling

[its-swiss](https://github.com/bobbymeyer/its-swiss), tracked from `main`
rather than pinned: Stripeclub is the second consumer its gem boundary was
waiting for, so the two are developed against each other.

```sh
bundle update its-swiss
```

Everything the gem ships is inside a cascade layer and everything in
`app/assets/stylesheets` is not, so the application wins without
out-specifying anything. What Stripeclub found is in
[ITS-SWISS-CANDIDATES.md](ITS-SWISS-CANDIDATES.md) — two real bugs, two
boundary questions, and a note on what held.

## Running it

```sh
bin/setup
bin/rails db:seed     # twelve patterns to look at
bin/rails server
```

`/its-swiss/specimen` in development renders every component the gem ships.

## Tests

```sh
bin/rails test
```

Tests come first, and a guard is kept only if breaking what it guards makes it
fail — the commit messages say which mutation was used on which guard.

The suite reads structure rather than pixels. There are golden SVG documents
in `test/fixtures/files/svg`, compared byte for byte and regenerated with
`GOLDEN=overwrite`; read the diff before accepting one. There are no pixel
tests.
