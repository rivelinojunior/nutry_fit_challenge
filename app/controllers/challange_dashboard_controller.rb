class ChallangeDashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @participant = current_user.participants.includes(:challenge).find_by!(
      id: params[:participant_id],
      challenge_id: params[:challenge_id]
    )
    @challenge = @participant.challenge

    unless challenge_started?
      return redirect_to challenge_participant_waiting_room_path(@challenge, @participant)
    end

    today_tasks_result = ChallengeTasks::FetchForTodayQuery.query(
      challenge_id: @challenge.id,
      participant_id: @participant.id
    )
    ranking_result = Rankings::FetchRankingQuery.query(challenge_id: @challenge.id)

    unless today_tasks_result.success && ranking_result.success
      return redirect_to join_path, alert: "Não foi possível carregar o painel."
    end

    @today_tasks = today_tasks_result.data
    @ranking_items = ranking_result.data
    @participant_ranking_item = @ranking_items.find { |item| item.participant.id == @participant.id }
    @participant_rank = @ranking_items.index(@participant_ranking_item)&.+(1)
  end

  private

  def challenge_started?
    @challenge.start_date <= Date.current
  end
end
