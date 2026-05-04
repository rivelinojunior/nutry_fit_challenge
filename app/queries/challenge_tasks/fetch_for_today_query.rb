# frozen_string_literal: true

module ChallengeTasks
  class FetchForTodayQuery < ApplicationQuery
    Task = Data.define(:challenge_task, :checked, :state)

    CHALLENGE_NOT_FOUND_ERROR = "Challenge not found"
    PARTICIPANT_NOT_FOUND_ERROR = "Participant not found"
    PARTICIPANT_OUTSIDE_CHALLENGE_ERROR = "Participant does not belong to challenge"

    def initialize(challenge_id:, participant_id:)
      @challenge_id = challenge_id
      @participant_id = participant_id
    end

    def query
      challenge = Challenge.find_by(id: challenge_id)
      return failure(errors: [ CHALLENGE_NOT_FOUND_ERROR ]) unless challenge

      participant = Participant.find_by(id: participant_id)
      return failure(errors: [ PARTICIPANT_NOT_FOUND_ERROR ]) unless participant

      unless participant.challenge_id == challenge.id
        return failure(errors: [ PARTICIPANT_OUTSIDE_CHALLENGE_ERROR ])
      end

      current_time = Time.current.in_time_zone(challenge.timezone)
      today = current_time.to_date
      tasks = challenge.challenge_tasks.where(scheduled_on: today).order(:id)
      checked_task_ids = Checkin.where(participant_id: participant.id, challenge_task_id: tasks.select(:id)).pluck(:challenge_task_id)

      success(data: tasks.map { |task| build_task(task, checked_task_ids, current_time) })
    end

    private

    attr_reader :challenge_id, :participant_id

    def build_task(challenge_task, checked_task_ids, current_time)
      checked = checked_task_ids.include?(challenge_task.id)

      Task.new(
        challenge_task:,
        checked:,
        state: state_for(challenge_task, checked, current_time)
      )
    end

    def state_for(challenge_task, checked, current_time)
      return "checked" if checked
      return "available" if challenge_task.allowed_start_time.blank?

      current_seconds = current_time.seconds_since_midnight
      return "future" if current_seconds < challenge_task.allowed_start_time.seconds_since_midnight
      return "expired" if current_seconds > challenge_task.allowed_end_time.seconds_since_midnight

      "available"
    end
  end
end
