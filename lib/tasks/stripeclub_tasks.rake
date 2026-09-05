namespace :stripeclub do
  desc "Plant the patterns from the handoff's reference images, so a host has something to look at. Idempotent."
  task seed: :environment do
    Stripeclub::Seeds.plant
  end
end
