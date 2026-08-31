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
| `Row` | A band, and what is done to the repeat inside it |
| `SvgPattern` | A colorway as an SVG `<pattern>`. The reference form |
| `ValueScale` | A pattern with no palette, drawn in value, paper to ink |
| `Tile` | One closing tile: how big it has to be, and what colour is at any point |
| `TilePng` | That function, sampled — four times a pixel, so an angled edge is an edge |
| `Tiling` / `SnapToTiling` | Whether the repeat closes, per output mode, and the nearest angle that does |

Steps 1–9 of the build order are done. Round two — the imperfect stripes, with
`feTurbulence` edges and seeded width jitter — is what is left.

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

## API

Everything is under `/api/v1`, read-only. Collections are bare arrays, no
envelope. `404` with `{"error": "Not found"}`, `401` with
`{"error": "Unauthorized"}`, `422` with a reason when a colorway cannot dress
its pattern.

```sh
curl https://stripeclub.example.com/api/v1/patterns/Awning/tile.svg
```

Stripeclub has no accounts, so the credential is one token rather than a user.
Set `STRIPECLUB_API_TOKEN` and it is required; leave it unset and the API is
open, which is what a tool on your own machine wants. **In production an unset
token closes the API rather than opening it** — a design tool on the internet
with its API open is not a decision anyone makes on purpose. `Token` works as
well as `Bearer`. The session cookie is not accepted, because there isn't one.

| Verb | Path | Notes |
| ---- | ---- | ----- |
| GET | `/patterns` | Every pattern, by name |
| GET | `/patterns/:id` | Structure: sequence, rows, colorways. `:id` may be an id or a name |
| GET | `/patterns/:id.svg` | The reference form — a `<pattern>` element, seamless at any angle |
| GET | `/patterns/:id/tile` | The tile's measurements and whether it closes |
| GET | `/patterns/:id/tile.svg` | One tile, for whatever is going to repeat it |
| GET | `/patterns/:id/tile.png` | The same tile, rasterised |
| GET | `/colorways` | Every colorway |
| GET | `/colorways/:id` | Rules, and the colours they resolve to |
| GET | `/colorways/:id.svg` | The reference form, dressed |
| GET | `/colorways/:id/tile.svg` | One tile, dressed |
| GET | `/colorways/:id/tile.png` | The same, rasterised |

`?period=` is how many user units a repeat is; `?scale=` is how many pixels a
unit is worth. They are the only two things a consumer needs that the pattern
does not already say.

The wire format is pinned longhand in `test/controllers/api/v1/contract_test.rb`.
Treat a failure there as a version bump rather than a fix — the way to change
v1 is to add v2.

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
