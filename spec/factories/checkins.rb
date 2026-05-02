FactoryBot.define do
  factory :checkin do
    association :participant
    association :challenge_task
    checked_at { Time.current }
  end
end
