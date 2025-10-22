class Project < ApplicationRecord
  # Associations
  has_and_belongs_to_many :people
  has_many :messages

  # Validations
  validates :name, presence: true
end
