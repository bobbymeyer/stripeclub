# its-swiss candidates

Stripeclub is the second consumer its-swiss was waiting for. Its `0.1.0`
boundary was drawn from one application, and the changelog says so — `.table`
and `.pagination` shipped with **no consumer at all**, and `.footer` with a
slot nothing filled.

This file is what the second consumer found. Nothing here has been changed in
the gem: a pattern enters it after it appears in two applications, and one of
those is still Pandatone's to confirm.

Each entry says what happened, where Stripeclub works around it, and what the
gem might do instead.

---

## 1. `.table .numeric` zeroes the end padding of every numeric cell

**A bug, not a boundary question.** components.css:

```css
.table .numeric { text-align: right; padding-inline: var(--space-3) 0; }
```

The shorthand sets `padding-inline-end: 0` on *every* numeric cell. That is
right for a figure in the last column — and the library already has a
`:last-child` rule that handles exactly that — but wrong anywhere else,
because the next column's text then begins where the number ends.

Both of Stripeclub's tables have a numeric column that is not last. The index
rendered its headings as `SlotsAngle`; the repeat table rendered `#Draws` and
`1Ground`.

Worked around in `app/assets/stylesheets/stripeclub.css`:

```css
.table .numeric:not(:last-child) { padding-inline-end: var(--space-3); }
```

Suggested fix in the gem — set only the start padding and let the existing
`:last-child` rule do its job:

```css
.table .numeric { text-align: right; padding-inline-start: var(--space-3); }
```

This is the first thing the first consumer of `.table` hit. The second thing
was that `.pagination`, the other component with no consumer, does not render
at all — see below.

---

## 2. `_pagination.html.erb` emits its own documentation as page content

**A bug, and a visible one.** The partial opens with a documentation comment
that contains a worked example written in ERB. The closing delimiter of that
example ends the comment early, so everything after it — two lines of prose
and a stray delimiter — is emitted as page content, above the numbers.

It reads, on the page, to a user:

> Long runs are elided around the current page, because a hundred numbers is
> not a control. %&gt;

This has been happening on the specimen page as well, which is the gem's own
documentation and its regression fixture. `test/integration/specimen_test.rb`
checks that a `data-specimen="pagination"` section is present, and
`components_test.rb` checks a selector; neither looks for text that should not
be there. Every assertion in the suite is about markup that is present rather
than output that should be absent, so nothing saw it.

Suggested fix in the gem: move the worked example out of the comment — into
the README, or into a comment with the delimiters broken up — and add one
assertion to the specimen test that the rendered page contains no template
delimiters. That assertion is four lines and would have caught this before it
shipped. Stripeclub's version is in `test/integration/layout_test.rb`, and it
caught the same mistake in the file written to work around it, on its first
run.

Worked around by `app/views/shared/_pagination.html.erb` — the library's
markup, copied verbatim, with only the comment changed. It is a file that
exists to be deleted.

---

## 3. The shell links the library's stylesheets and not the application's

`its_swiss_stylesheet_tags` writes the six links the gem ships. `theme.css` —
which the installer writes, and which holds the accent, the typeface and the
grid — is linked by the application or not at all.

Nothing says so. The install generator creates the file and prints a note
about what to put in it, but an application that follows the README exactly
gets an unstyled accent and no grid, with no error anywhere.

Stripeclub links it through the `:head` slot, which works and costs nothing
because the gem's CSS is layered and the app's is not, so order is irrelevant.

Candidates, in order of how much they presume:

- The installer could write the nested layout that links it (see 3 below).
- The README's shell section could name `:head` as the place the application's
  own stylesheets go.
- `its_swiss_stylesheet_tags` could take the application's stylesheets as
  arguments and write all of them.

---

## 4. `layout "its_swiss/shell"` leaves nowhere to fill the shell's slots

The installer injects `layout "its_swiss/shell"` into `ApplicationController`.
That renders the shell, but the shell is built to be filled through
`content_for` — `:mark`, `:nav`, `:head`, `:footer` — and a layout named on a
controller gives an application no single place to do it. Every view would
have to write the same masthead.

The Rails idiom is a nested layout: `app/views/layouts/application.html.erb`
fills the slots and ends with `render template: "layouts/its_swiss/shell"`.
That works, and Stripeclub does it, but the installer points the other way and
an application following it will write its nav five times before noticing.

Candidate: have `its_swiss:install` generate the nested layout — with the
slots stubbed and commented — rather than injecting a `layout` line. It is the
same amount of generated code and it puts the application on the path that
scales.

---

## 5. A pattern preview is not a paragraph — but that is Stripeclub's business

`.table th, .table td { vertical-align: baseline; }` is right for a table of
text and wrong for a row carrying a drawing six lines tall: the name aligns to
the drawing's baseline and sits at the foot of the row.

**Not a candidate.** A library cannot know a cell holds a picture, and the
override is one line in the application. Recorded here so it is not mistaken
for a gap later.

---

## 6. `.field` is a form's shape, and a table of controls is not a form

The row editor is a table: four small controls per row, five columns, one
save. Two things in the library are built for the other shape.

`ItsSwiss::FormBuilder` writes a label above its control, down the width of a
form. In a table the column heading is already the label, and a second copy in
every cell is read out on every cell.

`.field` is `display: flex; flex-direction: column; width: 100%`. Two related
controls in one cell — a scale's numerator and denominator — stack, with the
solidus between them on its own line.

Both are right for a form and neither is wrong here so much as aimed
elsewhere. Stripeclub keeps the `.field` wrapper so the controls are styled
like every other control in the application, moves the label off screen with
the library's own `.visually-hidden`, and lets the cell do the arranging.

`.form--inline` and `.field--inline` are close but not this: both arrange a
run of fields inside a form, and this is one control inside a cell.

Candidate, weakly: a modifier for a control whose label is elsewhere — the
`.field` styling with the column flex and the full width dropped. It is three
lines, and it is the second application to want it only if Pandatone has a
table of controls somewhere. Recorded rather than assumed.

---

## 7. What worked as shipped

Worth as much as the list above, since the point was to test the boundary:

- **`.pagination`'s CSS and `its_swiss_page_numbers`** — both correct. The
  elision, the gap, the `aria-current`, the styling: all of it works, and the
  copied partial is a copy precisely because there was nothing wrong with the
  markup. Only the comment above it.
- **The cascade layer boundary.** Every CSS correction in this file is an
  unlayered rule in the application's own stylesheet, and not one of them
  needed a raised specificity or an `!important`. This is the part of the
  design that most needed a second consumer, and it held.

  Note what it did not cover: three of the five findings here are a broken ERB
  comment, an installer pointing at the wrong layout shape, and a form builder
  aimed at a shape this application does not always have. The cascade
  layer is the boundary for *style*, and it works — but a gem that ships
  views, a generator and a form builder has three more surfaces than CSS, and
  those have no equivalent mechanism protecting them.
- **`.pairs`, `.button`, `.button--quiet`, `.button--danger`, `.empty`,
  `.run`, `.stack`, `.measure`, `.numeric`, `.visually-hidden`, the masthead,
  the nav's `aria-current`, the flash, the errors partial, and the form
  builder on every form that is shaped like a form** — all used as
  documented.
- **The grid primitives.** Stripeclub declared six columns and two spans and
  got the page it wanted. The gem shipping no grid is the right call.
