class ApplicationController < ActionController::Base
  # The library's shell is rendered by app/views/layouts/application.html.erb
  # rather than named here, which is what the installer wrote. The shell takes
  # its mark, its nav and its head through `content_for`, and a layout named
  # on the controller leaves nowhere to fill those in once for the whole
  # application — every view would have to remember, including the one that
  # links the application's own stylesheets.
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
