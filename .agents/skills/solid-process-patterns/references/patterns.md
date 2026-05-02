# Solid::Process — Pattern Reference

## Pattern 1: Simple CRUD Process

Use for single-model operations with guard clauses and optional side effects.

```ruby
# app/processes/members/create_member_process.rb
class Members::CreateMemberProcess < Solid::Process
  input do
    attribute :user_id, :string
    attribute :name, :string
    attribute :age, :integer
    attribute :weight, :decimal
    attribute :height, :decimal
    attribute :goal, :string

    validates :user_id, :name, :age, :weight, :height, :goal, presence: true
    validates :age, numericality: { greater_than: 0 }
  end

  deps do
    attribute :user_model, default: User
  end

  def call(attributes)
    user = deps.user_model.find_by(id: attributes[:user_id])
    return Failure(:user_not_found) unless user

    member = user.members.build(attributes.except(:user_id))
    return Failure(:member_invalid, errors: member.errors.full_messages) unless member.save

    Success(:member_created, member:)
  end
end
```

**Controller:**

```ruby
case Members::CreateMemberProcess.call(user_id: current_user.id, **member_params)
in Solid::Success[type: :member_created, member:]
  redirect_to member, notice: t(".success")
in Solid::Failure[type: :member_invalid, errors:]
  flash.now[:alert] = errors.to_sentence
  render :new, status: :unprocessable_entity
in Solid::Failure[type: :invalid_input, input:]
  @errors = input.errors
  render :new, status: :unprocessable_entity
end
```

## Pattern 2: Process with Transaction

Use when multiple models must be created or updated atomically.

```ruby
# app/processes/plans/create_plan_process.rb
class Plans::CreatePlanProcess < Solid::Process
  input do
    attribute :user_id, :string
    attribute :name, :string
    attribute :members, default: []

    validates :user_id, :name, presence: true
    validates :members, length: { minimum: 1 }
  end

  deps do
    attribute :user_model, default: User
  end

  def call(attributes)
    user = deps.user_model.find_by(id: attributes[:user_id])
    return Failure(:user_not_found) unless user

    ActiveRecord::Base.transaction do
      plan = user.plans.create!(name: attributes[:name], status: :draft)
      attributes[:members].each { |m| plan.members.create!(m) }
      Success(:plan_created, plan:)
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure(:validation_failed, errors: e.record.errors.full_messages)
  end
end
```

## Pattern 3: Integration Process (External Gateway)

Use for external API calls. Map external errors to domain failure types.

```ruby
# app/processes/meals/generate_meal_process.rb
class Meals::GenerateMealProcess < Solid::Process
  input do
    attribute :meal_id, :string
    attribute :user_id, :string
    attribute :preferences, :string, default: ""

    validates :meal_id, :user_id, presence: true
  end

  deps do
    attribute :meal_model, default: Meal
    attribute :ai_gateway, default: AiMealGateway
  end

  def call(attributes)
    meal = deps.meal_model.find_by(id: attributes[:meal_id], user_id: attributes[:user_id])
    return Failure(:meal_not_found) unless meal

    response = deps.ai_gateway.generate(meal:, preferences: attributes[:preferences])
    return Failure(:gateway_error, errors: [response.error]) unless response.success?

    meal.update!(portions: response.portions, status: :ready)
    Success(:meal_generated, meal:)
  rescue ActiveRecord::RecordInvalid => e
    Failure(:validation_failed, errors: e.record.errors.full_messages)
  end
end
```

## Pattern 4: Orchestrator Process

Use to coordinate multiple processes in sequence. Propagate the first failure.

```ruby
# app/processes/onboarding/complete_onboarding_process.rb
class Onboarding::CompleteOnboardingProcess < Solid::Process
  input do
    attribute :user_id, :string
    attribute :plan_params, default: {}
    attribute :member_ids, default: []

    validates :user_id, presence: true
  end

  deps do
    attribute :create_plan, default: Plans::CreatePlanProcess
    attribute :calculate_kpi, default: Kpi::CalculateKpiProcess
    attribute :user_model, default: User
  end

  def call(attributes)
    plan = nil

    case deps.create_plan.call(user_id: attributes[:user_id], **attributes[:plan_params])
    in Solid::Failure => result then return result
    in Solid::Success[plan: p] then plan = p
    end

    attributes[:member_ids].each do |member_id|
      case deps.calculate_kpi.call(user_id: attributes[:user_id], member_id:)
      in Solid::Failure => result then return result
      in Solid::Success then # continue
      end
    end

    user = deps.user_model.find(attributes[:user_id])
    user.update!(onboarding_completed_at: Time.current)

    Success(:onboarding_completed, user:, plan:)
  end
end
```

## Background Job Delegation

Jobs never contain business logic. They delegate immediately to a process.

```ruby
# app/jobs/calculate_kpi_job.rb
class CalculateKpiJob < ApplicationJob
  queue_as :default

  def perform(member_id:, user_id:)
    Kpi::CalculateKpiProcess.call(member_id:, user_id:)
  end
end
```

## Layer Communication Rules

```
Controller → Process (via case/in pattern matching)
Process    → Model, Query, Job, Mailer, Gateway
Job        → Process (delegate immediately, no logic in job)
```
