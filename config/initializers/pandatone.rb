# Where Pandatone is and what to show it at the door.
#
# The environment first, so a deployment sets it without a re-encrypt, and
# credentials behind it, so a developer's token is not lying around in a
# shell profile. Neither is required to boot: Stripeclub composes patterns
# without a palette in sight, and only a colorway needs Pandatone at all.
Rails.application.config.x.pandatone.tap do |pandatone|
  pandatone.url = ENV["PANDATONE_URL"].presence ||
    Rails.application.credentials.dig(:pandatone, :url)

  pandatone.token = ENV["PANDATONE_TOKEN"].presence ||
    Rails.application.credentials.dig(:pandatone, :token)
end
