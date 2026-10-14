# Wipe-and-recreate seeds: this is a demo app, so deterministic data beats
# idempotency gymnastics. Re-run with `bin/rails db:seed` (or db:reset).
LockerEvent.delete_all
Locker.delete_all
User.delete_all
Team.delete_all
Company.delete_all

support = User.create!(name: "Sam Porter", role: "support")

companies = {
  "Amazon" => {
    "Night Shift" => { users: [ "Alice Nguyen", "Andrii Bondar" ], lockers: %w[AMZ-N-01 AMZ-N-02 AMZ-N-03] },
    "Day Shift"   => { users: [ "Aaron Blake" ],                   lockers: %w[AMZ-D-01 AMZ-D-02] }
  },
  "DPD" => {
    "North Crew" => { users: [ "Daria Koval" ],  lockers: %w[DPD-N-01 DPD-N-02] },
    "South Crew" => { users: [ "Diego Silva" ],  lockers: %w[DPD-S-01 DPD-S-02 DPD-S-03] }
  }
}

companies.each do |company_name, teams|
  company = Company.create!(name: company_name)
  teams.each do |team_name, data|
    team = company.teams.create!(name: team_name)
    data[:users].each { |name| team.users.create!(name:, role: "employee") }
    data[:lockers].each { |name| team.lockers.create!(name:) }
  end
end

# A bit of history so the locker pages and the action log aren't empty:
# every employee opens and closes the first locker of their team, then
# support opens one locker per company and leaves it open.
User.employee.find_each do |user|
  locker = user.team.lockers.first
  Lockers::Operate.call(locker:, user:, event: :open)
  Lockers::Operate.call(locker:, user:, event: :close)
end

[ "AMZ-N-02", "DPD-S-02" ].each do |name|
  Lockers::Operate.call(locker: Locker.find_by!(name:), user: support, event: :open)
end

puts "Seeded: #{Company.count} companies, #{Team.count} teams, #{User.count} users, " \
     "#{Locker.count} lockers, #{LockerEvent.count} events"
