class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.string :slack_message_id
      t.string :channel_id
      t.bigint :user_id
      t.text :content
      t.datetime :timestamp
      t.string :thread_ts
      t.bigint :project_id

      t.timestamps
    end
  end
end
