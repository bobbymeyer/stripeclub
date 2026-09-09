# Changelog

Semver. The API is versioned separately, under its own path, and is not
what this file numbers.

## Unreleased

### Added

- **A pattern carries tags.** The discovery mechanism Pandatone has had on a
  palette since its first commit, for the same reason: it is how something
  that knows nothing about patterns finds one. `Stripeclub.patterns(tag:)`
  narrows to a whole tag, `Stripeclub.tags` says which are in use, the API
  index takes `?tag=` and `?q=`, and `PatternSummary` carries `tags` — a wire
  format change, so the contract test moved with it.

  `Stripeclub::Taggable` is a copy of Pandatone's concern rather than an
  include of it, on purpose. `Pandatone::Dresser` is published surface
  because a consumer asks Pandatone for palettes; nothing about a pattern's
  tags asks Pandatone anything, and including its concern would make them
  Pandatone's business and stop this engine booting without it. If a third
  tool draws this, the home is a gem of its own.

## Unreleased

### Changed

- **Nothing here pins a version of ours.** The gemspec asked for
  `pandatone >= 0.4` and `its-swiss ~> 1.0`; both had to be edited by hand
  when the other side moved, and neither could ever have been violated —
  Pandatone is taken from its main branch, and we are its only consumer.
  Pandatone carries no version requirement now, and its-swiss carries a floor
  with no ceiling, so a new major arrives with everything else.

## Unreleased

### Changed

- **Pandatone comes from its default branch, not a tag.** A tag cannot exist
  until the change that needs it has merged, so every cross-repo move cost a
  branch pin, a merge, a tag and a re-pin. This Gemfile is only what the
  dummy runs on; a host resolves the gemspec, which still asks for a version.
  The trade is deliberate: the suite now runs against Pandatone's tip, so a
  break between the two shows up here rather than in a host.

## 0.4.0 — 2026-09-08

On its-swiss 1.0.

### Changed

- **Set on its-swiss 1.0.** The library registers its own controllers from
  a module its shell imports, so the dummy no longer registers them by hand.
  A form has no width of its own in 1.0; the imperfection form says
  `measure`, which is where it was.

## 0.3.0 — 2026-09-07

A day of use. On its-swiss 0.9 and Pandatone 0.3.

### Changed

- **The pattern page is four surfaces.** Compose, Finish, Dress and Export,
  named under the title; the drawing and what is true of it stay in the
  left column, and stay put, while the surface beside them is worked.
  Nothing is reached by scrolling past what was done yesterday: the slots'
  buttons are with the slots, the exports are a surface, and taking the
  pattern away is in the head with renaming it.

- **Each thing said once.** Four stripes at 25.00% is one fact: a repeat of
  equal stripes says so in a word and shows no width column. A slot bound
  to its rank is the rule, so a colorway lists only the slots bound to
  something else, or says every slot is by rank. The sentence over every
  table is behind one mark, opened when it is asked for.

- **One red per page.** The chosen filter is in the weight, in ink; the
  accent is the host's, for where you are on the site.

## 0.2.0 — 2026-09-07

### Changed

- **Dressed by Pandatone's dresser.** The catalogue, the client, the
  palette and colour readers, the luminance measure, the snapshot, the
  picker, the swatches and the drift sentences were this engine's copies
  of a pattern Badger had copied too; they are `Pandatone::Dresser` now,
  and this engine keeps what is a stripe pattern's own: the rule per
  value with its two repeat-varying kinds, and what a stripe resolves to.
  `Stripeclub.palette_source`, `pandatone_url` and `pandatone_token` are
  gone: with no `PANDATONE_URL` the dresser asks the Pandatone in the same
  process, and with one it asks that Pandatone over HTTP. The gemspec
  depends on `pandatone`.
- **Set on its-swiss 0.8.** Every page opens with the library's page head.
  The index is cards on the page's own fields — the tile in value over the
  name and its two numbers — narrowed by a search that filters as you type
  and by two registers, which way the stripes lean and the order. The grid
  is set once, in the layout, for every page. The library's pagination
  partial is used as shipped: the copy that dodged an ERB comment bug it
  fixed in 0.7 is gone, and so is the numeric-cell correction 0.7 made
  unnecessary.
- A colorway's rule reads "Palette colour n" where it read "Palette slot
  n", and a colorway is taken off rather than removed. "Take off" is the
  dresser's word, on every tool.

### Removed

- `--baseline`, which nothing measured on; the dead footer and row-form
  rules; the pagination partial; the palette picker partial.



Stripeclub becomes a Rails engine. Everything that knows what a stripe is
comes along; everything that does not stays behind.

- **A mountable engine, isolated.** Every constant under `Stripeclub`, every
  table under `stripeclub_`, every route under the mount. Its migrations run
  with the host's; its stylesheets arrive through its own layout, which
  renders the host's around them.
- **The door is the host's.** The single API token and its production rule
  are gone: the engine's controllers inherit from the host's
  (`Stripeclub.base_controller_class`, `Stripeclub.api_base_controller_class`),
  and whatever those refuse, the engine refuses.
- **The palettes are the host's to supply.** `Stripeclub.palette_source` is
  anything that answers with palettes in Pandatone's wire format. The HTTP
  client is the default; a host with Pandatone in the same process hands
  over a lambda that asks it directly.
- **A Ruby interface.** `Stripeclub.patterns`, `.pattern`, `.colorways`,
  `.colorway`, `.tile` and `.tile_svg` answer with the same plain hashes the
  API serializes, and the API's reads call them.
- **The API describes itself.** `GET /api/v1/openapi` serves an OpenAPI 3.1
  description, open to anyone, and a test holds it and the routes to each
  other.
- **A section, not a nav.** The engine offers Patterns to the host through
  `content_for :sections`; the masthead, the mark, the footer and the way
  out are the host's.
