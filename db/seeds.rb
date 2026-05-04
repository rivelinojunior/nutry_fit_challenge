# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

return unless Rails.env.development?

seed_user = User.find_or_initialize_by(email: "admin@nutry.fit")
seed_user.name = "Nutry.fit Admin"
seed_user.password = "password123" if seed_user.new_record?
seed_user.save!

days_until_monday = (1 - Date.current.wday) % 7
start_date = Date.current + (days_until_monday.zero? ? 7.days : days_until_monday.days)
end_date = start_date + 6.days

challenge = Challenge.find_or_initialize_by(user: seed_user, name: "Desafio Nutry.fit")
challenge.assign_attributes(
  description: "Desafio semanal com tarefas de alimentação, hidratação, treino e preparação.",
  start_date:,
  end_date:,
  timezone: "America/Sao_Paulo",
  status: "draft"
)
challenge.save!

daily_tasks = [
  "Café da manhã",
  "Almoço",
  "Lanche da tarde",
  "Jantar",
  "Beber no mínimo 2L de água"
]

weekday_tasks = {
  "Treino musculação" => [ 1, 2, 3, 5 ],
  "Cardio" => [ 4, 6 ],
  "Pré-preparo" => [ 0 ]
}

specific_day_tasks = [
  "Preparação do ambiente",
  "Fotos do corpo",
  "Pesar"
]

task_specs = []

(start_date..end_date).each do |scheduled_on|
  daily_tasks.each do |name|
    task_specs << { name:, scheduled_on: }
  end

  weekday_tasks.each do |name, weekdays|
    task_specs << { name:, scheduled_on: } if weekdays.include?(scheduled_on.wday)
  end
end

specific_day_tasks.each do |name|
  task_specs << { name:, scheduled_on: start_date }
end

task_specs.each do |task_attributes|
  task = ChallengeTask.find_or_initialize_by(
    challenge:,
    name: task_attributes[:name],
    scheduled_on: task_attributes[:scheduled_on]
  )
  task.assign_attributes(points: 10)
  task.save!
end
