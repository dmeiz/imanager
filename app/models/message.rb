class Message < ApplicationRecord
  # Associations
  belongs_to :person, foreign_key: :user_id
  belongs_to :project, optional: true

  # Validations
  validates :slack_message_id, presence: true, uniqueness: true
  validates :channel_id, presence: true
  validates :content, presence: true
  validates :timestamp, presence: true
end
