module Admin
  class RemoveChallengeTaskProcess < Solid::Process
    CHALLENGE_TASK_NOT_FOUND_ERROR = "Tarefa não encontrada.".freeze
    ALREADY_STARTED_ERROR = "Challenge has already started".freeze

    input do
      attribute :challenge_id, :integer
      attribute :challenge_task_id, :integer
      attribute :user_id, :integer

      validates :challenge_id, :challenge_task_id, :user_id, presence: true
    end

    deps do
      attribute :challenge_model, default: Challenge
      attribute :challenge_task_model, default: ChallengeTask
    end

    def call(attributes)
      challenge = deps.challenge_model.find_by(id: attributes[:challenge_id], user_id: attributes[:user_id])
      challenge_task = challenge&.challenge_tasks&.find_by(id: attributes[:challenge_task_id])
      return Failure(:challenge_task_not_found, challenge:, errors: [ CHALLENGE_TASK_NOT_FOUND_ERROR ]) unless challenge_task

      return Failure(:already_started, challenge:, challenge_task:, errors: [ ALREADY_STARTED_ERROR ]) if started?(challenge)

      challenge_task.destroy

      Success(:removed, challenge:, challenge_task:)
    end

    private

    def started?(challenge)
      challenge.start_date <= Date.current
    end
  end
end
