FactoryBot.define do
  factory :participant do
    association :user
    association :challenge
    joined_at { Time.current }
  end
end
