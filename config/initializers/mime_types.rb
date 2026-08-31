# SVG is not one of the types Rails registers, and a tile is served as one.
Mime::Type.register "image/svg+xml", :svg
