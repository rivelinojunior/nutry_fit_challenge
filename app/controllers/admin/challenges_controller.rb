module Admin
  class ChallengesController < BaseController
    before_action :set_challenge, only: %i[edit update]

    def new
      @challenge = current_user.challenges.build
    end

    def create
      case Admin::CreateChallengeProcess.call(user: current_user, **challenge_params)
      in Solid::Success[type: :created, value: { challenge: }]
        redirect_to admin_challenge_tasks_path(challenge), notice: "Desafio criado. Agora defina as tarefas."
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
      return redirect_to new_admin_challenge_path, alert: "Crie o desafio antes de editar." unless @challenge

      case Admin::UpdateChallengeProcess.call(challenge_id: @challenge.id, **challenge_params, timezone: @challenge.timezone)
      in Solid::Success[type: :updated, value: { challenge: }]
        redirect_to admin_challenge_tasks_path(challenge), notice: "Desafio atualizado."
      in Solid::Failure[type: :validation_failed, value: { challenge: }]
        @challenge = challenge
        render :edit, status: :unprocessable_entity
      in Solid::Failure[type: :already_started, value: { challenge:, errors: }]
        @challenge = challenge
        add_base_errors(@challenge, errors)
        render :edit, status: :unprocessable_entity
      in Solid::Failure[type: :invalid_input, value: { input: }]
        @challenge.assign_attributes(challenge_params)
        copy_input_errors(input, @challenge)
        render :edit, status: :unprocessable_entity
      in Solid::Failure[type: :challenge_not_found]
        redirect_to new_admin_challenge_path, alert: "Desafio não encontrado."
      end
    end

    private

    def set_challenge
      @challenge = current_user.challenges.order(:id).first
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
