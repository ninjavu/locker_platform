class Locker < ApplicationRecord
  include AASM

  belongs_to :team
  has_one :company, through: :team
  has_many :locker_events, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :team_id }

  # Pure state machine: no callbacks, no business rules. Transitioning a
  # locker on behalf of a user (with its audit trail and concurrency
  # handling) is Lockers::Operate's job — always go through the service.
  # Optimistic locking (lock_version) makes a stale concurrent transition
  # raise ActiveRecord::StaleObjectError instead of double-applying.
  aasm column: :state, timestamps: false do
    state :closed, initial: true
    state :open

    event :open do
      transitions from: :closed, to: :open
    end

    event :close do
      transitions from: :open, to: :closed
    end
  end
end
