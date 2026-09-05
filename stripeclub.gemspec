require_relative "lib/stripeclub/version"

Gem::Specification.new do |spec|
  spec.name        = "stripeclub"
  spec.version     = Stripeclub::VERSION
  spec.authors     = [ "Bobby Meyer" ]
  spec.email       = [ "bobby@bobbymeyer.com" ]
  spec.homepage    = "https://github.com/bobbymeyer/stripeclub"
  spec.summary     = "A stripe pattern generator, as a Rails engine."
  spec.description = <<~TEXT.strip
    Patterns composed in value and dressed afterwards in a palette, with a
    read-only JSON API and a Ruby interface, so a later tool can ask for a
    pattern the way this one asks Pandatone for a palette.
  TEXT
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  # Not published to RubyGems: a host takes the gem from a tag. If it ever
  # is, MFA should be required for the push.
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md", "CHANGELOG.md"].select { |path| File.file?(path) }
  end

  spec.add_dependency "rails", ">= 8.0", "< 9"
  # The typographic style every screen is set in, declared here rather than
  # taken from the host on faith.
  spec.add_dependency "its-swiss", "~> 0.7"
  spec.add_dependency "propshaft", ">= 1.0", "< 3"
  spec.add_dependency "importmap-rails", ">= 2.0", "< 4"
  spec.add_dependency "turbo-rails", ">= 2.0", "< 3"
  spec.add_dependency "stimulus-rails", ">= 1.3", "< 2"
  # The tile, rasterised.
  spec.add_dependency "chunky_png", "~> 1.4"
end
