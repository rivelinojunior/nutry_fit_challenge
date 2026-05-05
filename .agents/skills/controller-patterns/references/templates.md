# Controller Templates

## HTML REST Controller

Use this shape for admin and participant HTML controllers. Keep business logic
inside processes and use query objects for read composition when setup becomes
non-trivial.

```ruby
class Admin::ChallengesController < ApplicationController
  before_action :authenticate_user!

  def index
    @challenges = Admin::ChallengesQuery.new(user: current_user).call
  end

  def show
    @challenge = Admin::ChallengeQuery.new(user: current_user, challenge_id: params[:id]).call
  end

  def new
    @challenge = Challenge.new
  end

  def create
    case Admin::CreateChallengeProcess.call(user_id: current_user.id, **challenge_params)
    in Solid::Success[type: :challenge_created, challenge:]
      redirect_to admin_challenge_path(challenge), notice: t(".success")
    in Solid::Failure[type: :invalid_input, input:]
      @challenge = input
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @challenge = Admin::ChallengeQuery.new(user: current_user, challenge_id: params[:id]).call
  end

  def update
    case Admin::UpdateChallengeProcess.call(
      user_id: current_user.id,
      challenge_id: params[:id],
      **challenge_params
    )
    in Solid::Success[type: :challenge_updated, challenge:]
      redirect_to admin_challenge_path(challenge), notice: t(".success")
    in Solid::Failure[type: :invalid_input, input:]
      @challenge = input
      render :edit, status: :unprocessable_entity
    in Solid::Failure[type: :challenge_not_found]
      redirect_to admin_challenges_path, alert: t(".not_found")
    in Solid::Failure[type: :challenge_locked]
      redirect_to admin_challenge_path(params[:id]), alert: t(".locked")
    end
  end

  private

  def challenge_params
    params.expect(challenge: [ :name, :description, :start_date, :end_date, :timezone ])
  end
end
```

## Resourceful Domain Action

Prefer a small resource controller over a custom action on a large controller.

```ruby
class Admin::ChallengePublicationsController < ApplicationController
  before_action :authenticate_user!

  def create
    case Admin::PublishChallengeProcess.call(user_id: current_user.id, challenge_id: params[:challenge_id])
    in Solid::Success[type: :challenge_published, challenge:]
      redirect_to admin_challenge_path(challenge), notice: t(".success")
    in Solid::Failure[type: :challenge_not_found]
      redirect_to admin_challenges_path, alert: t(".not_found")
    in Solid::Failure[type: :challenge_invalid, errors:]
      redirect_to admin_challenge_path(params[:challenge_id]), alert: errors.to_sentence
    end
  end
end
```

Corresponding route:

```ruby
namespace :admin do
  resources :challenges do
    resource :publication, only: :create, controller: "challenge_publications"
  end
end
```

## Participant Check-In Controller

```ruby
class CheckinsController < ApplicationController
  before_action :authenticate_user!

  def create
    case Checkins::PerformCheckinProcess.call(
      user_id: current_user.id,
      challenge_task_id: params[:challenge_task_id]
    )
    in Solid::Success[type: :checkin_performed, checkin:]
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to challenge_path(checkin.challenge), notice: t(".success") }
      end
    in Solid::Failure[type: :already_checked_in]
      redirect_back fallback_location: root_path, alert: t(".already_checked_in")
    in Solid::Failure[type: :task_not_available]
      redirect_back fallback_location: root_path, alert: t(".task_not_available")
    in Solid::Failure[type: :participant_not_found]
      redirect_to root_path, alert: t(".participant_not_found")
    end
  end
end
```

## JSON/API Controller

Only add API controllers when product scope requires JSON clients. Keep API
responses structured and explicit.

```ruby
class Api::V1::CheckinsController < Api::V1::BaseController
  before_action :authenticate_user!

  def create
    case Checkins::PerformCheckinProcess.call(
      user_id: current_user.id,
      challenge_task_id: params[:challenge_task_id]
    )
    in Solid::Success[type: :checkin_performed, checkin:]
      render json: { id: checkin.id, checked_at: checkin.checked_at }, status: :created
    in Solid::Failure[type: :invalid_input, input:]
      render json: { errors: input.errors.full_messages }, status: :unprocessable_entity
    in Solid::Failure[type: :already_checked_in]
      render json: { errors: [I18n.t(".already_checked_in")] }, status: :unprocessable_entity
    end
  end
end
```

## ApplicationController Hooks

Keep global concerns small. Devise parameter sanitization already lives here;
add global rescue handlers only when the app has a consistent destination and
copy for that class of error.

```ruby
class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  allow_browser versions: :modern
  stale_when_importmap_changes

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end
end
```
