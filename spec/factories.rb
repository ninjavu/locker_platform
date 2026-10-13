FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }
  end

  factory :team do
    company
    sequence(:name) { |n| "Team #{n}" }
  end

  factory :user do
    sequence(:name) { |n| "User #{n}" }
    role { "employee" }
    team

    trait :support do
      role { "support" }
      team { nil }
    end
  end

  factory :locker do
    sequence(:name) { |n| "LCK-#{n.to_s.rjust(3, '0')}" }
    team

    trait :open do
      state { "open" }
    end
  end

  factory :locker_event do
    locker
    user { association :user, team: locker.team }
    action { "open" }
  end
end
