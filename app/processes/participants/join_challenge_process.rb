module Participants
  class JoinChallengeProcess < Solid::Process
    PUBLISHED_STATUS = "published"
    CHALLENGE_NOT_PUBLISHED_ERROR = "Challenge is not published".freeze
    CHALLENGE_ALREADY_STARTED_ERROR = "Challenge has already started".freeze
    USER_ALREADY_JOINED_ERROR = "User already joined this challenge".freeze

    input do
      attribute :user_id, :integer
      attribute :challenge_code, :string

      normalizes :challenge_code, with: -> { _1&.strip&.upcase }

      validates :user_id, :challenge_code, presence: true
    end

    deps do
      attribute :user_model, default: User
      attribute :challenge_model, default: Challenge
      attribute :participant_model, default: Participant
    end

    def call(attributes)
      user = deps.user_model.find_by(id: attributes[:user_id])
      return Failure(:user_not_found) unless user

      challenge_code = attributes[:challenge_code].strip.upcase
      challenge = deps.challenge_model.find_by(challenge_code:)
      return Failure(:challenge_not_found) unless challenge

      return Failure(:challenge_not_published, challenge:, errors: [ CHALLENGE_NOT_PUBLISHED_ERROR ]) unless published?(challenge)

      participant = find_participant(user, challenge)
      return Failure(:already_joined, participant:, challenge:, errors: [ USER_ALREADY_JOINED_ERROR ]) if participant
      return Failure(:challenge_already_started, challenge:, errors: [ CHALLENGE_ALREADY_STARTED_ERROR ]) if started?(challenge)

      participant = deps.participant_model.create(user:, challenge:)

      if participant.persisted?
        Success(:participant_created, participant:, challenge:)
      else
        Failure(:validation_failed, participant:, errors: participant.errors.full_messages)
      end
    end

    private

    def published?(challenge)
      challenge.status == PUBLISHED_STATUS
    end

    def started?(challenge)
      challenge.start_date <= Date.current
    end

    def find_participant(user, challenge)
      deps.participant_model.find_by(user_id: user.id, challenge_id: challenge.id)
    end
  end
end
