class AddLastFetchedAtToSlackChannels < ActiveRecord::Migration[7.1]
  def change
    add_column :slack_channels, :last_fetched_at, :datetime
  end
end
