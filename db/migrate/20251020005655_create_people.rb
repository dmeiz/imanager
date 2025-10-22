class CreatePeople < ActiveRecord::Migration[7.1]
  def change
    create_table :people do |t|
      t.string :name
      t.string :slack_user_id

      t.timestamps
    end
  end
end
