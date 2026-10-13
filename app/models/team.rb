class Team < ApplicationRecord
  belongs_to :company
  has_many :users, dependent: :destroy
  has_many :lockers, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :company_id }
end
