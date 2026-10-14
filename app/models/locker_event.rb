class LockerEvent < ApplicationRecord
  ACTIONS = %w[open close].freeze

  belongs_to :locker
  belongs_to :user

  validates :action, inclusion: { in: ACTIONS }

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
