class Person < ApplicationRecord
  # Associations
  has_and_belongs_to_many :projects
  has_many :messages, foreign_key: :user_id

  # Validations
  validates :name, presence: true
  validates :slack_user_id, presence: true, uniqueness: true
end
