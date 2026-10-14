module Lockers
  # The single write-side business operation of the app: transition a locker
  # and record who did it, atomically. Expected business outcomes (the locker
  # is already in the target state; somebody else just operated it) come back
  # as a failure Result with a user-facing message — only programmer errors
  # and unexpected persistence failures raise.
  class Operate < ApplicationService
    EVENTS = %i[open close].freeze

    Result = Data.define(:ok, :message) do
      alias_method :success?, :ok
    end

    def initialize(locker:, user:, event:)
      raise ArgumentError, "unknown event #{event.inspect}" unless EVENTS.include?(event)

      @locker = locker
      @user = user
      @event = event
    end

    def call
      Locker.transaction do
        @locker.public_send(:"#{@event}!")
        @locker.locker_events.create!(user: @user, action: @event.to_s)
      end
      Result.new(ok: true, message: "Locker #{@locker.name} is now #{@locker.state}.")
    rescue AASM::InvalidTransition
      Result.new(ok: false, message: "Locker #{@locker.name} is already #{@locker.state} — nothing to do.")
    rescue ActiveRecord::StaleObjectError
      Result.new(ok: false,
                 message: "Locker #{@locker.name} was just operated by someone else — check its current state.")
    end
  end
end
