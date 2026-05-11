module Admin
  class ChallengesController < BaseController
    before_action :set_challenge, only: %i[show edit]

    def index
      @challenges = Challenge.includes(:user).order(start_date: :desc, created_at: :desc)
    end

    def show
      @task_form = default_task_form
      @challenge_started = @challenge.present? && @challenge.start_date <= Date.current
      @tasks_by_date = @challenge ? @challenge.challenge_tasks.order(:scheduled_on, :created_at).group_by(&:scheduled_on) : {}
    end

    def new
      @challenge = current_user.challenges.build
    end

    def create
      case Admin::CreateChallengeProcess.call(user: current_user, **challenge_params)
      in Solid::Success[type: :created, value: { challenge: }]
        redirect_to admin_challenge_path(challenge), notice: "Desafio criado. Agora defina as tarefas."
      in Solid::Failure[type: :validation_failed, value: { challenge: }]
        @challenge = challenge
        render :new, status: :unprocessable_entity
      in Solid::Failure[type: :invalid_input, value: { input: }]
        @challenge = current_user.challenges.build(challenge_params)
        copy_input_errors(input, @challenge)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      redirect_to new_admin_challenge_path, alert: "Crie o desafio antes de editar." unless @challenge
    end

    def update
      case Admin::UpdateChallengeProcess.call(challenge_id: params[:id], user_id: current_user.id, **challenge_params)
      in Solid::Success[type: :updated, value: { challenge: }]
        redirect_to admin_challenge_path(challenge), notice: "Desafio atualizado."
      in Solid::Failure[type: :validation_failed, value: { challenge: }]
        @challenge = challenge
        render :edit, status: :unprocessable_entity
      in Solid::Failure[type: :already_started, value: { challenge:, errors: }]
        @challenge = challenge
        add_base_errors(@challenge, errors)
        render :edit, status: :unprocessable_entity
      in Solid::Failure[type: :invalid_input, value: { input: }]
        @challenge = Challenge.find_by(id: params[:id])
        return redirect_to new_admin_challenge_path, alert: "Desafio não encontrado." unless @challenge

        @challenge.assign_attributes(challenge_params)
        copy_input_errors(input, @challenge)
        render :edit, status: :unprocessable_entity
      in Solid::Failure[type: :challenge_not_found]
        redirect_to new_admin_challenge_path, alert: "Desafio não encontrado."
      end
    end

    private

    def set_challenge
      @challenge = Challenge.find_by(id: params[:id])
    end

    def default_task_form
      {
        "recurrence_type" => "daily",
        "weekdays" => [],
        "points" => 10
      }
    end

    def challenge_params
      params.expect(challenge: %i[name description start_date end_date])
    end

    def copy_input_errors(input, challenge)
      input.errors.each do |error|
        challenge.errors.add(error.attribute, error.message)
      end
    end

    def add_base_errors(challenge, errors)
      errors.each { |error| challenge.errors.add(:base, error) }
    end
  end
end
