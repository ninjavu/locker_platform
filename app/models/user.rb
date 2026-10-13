class User < ApplicationRecord
  belongs_to :team, optional: true
  has_many :locker_events, dependent: :destroy

  enum :role, { employee: "employee", support: "support" }

  validates :name, presence: true
  validates :team, presence: true, if: :employee?
  validates :team, absence: true, if: :support?

  def company = team&.company

  # A single label for the user-switcher dropdown, e.g.
  # "Alice (Amazon / Night Shift)" or "Sam (eLocker Support)".
  def label
    support? ? "#{name} (eLocker Support)" : "#{name} (#{company.name} / #{team.name})"
  end
end
