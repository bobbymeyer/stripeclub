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
