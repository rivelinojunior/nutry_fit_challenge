# frozen_string_literal: true

module CompletedChallenges
  class FetchForUserAndChallengeQuery < ApplicationQuery
    CHALLENGE_NOT_FOUND_ERROR = "Challenge not found"

    def initialize(user_id:, challenge_id:)
      @user_id = user_id
      @challenge_id = challenge_id
    end

    def query
      participant = completed_participant
      return failure(errors: [ CHALLENGE_NOT_FOUND_ERROR ]) unless participant

      ranking_result = Rankings::FetchRankingQuery.query(challenge_id: participant.challenge_id)
      return failure(errors: ranking_result.errors) unless ranking_result.success

      success(data: {
        completed_challenge_item: build_item(participant, ranking_result.data),
        ranking_items: ranking_result.data
      })
    end

    private

    attr_reader :user_id, :challenge_id

    def completed_participant
      Participant
        .includes(:user, :challenge)
        .joins(:challenge)
        .where(user_id:, challenge_id:)
        .where(challenges: { end_date: ...Date.current })
        .first
    end

    def build_item(participant, ranking_items)
      participant_ranking_item = ranking_items.find { |item| item.participant.id == participant.id }

      FetchForUserQuery::CompletedChallengeItem.new(
        challenge: participant.challenge,
        participant:,
        rank: participant_ranking_item ? ranking_items.index(participant_ranking_item) + 1 : nil,
        total_points: participant_ranking_item&.total_points || 0,
        active_days: participant_ranking_item&.active_days || 0
      )
    end
  end
end
