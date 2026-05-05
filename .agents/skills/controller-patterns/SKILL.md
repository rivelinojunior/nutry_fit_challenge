---
name: controller-patterns
description: >-
  Guides Rails 8 controller design for the Nutry.fit challenge app: thin
  controllers, RESTful routes, Devise authentication, strong parameters,
  query/process delegation, Solid::Process case/in result handling, Turbo
  responses, redirects, status codes, and request spec coverage. Use when
  designing, implementing, or reviewing controllers, routes, endpoints,
  HTTP response handling, controller specs, or request specs. WHEN NOT:
  Implementing business logic inside a process (use solid-process-patterns),
  changing Rails views or DaisyUI UI (use daisyui-frontend-patterns), or
  reviewing existing RSpec quality only (use rspec-review).
---

# Rails Controller Patterns

## Core Principle

Keep controllers thin. A controller authenticates, authorizes when an
authorization layer exists, delegates reads to query objects, delegates writes
to `Solid::Process`, prepares view state, and responds. It must not contain
business rules.

For this MVP, assume Devise `User` authentication via `authenticate_user!` and
`current_user`. Use app-specific terms from the domain: `Challenge`,
`ChallengeTask`, `Participant`, and `Checkin`.

## Collaboration Rules

- Use `before_action :authenticate_user!` for participant/admin flows unless the route is intentionally public.
- Use query objects for read/setup actions when record lookup, filtering, ranking, ownership scoping, or date logic is non-trivial.
- Use `Solid::Process` classes for write actions and multi-step workflows.
- Use `case/in` pattern matching for process results. Do not use `success?` or `failure?`.
- Keep result type symbols stable across process, controller, and specs.
- Keep model calls out of controllers once behavior becomes more than simple setup. Extract to a query or process instead.
- Prefer RESTful controllers over extra custom actions on a broad controller.

## RESTful Routing

Use conventional actions first:

```ruby
def index   # GET    /resources
def show    # GET    /resources/:id
def new     # GET    /resources/new
def create  # POST   /resources
def edit    # GET    /resources/:id/edit
def update  # PATCH  /resources/:id
def destroy # DELETE /resources/:id
```

Model domain verbs as resourceful controllers:

- Joining a challenge: `ChallengeParticipantsController#create`, not `ChallengesController#join`.
- Performing a check-in: `CheckinsController#create`, not `ChallengeTasksController#check_in`.
- Publishing a challenge: `Admin::ChallengePublicationsController#create`, not `Admin::ChallengesController#publish`.
- Removing a materialized task: `Admin::ChallengeTasksController#destroy` if it is true deletion.

## Process Integration

For write actions, call a process and handle every relevant result explicitly:

```ruby
class CheckinsController < ApplicationController
  before_action :authenticate_user!

  def create
    case Checkins::PerformCheckinProcess.call(
      user_id: current_user.id,
      challenge_task_id: params[:challenge_task_id]
    )
    in Solid::Success[type: :checkin_performed, checkin:]
      redirect_to challenge_path(checkin.challenge), notice: t(".success")
    in Solid::Failure[type: :invalid_input, input:]
      redirect_back fallback_location: root_path, alert: input.errors.full_messages.to_sentence
    in Solid::Failure[type: :participant_not_found]
      redirect_to root_path, alert: t(".participant_not_found")
    in Solid::Failure[type: :task_not_available]
      redirect_back fallback_location: root_path, alert: t(".task_not_available")
    end
  end
end
```

Use `solid-process-patterns` for result naming, dependency injection, and
process internals.

## Strong Parameters

Use a private params method. In Rails 8, prefer `params.expect` for permitted
mass-assignment attributes.

```ruby
def challenge_params
  params.expect(challenge: [ :name, :description, :start_date, :end_date, :timezone ])
end
```

Pass permitted params into processes as keyword arguments:

```ruby
Admin::CreateChallengeProcess.call(user_id: current_user.id, **challenge_params)
```

## Turbo Responses

When adding Turbo Stream responses, always keep an HTML fallback.

```ruby
respond_to do |format|
  format.turbo_stream
  format.html { redirect_to challenge_path(challenge), notice: t(".success") }
end
```

Inline `render turbo_stream:` is fine for synchronous response-local updates.
Extract reusable or out-of-request delivery to a dedicated broadcaster only
when the app has such a layer.

## Error Handling

Use HTTP statuses intentionally:

```ruby
:ok                    # 200
:created               # 201
:no_content            # 204
:unauthorized          # 401
:forbidden             # 403
:not_found             # 404
:unprocessable_entity  # 422
```

Validation failures that re-render forms should use `:unprocessable_entity`.
Successful HTML writes usually redirect. JSON/API endpoints should render
structured JSON and explicit statuses.

## Testing Checklist

- Authentication: signed-in and unauthenticated paths.
- Authorization or ownership scope when relevant.
- Successful path: redirect/render, status, flash, and side effect.
- Failure paths for each process result handled by the controller.
- Invalid params return `:unprocessable_entity` when rendering the form again.
- Turbo Stream response and HTML fallback when Turbo is used.
- No controller business rules that duplicate process logic.

## References

- Read [templates.md](references/templates.md) for controller templates and patterns.
- Read [request-specs.md](references/request-specs.md) when adding or reviewing request specs.
- Use `solid-process-patterns` for process result contracts.
- Use `daisyui-frontend-patterns` before changing controller-coupled views.
