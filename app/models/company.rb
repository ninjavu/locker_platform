class Company < ApplicationRecord
  has_many :teams, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
