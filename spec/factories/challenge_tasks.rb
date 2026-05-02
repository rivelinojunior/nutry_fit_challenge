FactoryBot.define do
  factory :challenge_task do
    association :challenge
    name { "Beber água" }
    points { 10 }
    scheduled_on { Date.today }
  end
end
