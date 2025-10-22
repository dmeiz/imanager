class CreateSlackChannels < ActiveRecord::Migration[7.1]
  def change
    create_table :slack_channels do |t|
      t.string :channel_id
      t.string :channel_name

      t.timestamps
    end
  end
end
