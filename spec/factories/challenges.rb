FactoryBot.define do
  factory :challenge do
    association :user
    name { "Desafio Nutry" }
    description { "Descrição" }
    start_date { Date.current + 1.day }
    end_date { Date.current + 7.days }
    timezone { "America/Sao_Paulo" }
    status { "draft" }
  end
end
