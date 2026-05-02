---
name: solid-process-patterns
description: >-
  Guides Solid::Process class design for Rails business logic. Use when deciding
  how to structure a process, choosing result type names, setting up input validation,
  integrating results in controllers with pattern matching, or when user mentions
  solid process, process classes, or business logic orchestration. WHEN NOT:
  Implementing a specific process (use @solid-process-agent), writing tests
  (use @rspec-agent), or making architecture decisions (use rails-architecture skill).
model: sonnet
compatibility: Ruby 3.3+, Rails 7.0+
---

# Solid::Process Patterns

## Process Blueprint

Every process follows the same structure: validated input, injected dependencies, linear call method, domain result types.

```ruby
class Domain::VerbNounProcess < Solid::Process
  input do
    attribute :user_id, :string
    attribute :resource_id, :string

    validates :user_id, :resource_id, presence: true
  end

  deps do
    attribute :resource_model, default: Resource
    attribute :gateway, default: DomainGateway
  end

  def call(attributes)
    resource = deps.resource_model.find_by(id: attributes[:resource_id], user_id: attributes[:user_id])
    return Failure(:resource_not_found) unless resource

    response = deps.gateway.call(resource:)
    return Failure(:gateway_error, errors: Array(response.errors)) unless response.success?

    Success(:resource_processed, resource:)
  end
end
```

## Naming Convention

**Class:** `Domain::VerbNounProcess` — verb describes the action, noun describes the target.
**File:** `app/processes/domain/verb_noun_process.rb`

| Example | Class | File |
|---------|-------|------|
| Calculate KPIs for a member | `Kpi::CalculateKpiProcess` | `app/processes/kpi/calculate_kpi_process.rb` |
| Generate a meal | `Meals::GenerateMealProcess` | `app/processes/meals/generate_meal_process.rb` |
| Create a plan | `Plans::CreatePlanProcess` | `app/processes/plans/create_plan_process.rb` |
| Complete onboarding | `Onboarding::CompleteOnboardingProcess` | `app/processes/onboarding/complete_onboarding_process.rb` |

## Input Block

Define typed attributes and validations. When input is invalid, `Failure(:invalid_input)` is returned automatically — the `call` method never runs.

```ruby
input do
  attribute :email, :string
  attribute :age, :integer
  attribute :goal, :string

  # Normalization runs on assignment (Rails 8.1+)
  normalizes :email, with: -> { _1&.strip&.downcase }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age, numericality: { greater_than: 0, less_than: 150 }
  validates :goal, presence: true, inclusion: { in: %w[lose_weight gain_muscle maintain] }
end
```

## Result Type Naming

Keep result types stable — the same symbol must appear in the process, controller, and spec.

**Success types:**
- Generic: `:created`, `:updated`, `:deleted`, `:found`
- Domain-specific: `:kpi_calculated`, `:plan_generated`, `:meal_accepted`

**Failure types:**
- Automatic: `:invalid_input` (from input validation failure)
- Not found: `:user_not_found`, `:member_not_found`, `:meal_not_found`
- Business rule: `:goal_not_allowed`, `:quota_exceeded`, `:already_completed`
- External: `:gateway_error`, `:ai_timeout`
- Persistence: `:validation_failed`

Failures that carry context use named keys: `Failure(:member_invalid, errors: member.errors.full_messages)`.

## Controller Integration

Always use Ruby `case/in` pattern matching. Never use `result.success?` or `result.failure?`.

```ruby
class PlansController < ApplicationController
  def create
    case Plans::CreatePlanProcess.call(user_id: current_user.id, **plan_params)
    in Solid::Success[type: :plan_created, plan:]
      redirect_to plan, notice: t(".success")
    in Solid::Failure[type: :invalid_input, input:]
      @errors = input.errors
      render :new, status: :unprocessable_entity
    in Solid::Failure[type: :user_not_found]
      redirect_to root_path, alert: t("errors.unauthorized")
    end
  end
end
```

For Turbo Stream responses:

```ruby
def create
  case Plans::CreatePlanProcess.call(user_id: current_user.id, **plan_params)
  in Solid::Success[type: :plan_created, plan:]
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("plan_#{plan.id}", partial: "plans/plan", locals: { plan: }) }
      format.html { redirect_to plan }
    end
  in Solid::Failure[type: :invalid_input, input:]
    @errors = input.errors
    render :new, status: :unprocessable_entity
  end
end
```

## Dependency Injection

Use `deps` for all collaborators. Process `attributes` are business data only. This enables isolated testing without mocking global constants and keeps the process API honest.

```ruby
deps do
  attribute :member_model, default: Member         # ActiveRecord model
  attribute :ai_gateway                            # external service
  attribute :mailer                               # ActionMailer class
  attribute :calculate_kpi_process                # nested process
end
```

Access via `deps.member_model`, `deps.ai_gateway`, etc.

Rules:
- Models may use default class refs in `deps` when appropriate.
- Outer-layer collaborators such as jobs, broadcasters, agents, gateways, mailers, and query objects must be injected explicitly and must not be defaulted in the process.
- Processes must not use query objects at all. Query objects are for read composition in controllers, views, and reports. Processes must use models and ownership-scoped relations.
- If a process triggers broadcasting or schedules follow-up background work, those collaborators still live in `deps`; they are not process attributes.

## Transactions

Use `ActiveRecord::Base.transaction` with bang methods. Rescue `RecordInvalid` to return a typed failure — do not use bare `rescue StandardError`.

```ruby
def call(attributes)
  ActiveRecord::Base.transaction do
    plan = Plan.create!(name: attributes[:name], user_id: attributes[:user_id])
    attributes[:members].each { |m| plan.members.create!(m) }
    Success(:plan_created, plan:)
  end
rescue ActiveRecord::RecordInvalid => e
  Failure(:validation_failed, errors: e.record.errors.full_messages)
end
```

## When to Use a Process

| Signal | Action |
|--------|--------|
| Controller action exceeds ~10 lines of business logic | Extract to process |
| Logic spans multiple models | Use process |
| Operation triggers side effects (jobs, mailers, broadcasters) | Use process |
| Business flow must decide when Turbo delivery or follow-up background work happens | Use process with explicitly injected deps |
| Same logic needed in multiple controllers | Use process |
| External API call with error handling | Use process |
| Multi-step operation with rollback | Use process |

**Skip when:** simple CRUD without business logic, the operation is a single model call with no side effects.

## References

- See [patterns.md](references/patterns.md) for CRUD, Transaction, Integration, and Orchestrator examples
- See `broadcaster-patterns` for `app/broadcasts` rules and broadcaster dependency injection
- See @solid-process-agent to implement a process
- See @rspec-agent for Solid::Process testing conventions
