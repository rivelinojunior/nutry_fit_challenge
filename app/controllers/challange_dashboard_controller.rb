class ChallangeDashboardController < ApplicationController
  before_action :redirect_guest_to_sign_in
  before_action :authenticate_user!

  def show
    @participant = find_participant

    return redirect_to join_path if @participant.blank?

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

  def redirect_guest_to_sign_in
    redirect_to new_user_session_path unless user_signed_in?
  end

  def find_participant
    participant_scope = current_user.participants.includes(:challenge)

    return participant_scope.order(joined_at: :desc).first if params[:participant_id].blank?

    participant_scope.find_by!(
      id: params[:participant_id],
      challenge_id: params[:challenge_id]
    )
  end

  def challenge_started?
    @challenge.start_date <= Date.current
  end
end
