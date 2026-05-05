class ChallengeParticipantsController < ApplicationController
  before_action :authenticate_user!

  def new
  end

  def create
    case Participants::JoinChallengeProcess.call(user_id: current_user.id, **challenge_participant_params)
    in Solid::Success[type: :participant_created]
      redirect_to new_challenge_participant_path, notice: "Você entrou no desafio."
    in Solid::Failure[type: :invalid_input, value: { input: }]
      redirect_to new_challenge_participant_path, alert: input.errors.full_messages.to_sentence
    in Solid::Failure[type: :challenge_not_found]
      redirect_to new_challenge_participant_path, alert: "Código do desafio não encontrado."
    in Solid::Failure[type: :challenge_not_published]
      redirect_to new_challenge_participant_path, alert: "Este desafio ainda não está publicado."
    in Solid::Failure[type: :challenge_already_started]
      redirect_to new_challenge_participant_path, alert: "Este desafio já começou."
    in Solid::Failure[type: :already_joined]
      redirect_to new_challenge_participant_path, alert: "Você já entrou neste desafio."
    in Solid::Failure[type: :user_not_found]
      redirect_to new_user_session_path, alert: "Entre novamente para continuar."
    in Solid::Failure[type: :validation_failed, value: { errors: }]
      redirect_to new_challenge_participant_path, alert: errors.to_sentence
    end
  end

  private

  def challenge_participant_params
    params.expect(challenge_participant: [ :challenge_code ])
  end
end
