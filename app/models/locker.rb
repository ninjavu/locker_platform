class Locker < ApplicationRecord
  include AASM

  belongs_to :team
  has_one :company, through: :team
  has_many :locker_events, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  # The single tenancy boundary of the app: every controller resolves lockers
  # through this scope, so a record outside the user's reach is a plain 404.
  scope :accessible_by, ->(user) { user.support? ? all : where(team_id: user.team_id) }

  aasm column: :state, timestamps: false do
    state :closed, initial: true
    state :open

    # Events take the acting user, e.g. `locker.open!(current_user)`, and the
    # audit record is written inside the same transaction as the state change.
    event :open do
      transitions from: :closed, to: :open
      after { |user| log_action("open", user) }
    end

    event :close do
      transitions from: :open, to: :closed
      after { |user| log_action("close", user) }
    end
  end

  private

  def log_action(action, user)
    locker_events.create!(action:, user:)
  end
end
