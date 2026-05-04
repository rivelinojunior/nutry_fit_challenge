module Admin
  class RemoveChallengeTaskProcess < Solid::Process
    CHALLENGE_TASK_NOT_FOUND_ERROR = "Challenge task not found".freeze
    ALREADY_STARTED_ERROR = "Challenge has already started".freeze

    input do
      attribute :challenge_task_id, :integer

      validates :challenge_task_id, presence: true
    end

    deps do
      attribute :challenge_task_model, default: ChallengeTask
    end

    def call(attributes)
      challenge_task = deps.challenge_task_model.find_by(id: attributes[:challenge_task_id])
      return Failure(:challenge_task_not_found, errors: [ CHALLENGE_TASK_NOT_FOUND_ERROR ]) unless challenge_task

      return Failure(:already_started, challenge_task:, errors: [ ALREADY_STARTED_ERROR ]) if started?(challenge_task.challenge)

      challenge_task.destroy

      Success(:removed, challenge_task:)
    end

    private

    def started?(challenge)
      challenge.start_date <= Date.current
    end
  end
end
