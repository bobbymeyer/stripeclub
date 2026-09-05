# Stripeclub

A stripe pattern generator, as a Rails engine. The second of a set of small
design tools: it consumes palettes from
[Pandatone](https://github.com/bobbymeyer/pandatone) the way a later tool
will consume it.

It was a standalone application until 0.1.0. Now it is one tool among
several, mounted in a host that owns the server, the database, the account
and the shell — see [design-chassis](https://github.com/bobbymeyer/design-chassis)
for the one it was made for.

## Mounting it

```ruby
# Gemfile — not on RubyGems; taken from the tag
gem "stripeclub", github: "bobbymeyer/stripeclub", tag: "v0.1.0"

# config/routes.rb
mount Stripeclub::Engine, at: "/stripeclub"
```

Then `bin/rails db:migrate`: the engine's migrations run with the host's.
Its tables are prefixed `stripeclub_`. `bin/rails stripeclub:seed` plants the
patterns from the handoff's reference images.

### What the host provides

**The door.** Every screen inherits from the host's `ApplicationController`
and every API endpoint from the host's `ApiController`; those decide who gets
in. Point them elsewhere before the engine loads with
`Stripeclub.base_controller_class` and `Stripeclub.api_base_controller_class`.

**The shell and the theme.** The engine's layout fills the slots its-swiss
leaves and renders the host's `layouts/application` around them, handing it
Patterns through `content_for :sections`. The accent, the typeface and the
value scale are the host's; the engine ships its grid and its components.

**The palettes.** Stripeclub dresses a pattern in a palette it did not make,
and where palettes come from is the host's to say:

```ruby
# config/initializers/stripeclub.rb
Stripeclub.palette_source = -> { Pandatone.palettes.map { |p| Pandatone.palette(p[:id]) } }
```

`palette_source` is anything that answers `call` with an array of palettes in
Pandatone's wire format — `id`, `name`, `tags`, and `colors` each with `id`,
`name`, `hex` and `rgb`. Unset, it fetches them over HTTP from the Pandatone
at `PANDATONE_URL` with `PANDATONE_TOKEN`, which is what a Stripeclub running
on its own wants. A host with Pandatone in the same process hands over a
lambda that asks it directly, and Stripeclub never learns the difference:
it knows Pandatone by its wire format and by nothing else.

The picker fetches the catalogue once, holds it for five minutes, and filters
it here — palettes with fewer colours than the pattern has slots are demoted
rather than hidden. Choosing takes a snapshot. What Pandatone does to that
palette afterwards is drift — reported when you ask for it and never applied.
Without a source that answers, every page still works except the picker,
which says so.

## Calling it from Ruby

The same questions the API answers, as methods, with plain data back — the
hashes the API serializes, never a record of the engine's.

```ruby
Stripeclub.patterns                         # => [ { id:, name:, slot_count:, angle: }, ... ]
Stripeclub.pattern("Awning")                # => { ..., sequence:, rows:, colorways: }
Stripeclub.colorways
Stripeclub.colorway(12)                     # => { ..., rules:, colors: }
Stripeclub.tile("Awning", colorway: 12)     # => { width:, height:, tiles:, note: }
Stripeclub.tile_svg("Awning", period: 60)   # => "<svg ...>"
```

The API's read endpoints call these same methods, so the two cannot drift.

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
| `Imperfection` | Round two: wobbly edges, seeded width jitter, tiling texture — none of which touch the composition |

All ten steps of the build order are done.

Round two is post-effects, not geometry: the widths in the sequence stay what
you typed and the angle stays what you set, and the wobble, the jitter and the
texture are applied when the pattern is drawn. Turn an imperfection off and
the clean composition is still exactly there. The one that looks like an
exception — width variance — computes its widths from a seed at draw time and
renormalises them, so the sequence still sums to one.

A raster carries the geometry and not the filters. A displacement map and a
noise multiply are things a renderer does to a picture, and a PNG arrives with
no renderer attached — so the tile says so, in its `<desc>` and in the API.

## API

Everything is under `/api/v1` of the mount path — `/stripeclub/api/v1`
where the engine is mounted at `/stripeclub`. Read-only. Collections are
bare arrays, no envelope. `404` with `{"error": "Not found"}`, `401` with
`{"error": "Unauthorized"}`, `422` with a reason when a colorway cannot dress
its pattern.

```sh
curl -H "Authorization: Bearer $TOKEN" \
     https://studio.example.com/stripeclub/api/v1/patterns/Awning/tile.svg
```

The token is the host's: the engine's API controllers inherit from the
host's, and whatever that one refuses, the engine refuses. The API describes
itself at `GET /api/v1/openapi`, which is the one endpoint not behind the
token; `test/controllers/api/v1/openapi_test.rb` holds the description and
the routes to each other.

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

## Tests

Tests come first, and a guard is kept only if breaking what it guards makes it
fail. They run against the dummy host under `test/dummy`, which opens its
screens to a cookie and its API to one token — the least a host can be.

```sh
bin/rails test
```

The suite reads structure rather than pixels. There are golden SVG documents
in `test/fixtures/files/svg`, compared byte for byte and regenerated with
`GOLDEN=overwrite`; read the diff before accepting one. There are no pixel
tests. Nothing in the suite reaches the network: the HTTP palette source is
stubbed at the wire with WebMock.

## Styling

[its-swiss](https://github.com/bobbymeyer/its-swiss), pinned `~> 0.7` in the
gemspec. What Stripeclub found in it as the second consumer is in
[ITS-SWISS-CANDIDATES.md](ITS-SWISS-CANDIDATES.md).
