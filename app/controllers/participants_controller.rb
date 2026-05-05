class ParticipantsController < ApplicationController
  before_action :authenticate_user!

  def join
    @challenge_code = ""
  end

  def create
    @challenge_code = params[:challenge_code]

    case Participants::JoinChallengeProcess.call(user_id: current_user.id, challenge_code: @challenge_code)
    in Solid::Success[type: :participant_created, value: { participant: }]
      redirect_to participant_waiting_room_path(participant)
    in Solid::Failure[type: :invalid_input]
      render_join_error("Informe o código do desafio")
    in Solid::Failure[type: :challenge_not_found]
      render_join_error("Desafio não encontrado")
    in Solid::Failure[type: :challenge_not_published]
      render_join_error("Desafio indisponível")
    in Solid::Failure[type: :challenge_already_started]
      render_join_error("Desafio já começou")
    in Solid::Failure[type: :already_joined, value: { participant: }]
      redirect_to participant_dashboard_path(participant)
    in Solid::Failure[type: :user_not_found]
      redirect_to new_user_session_path, alert: "Entre novamente para continuar."
    in Solid::Failure[type: :validation_failed]
      render_join_error("Não foi possível entrar no desafio")
    end
  end

  def waiting_room
    render plain: "Sala de espera"
  end

  def dashboard
    render plain: "Painel do participante"
  end

  private

  def render_join_error(message)
    @error_message = message
    render :join, status: :unprocessable_entity
  end
end
