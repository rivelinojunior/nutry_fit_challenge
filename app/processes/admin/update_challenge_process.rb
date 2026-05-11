module Admin
  class UpdateChallengeProcess < Solid::Process
    ALREADY_STARTED_ERROR = "Challenge has already started".freeze

    input do
      attribute :challenge_id, :integer
      attribute :user_id, :integer
      attribute :name, :string
      attribute :description, :string
      attribute :start_date, :date
      attribute :end_date, :date

      validates :challenge_id, :user_id, :name, :start_date, :end_date, presence: true
    end

    deps do
      attribute :challenge_model, default: Challenge
    end

    def call(attributes)
      challenge = deps.challenge_model.find_by(id: attributes[:challenge_id])
      return Failure(:challenge_not_found) unless challenge

      return Failure(:already_started, challenge:, errors: [ ALREADY_STARTED_ERROR ]) if started?(challenge)

      if challenge.update(challenge_attributes(attributes))
        Success(:updated, challenge:)
      else
        Failure(:validation_failed, challenge:, errors: challenge.errors.full_messages)
      end
    end

    private

    def started?(challenge)
      challenge.start_date <= Date.current
    end

    def challenge_attributes(attributes)
      attributes.slice(:name, :description, :start_date, :end_date)
    end
  end
end
