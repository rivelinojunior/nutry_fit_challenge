module Admin
  class GenerateChallengeTasksProcess < Solid::Process
    RECURRENCE_TYPES = %w[daily weekdays specific_date].freeze
    WEEKDAYS = (0..6).freeze

    CHALLENGE_NOT_FOUND_ERROR = "Desafio não encontrado.".freeze
    ALREADY_STARTED_ERROR = "O desafio já começou.".freeze
    SPECIFIC_DATE_OUT_OF_RANGE_ERROR = "A data específica deve estar dentro do período do desafio.".freeze

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
      attribute :links

      validates :challenge_id, :user_id, :name, :points, :recurrence_type, presence: true
      validates :points, numericality: { only_integer: true, greater_than: 0 }, allow_blank: true
      validates :recurrence_type, inclusion: { in: RECURRENCE_TYPES }, allow_blank: true

      validate do
        unless (start_time.blank? && end_time.blank?) || (start_time.present? && end_time.present?)
          errors.add(:base, "Informe início e fim juntos.")
        end

        errors.add(:end_time, "deve ser maior que o início") if start_time.present? && end_time.present? && end_time <= start_time

        if recurrence_type == "weekdays"
          if weekdays.blank?
            errors.add(:weekdays, "devem ser selecionados")
          elsif !weekdays.respond_to?(:all?) || !weekdays.all? { |weekday| WEEKDAYS.cover?(weekday) }
            errors.add(:weekdays, "devem conter valores de 0 a 6")
          end
        end

        errors.add(:specific_date, :blank) if recurrence_type == "specific_date" && specific_date.blank?

        if links.present?
          if !links.respond_to?(:all?)
            errors.add(:links, "devem ser uma lista")
          else
            links.each do |link|
              errors.add(:links, "devem ter nome e URL") unless link.respond_to?(:key?)
            end

            normalized_links = Admin::GenerateChallengeTasksProcess.normalize_links(links)
            normalized_links.each do |link|
              errors.add(:links, "devem ter nome e URL") if link[:label].blank? || link[:url].blank?
              errors.add(:links, "devem começar com http ou https") if link[:url].present? && !Admin::GenerateChallengeTasksProcess.http_url?(link[:url])
            end
          end
        end
      end
    end

    deps do
      attribute :challenge_model, default: Challenge
      attribute :challenge_task_model, default: ChallengeTask
    end

    def self.normalize_links(links)
      return [] if links.blank?

      links.filter_map do |link|
        next unless link.respond_to?(:key?)

        label = link[:label].presence || link["label"]
        url = link[:url].presence || link["url"]
        next if label.blank? && url.blank?

        { label: label&.strip, url: url&.strip }
      end
    end

    def self.http_url?(url)
      uri = URI.parse(url)

      uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      false
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
        links: self.class.normalize_links(attributes[:links]).presence,
        scheduled_on:
      }
    end
  end
end
