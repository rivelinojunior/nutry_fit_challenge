# frozen_string_literal: true

module Rankings
  class FetchRankingQuery < ApplicationQuery
    RankingItem = Data.define(:participant, :total_points, :active_days, :last_checkin)

    CHALLENGE_NOT_FOUND_ERROR = "Challenge not found"

    def initialize(challenge_id:)
      @challenge_id = challenge_id
    end

    def query
      challenge = Challenge.find_by(id: challenge_id)
      return failure(errors: [ CHALLENGE_NOT_FOUND_ERROR ]) unless challenge

      success(data: build_ranking(challenge))
    end

    private

    attr_reader :challenge_id

    def build_ranking(challenge)
      challenge
        .participants
        .joins(join_checkins_and_challenge_tasks_sql(challenge))
        .select(ranking_select_sql)
        .group("participants.id")
        .order(
          Arel.sql("total_points DESC"),
          Arel.sql("active_days DESC"),
          Arel.sql("last_checkin DESC")
        )
        .map { |participant| build_ranking_item(participant) }
    end

    def join_checkins_and_challenge_tasks_sql(challenge)
      Participant.sanitize_sql_array(
        [
          <<~SQL.squish,
            LEFT OUTER JOIN checkins
              ON checkins.participant_id = participants.id
            LEFT OUTER JOIN challenge_tasks
              ON challenge_tasks.id = checkins.challenge_task_id
              AND challenge_tasks.challenge_id = ?
          SQL
          challenge.id
        ]
      )
    end

    def ranking_select_sql
      <<~SQL.squish
        participants.*,
        COALESCE(SUM(challenge_tasks.points), 0) AS total_points,
        COUNT(DISTINCT challenge_tasks.scheduled_on) AS active_days,
        MAX(
          CASE
            WHEN challenge_tasks.id IS NOT NULL THEN checkins.checked_at
          END
        ) AS last_checkin
      SQL
    end

    def build_ranking_item(participant)
      RankingItem.new(
        participant:,
        total_points: participant.total_points.to_i,
        active_days: participant.active_days.to_i,
        last_checkin: participant.last_checkin
      )
    end
  end
end
