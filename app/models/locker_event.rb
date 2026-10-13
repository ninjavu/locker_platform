class LockerEvent < ApplicationRecord
  ACTIONS = %w[open close].freeze

  belongs_to :locker
  belongs_to :user

  validates :action, inclusion: { in: ACTIONS }

  scope :accessible_by, ->(user) { joins(:locker).merge(Locker.accessible_by(user)) }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
