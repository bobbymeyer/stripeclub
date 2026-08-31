ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # A sequence with exactly these widths, in order, one value per stripe.
    #
    # Most of what there is to say about a sequence is about its widths, and
    # the pattern around them is scaffolding — written out in every test it
    # would bury the only number the test is about. The widths are written
    # past validation on purpose: these tests ask whether the sequence refuses
    # them, which it cannot do if the write already did.
    def sequence_of(*widths)
      pattern = Pattern.create!(name: "Widths", slot_count: widths.size)

      pattern.sequence.stripes.each_with_index do |stripe, index|
        stripe.update_column(:width, widths[index])
      end

      pattern.sequence.tap { |sequence| sequence.stripes.reload }
    end
  end
end
