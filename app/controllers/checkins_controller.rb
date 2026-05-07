class CheckinsController < ApplicationController
  before_action :authenticate_user!

  def create
    participant = current_user.participants.find(params[:participant_id])

    case Checkins::PerformCheckinProcess.call(
      challenge_id: participant.challenge_id,
      participant_id: participant.id,
      challenge_task_id: params[:challenge_task_id]
    )
    in Solid::Success[type: :created]
      redirect_to participant_dashboard_path(participant.challenge, participant), notice: "Check-in registrado."
    in Solid::Failure[type: :invalid_input]
      redirect_to participant_dashboard_path(participant.challenge, participant), alert: "Tarefa inválida."
    in Solid::Failure[type: :challenge_not_found]
      redirect_to join_path, alert: "Desafio não encontrado."
    in Solid::Failure[type: :participant_not_found]
      redirect_to join_path, alert: "Participante não encontrado."
    in Solid::Failure[type: :challenge_task_not_found]
      redirect_to participant_dashboard_path(participant.challenge, participant), alert: "Tarefa não encontrada."
    in Solid::Failure[type: :task_outside_challenge]
      redirect_to participant_dashboard_path(participant.challenge, participant), alert: "Tarefa não pertence a este desafio."
    in Solid::Failure[type: :not_scheduled_for_today]
      redirect_to participant_dashboard_path(participant.challenge, participant), alert: "Esta tarefa não é de hoje."
    in Solid::Failure[type: :outside_allowed_window]
      redirect_to participant_dashboard_path(participant.challenge, participant), alert: "Esta tarefa não está disponível agora."
    in Solid::Failure[type: :duplicate_checkin]
      redirect_to participant_dashboard_path(participant.challenge, participant), alert: "Você já marcou esta tarefa."
    in Solid::Failure[type: :validation_failed]
      redirect_to participant_dashboard_path(participant.challenge, participant), alert: "Não foi possível registrar o check-in."
    end
  end
end
