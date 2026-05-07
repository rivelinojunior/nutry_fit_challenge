class WaitingRoomController < ApplicationController
  before_action :authenticate_user!

  def new
    @participant = current_user.participants.includes(:challenge).find_by!(
      id: params[:participant_id],
      challenge_id: params[:challenge_id]
    )
    @challenge = @participant.challenge

    return redirect_to participant_dashboard_path(@challenge, @participant) if challenge_started?

    @days_remaining = (@challenge.start_date - Date.current).to_i
  end

  private

  def challenge_started?
    @challenge.start_date <= Date.current
  end
end
