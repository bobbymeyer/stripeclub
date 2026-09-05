# Changelog

Semver. The API is versioned separately, under its own path, and is not
what this file numbers.

## 0.1.0 — 2026-09-05

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
