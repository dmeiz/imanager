class SlackChannel < ApplicationRecord
  # Validations
  validates :channel_id, presence: true, uniqueness: true
  validates :channel_name, presence: true
end
