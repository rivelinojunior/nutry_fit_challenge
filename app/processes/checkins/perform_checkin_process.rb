module Checkins
  class PerformCheckinProcess < Solid::Process
    CHALLENGE_NOT_FOUND_ERROR = "Challenge not found".freeze
    PARTICIPANT_NOT_FOUND_ERROR = "Participant not found".freeze
    CHALLENGE_TASK_NOT_FOUND_ERROR = "Challenge task not found".freeze
    TASK_OUTSIDE_CHALLENGE_ERROR = "Challenge task does not belong to challenge".freeze
    NOT_SCHEDULED_FOR_TODAY_ERROR = "Challenge task is not scheduled for today".freeze
    OUTSIDE_ALLOWED_WINDOW_ERROR = "Checkin is outside the allowed time window".freeze
    DUPLICATE_CHECKIN_ERROR = "Checkin has already been performed".freeze

    input do
      attribute :challenge_id, :integer
      attribute :participant_id, :integer
      attribute :challenge_task_id, :integer
      attribute :checked_at, :time, default: -> { Time.current }

      validates :challenge_id, :participant_id, :challenge_task_id, :checked_at, presence: true
    end

    deps do
      attribute :challenge_model, default: Challenge
      attribute :participant_model, default: Participant
      attribute :challenge_task_model, default: ChallengeTask
      attribute :checkin_model, default: Checkin
    end

    def call(attributes)
      challenge = deps.challenge_model.find_by(id: attributes[:challenge_id])
      return Failure(:challenge_not_found, errors: [ CHALLENGE_NOT_FOUND_ERROR ]) unless challenge

      participant = deps.participant_model.find_by(id: attributes[:participant_id], challenge_id: challenge.id)
      return Failure(:participant_not_found, challenge:, errors: [ PARTICIPANT_NOT_FOUND_ERROR ]) unless participant

      challenge_task = deps.challenge_task_model.find_by(id: attributes[:challenge_task_id])
      return Failure(:challenge_task_not_found, challenge:, errors: [ CHALLENGE_TASK_NOT_FOUND_ERROR ]) unless challenge_task

      unless challenge_task.challenge_id == challenge.id
        return Failure(:task_outside_challenge, challenge:, challenge_task:, errors: [ TASK_OUTSIDE_CHALLENGE_ERROR ])
      end

      checked_at = attributes[:checked_at].in_time_zone(challenge.timezone)
      unless scheduled_for_today?(challenge_task, checked_at)
        return Failure(:not_scheduled_for_today, challenge:, challenge_task:, errors: [ NOT_SCHEDULED_FOR_TODAY_ERROR ])
      end

      unless inside_allowed_window?(challenge_task, checked_at)
        return Failure(:outside_allowed_window, challenge:, challenge_task:, errors: [ OUTSIDE_ALLOWED_WINDOW_ERROR ])
      end

      if deps.checkin_model.exists?(participant_id: participant.id, challenge_task_id: challenge_task.id)
        return Failure(:duplicate_checkin, challenge:, challenge_task:, errors: [ DUPLICATE_CHECKIN_ERROR ])
      end

      checkin = deps.checkin_model.create!(
        participant:,
        challenge_task:,
        checked_at:
      )

      Success(:created, checkin:)
    rescue ActiveRecord::RecordInvalid => e
      Failure(:validation_failed, errors: e.record.errors.full_messages)
    end

    private

    def scheduled_for_today?(challenge_task, checked_at)
      challenge_task.scheduled_on == checked_at.to_date
    end

    def inside_allowed_window?(challenge_task, checked_at)
      return true if challenge_task.allowed_start_time.blank?

      checked_at_seconds = checked_at.seconds_since_midnight

      checked_at_seconds >= challenge_task.allowed_start_time.seconds_since_midnight &&
        checked_at_seconds <= challenge_task.allowed_end_time.seconds_since_midnight
    end
  end
end
