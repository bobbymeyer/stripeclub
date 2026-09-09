# Tags are how a pattern is found by something that knows nothing about
# patterns: a project asks every tool for what carries a tag, and gets these
# back beside Pandatone's palettes. That makes the handling load-bearing, so
# it is normalized in one place and queried in one place.
#
# This is the second drawing of the pattern — Pandatone's `Taggable` is the
# first — and it is a copy on purpose. Tagging is not Pandatone's to own the
# way dressing is: `Pandatone::Dresser` is published surface because a
# consumer asks Pandatone for palettes, but nothing here asks Pandatone
# anything. Including its concern would make a pattern's tags Pandatone's
# business and stop Stripeclub booting without it. If a third tool draws this,
# the home is a small gem of its own, not the host and not the style library.
module Stripeclub
  module Taggable
    extend ActiveSupport::Concern

    included do
      before_validation :normalize_tags
      validate :tags_must_be_a_list_of_strings

      # Matches whole tags only. Tags are stored downcased, so the needle is
      # too: a pattern tagged "brands" must not answer a project that asked
      # for "brand".
      scope :tagged, ->(tag) {
        tag = tag.to_s.strip.downcase
        next none if tag.blank?

        where("EXISTS (SELECT 1 FROM json_each(#{table_name}.tags) WHERE json_each.value = ?)", tag)
      }
    end

    class_methods do
      # Every tag actually in use, for building a filter bar. Cheap enough at
      # this scale to ask the database each time.
      def all_tags
        connection.select_values(
          "SELECT DISTINCT json_each.value FROM #{table_name}, json_each(#{table_name}.tags) ORDER BY 1"
        )
      end

      # Accepts either a list or a comma-separated string, so the same writer
      # serves a JSON body and a text field in a form.
      def normalize_tags(value)
        list = case value
        when nil    then []
        when String then value.split(",")
        else             value
        end

        list.map { |tag| tag.to_s.strip.downcase }.reject(&:blank?).uniq
      end
    end

    def tag_list
      tags.join(", ")
    end

    def tag_list=(value)
      self.tags = value
    end

    private
      def normalize_tags
        self.tags = self.class.normalize_tags(tags) if tags.nil? || tags.is_a?(Array) || tags.is_a?(String)
      end

      def tags_must_be_a_list_of_strings
        return if tags.is_a?(Array) && tags.all?(String)

        errors.add(:tags, "must be an array of strings")
      end
  end
end
