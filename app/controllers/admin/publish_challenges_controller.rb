module Admin
  class PublishChallengesController < BaseController
    def update
      result = Admin::PublishChallengeProcess.call(challenge_id: params[:id])

      case result
      in Solid::Success[type: :published]
        redirect_to admin_challenge_tasks_path(result[:challenge]), notice: "Desafio publicado."
      in Solid::Failure[type: :invalid_input]
        failure_redirect(result[:input].errors.full_messages.to_sentence)
      in Solid::Failure[type: :challenge_not_found]
        failure_redirect("Desafio não encontrado.")
      in Solid::Failure[type: :already_published | :missing_challenge_code | :missing_tasks | :validation_failed]
        failure_redirect(result[:errors].to_sentence)
      end
    end

    private

    def failure_redirect(error_message)
      redirect_to admin_challenge_tasks_path(params[:id]), alert: error_message
    end
  end
end
