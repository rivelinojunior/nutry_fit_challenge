module Admin
  class PublishChallengeProcess < Solid::Process
    PUBLISHED_STATUS = "published"
    ALREADY_PUBLISHED_ERROR = "Challenge is already published".freeze
    MISSING_TASKS_ERROR = "Challenge must have tasks before publishing".freeze

    input do
      attribute :challenge_id, :integer

      validates :challenge_id, presence: true
    end

    deps do
      attribute :challenge_model, default: Challenge
    end

    def call(attributes)
      challenge = deps.challenge_model.find_by(id: attributes[:challenge_id])
      return Failure(:challenge_not_found) unless challenge

      return Failure(:already_published, challenge:, errors: [ ALREADY_PUBLISHED_ERROR ]) if published?(challenge)
      return Failure(:missing_tasks, challenge:, errors: [ MISSING_TASKS_ERROR ]) unless challenge.challenge_tasks.exists?

      if challenge.update(status: PUBLISHED_STATUS)
        Success(:published, challenge:)
      else
        Failure(:validation_failed, challenge:, errors: challenge.errors.full_messages)
      end
    end

    private

    def published?(challenge)
      challenge.status == PUBLISHED_STATUS
    end
  end
end
