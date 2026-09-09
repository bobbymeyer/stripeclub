# Tags on a pattern, for the same reason Pandatone puts them on a palette:
# they are the discovery mechanism, and the way something outside Stripeclub
# finds a pattern without knowing anything about patterns.
class AddTagsToStripeclubPatterns < ActiveRecord::Migration[8.1]
  def change
    add_column :stripeclub_patterns, :tags, :json, null: false, default: []
  end
end
