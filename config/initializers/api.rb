# The credential a consuming tool carries.
#
# Stripeclub has no accounts — it is one person's tool — so this is a single
# token and not a user. Unset, the API is open, which is what a tool running
# on someone's own machine wants and how the camo project will reach it.
#
# Unset *in production* it is closed instead, and says so. A design tool put
# on the internet with its API open is not a decision anyone makes on purpose,
# and failing shut with a legible reason is better than either guessing.
Rails.application.config.x.api.token = ENV["STRIPECLUB_API_TOKEN"].presence ||
  Rails.application.credentials.dig(:api, :token)

# Whether an unset token closes the API or opens it.
#
# A setting rather than a `Rails.env.production?` in the controller. Somewhere
# to say "require one in staging too" is worth having on its own, and asking
# the environment from inside a request means the only way to test the shut
# case is to move the whole environment under the test — which reaches a lot
# further than intended: cable.yml resolves per environment, and production's
# wants a gem this application does not bundle.
Rails.application.config.x.api.required = Rails.env.production?
