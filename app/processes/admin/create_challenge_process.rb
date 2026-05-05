module Admin
  class CreateChallengeProcess < Solid::Process
    DEFAULT_TIMEZONE = "America/Sao_Paulo"
    DEFAULT_STATUS = "draft"

    input do
      attribute :user
      attribute :name, :string
      attribute :description, :string
      attribute :start_date, :date
      attribute :end_date, :date
      attribute :timezone, :string, default: DEFAULT_TIMEZONE

      validates :user, :name, :start_date, :end_date, :timezone, presence: true
    end

    deps do
      attribute :challenge_model, default: Challenge
    end

    def call(attributes)
      challenge = deps.challenge_model.create(
        user: attributes[:user],
        name: attributes[:name],
        description: attributes[:description],
        start_date: attributes[:start_date],
        end_date: attributes[:end_date],
        timezone: attributes[:timezone],
        status: DEFAULT_STATUS,
        challenge_code: deps.challenge_model.generate_unique_challenge_code
      )

      if challenge.persisted?
        Success(:created, challenge:)
      else
        Failure(:validation_failed, challenge:, errors: challenge.errors.full_messages)
      end
    end
  end
end
