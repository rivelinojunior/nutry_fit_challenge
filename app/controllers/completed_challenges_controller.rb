class CompletedChallengesController < ApplicationController
  before_action :authenticate_user!

  def index
    result = CompletedChallenges::FetchForUserQuery.query(user_id: current_user.id)

    return redirect_to join_path, alert: "Não foi possível carregar os desafios concluídos." unless result.success

    @completed_challenge_items = result.data
  end

  def show
    result = CompletedChallenges::FetchForUserAndChallengeQuery.query(
      user_id: current_user.id,
      challenge_id: params[:id]
    )

    return redirect_to completed_challenges_path, alert: "Desafio concluído não encontrado." unless result.success

    @completed_challenge_item = result.data.fetch(:completed_challenge_item)
    @challenge = @completed_challenge_item.challenge
    @participant = @completed_challenge_item.participant
    @ranking_items = result.data.fetch(:ranking_items)
  end
end
