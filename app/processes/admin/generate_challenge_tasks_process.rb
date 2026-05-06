module Admin
  class GenerateChallengeTasksProcess < Solid::Process
    RECURRENCE_TYPES = %w[daily weekdays specific_date].freeze
    WEEKDAYS = (0..6).freeze

    CHALLENGE_NOT_FOUND_ERROR = "Challenge not found".freeze
    ALREADY_STARTED_ERROR = "Challenge has already started".freeze
    SPECIFIC_DATE_OUT_OF_RANGE_ERROR = "Specific date must be within the challenge period".freeze

    input do
      attribute :challenge_id, :integer
      attribute :user_id, :integer
      attribute :name, :string
      attribute :description, :string
      attribute :points, :integer
      attribute :start_time, :time
      attribute :end_time, :time
      attribute :recurrence_type, :string
      attribute :weekdays
      attribute :specific_date, :date

      validates :challenge_id, :user_id, :name, :points, :recurrence_type, presence: true
      validates :points, numericality: { only_integer: true, greater_than: 0 }, allow_blank: true
      validates :recurrence_type, inclusion: { in: RECURRENCE_TYPES }, allow_blank: true

      validate do
        unless (start_time.blank? && end_time.blank?) || (start_time.present? && end_time.present?)
          errors.add(:base, "Start time and end time must be provided together")
        end

        errors.add(:end_time, "must be greater than start time") if start_time.present? && end_time.present? && end_time <= start_time

        if recurrence_type == "weekdays"
          if weekdays.blank?
            errors.add(:weekdays, "can't be blank")
          elsif !weekdays.respond_to?(:all?) || !weekdays.all? { |weekday| WEEKDAYS.cover?(weekday) }
            errors.add(:weekdays, "must contain values from 0 to 6")
          end
        end

        errors.add(:specific_date, "can't be blank") if recurrence_type == "specific_date" && specific_date.blank?
      end
    end

    deps do
      attribute :challenge_model, default: Challenge
      attribute :challenge_task_model, default: ChallengeTask
    end

    def call(attributes)
      challenge = deps.challenge_model.find_by(id: attributes[:challenge_id], user_id: attributes[:user_id])
      return Failure(:challenge_not_found, errors: [ CHALLENGE_NOT_FOUND_ERROR ]) unless challenge

      return Failure(:already_started, challenge:, errors: [ ALREADY_STARTED_ERROR ]) if started?(challenge)
      return specific_date_out_of_range_failure(challenge) if specific_date_out_of_range?(challenge, attributes)

      tasks = create_tasks!(challenge, attributes)

      Success(:created, challenge:, tasks:)
    rescue ActiveRecord::RecordInvalid => e
      Failure(:validation_failed, challenge:, errors: e.record.errors.full_messages)
    end

    private

    def started?(challenge)
      challenge.start_date <= Date.current
    end

    def specific_date_out_of_range?(challenge, attributes)
      return false unless attributes[:recurrence_type] == "specific_date"

      attributes[:specific_date].before?(challenge.start_date) || attributes[:specific_date].after?(challenge.end_date)
    end

    def specific_date_out_of_range_failure(challenge)
      Failure(:specific_date_out_of_range, challenge:, errors: [ SPECIFIC_DATE_OUT_OF_RANGE_ERROR ])
    end

    def create_tasks!(challenge, attributes)
      ActiveRecord::Base.transaction do
        scheduled_dates(challenge, attributes).map do |scheduled_on|
          deps.challenge_task_model.create!(task_attributes(challenge, attributes, scheduled_on))
        end
      end
    end

    def scheduled_dates(challenge, attributes)
      case attributes[:recurrence_type]
      when "daily"
        challenge.start_date..challenge.end_date
      when "weekdays"
        (challenge.start_date..challenge.end_date).select { |date| attributes[:weekdays].include?(date.wday) }
      when "specific_date"
        [ attributes[:specific_date] ]
      end
    end

    def task_attributes(challenge, attributes, scheduled_on)
      {
        challenge:,
        name: attributes[:name],
        description: attributes[:description],
        points: attributes[:points],
        allowed_start_time: attributes[:start_time],
        allowed_end_time: attributes[:end_time],
        scheduled_on:
      }
    end
  end
end
