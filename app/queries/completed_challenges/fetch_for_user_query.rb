# frozen_string_literal: true

module CompletedChallenges
  class FetchForUserQuery < ApplicationQuery
    CompletedChallengeItem = Data.define(:challenge, :participant, :rank, :total_points, :active_days)

    def initialize(user_id:)
      @user_id = user_id
    end

    def query
      success(data: completed_participants.map { |participant| build_item(participant) })
    end

    private

    attr_reader :user_id

    def completed_participants
      Participant
        .includes(:user, challenge: :participants)
        .joins(:challenge)
        .where(user_id:)
        .where(challenges: { end_date: ...Date.current })
        .order("challenges.end_date DESC", joined_at: :desc)
    end

    def build_item(participant)
      ranking_items = Rankings::FetchRankingQuery.query(challenge_id: participant.challenge_id).data
      participant_ranking_item = ranking_items.find { |item| item.participant.id == participant.id }

      CompletedChallengeItem.new(
        challenge: participant.challenge,
        participant:,
        rank: participant_ranking_item ? ranking_items.index(participant_ranking_item) + 1 : nil,
        total_points: participant_ranking_item&.total_points || 0,
        active_days: participant_ranking_item&.active_days || 0
      )
    end
  end
end
