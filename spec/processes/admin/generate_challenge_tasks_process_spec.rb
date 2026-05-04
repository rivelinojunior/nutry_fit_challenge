require "rails_helper"

RSpec.describe Admin::GenerateChallengeTasksProcess do
  describe ".call" do
    subject(:result) { described_class.call(**attributes) }

    let(:challenge) do
      create(
        :challenge,
        start_date:,
        end_date:
      )
    end
    let(:start_date) do
      days_until_monday = (1 - Date.current.wday) % 7

      Date.current + (days_until_monday.zero? ? 7.days : days_until_monday.days)
    end
    let(:end_date) { start_date + 6.days }
    let(:challenge_id) { challenge.id }
    let(:name) { "Beber água" }
    let(:description) { "Registrar consumo diário" }
    let(:points) { 10 }
    let(:start_time) { Time.zone.local(2000, 1, 1, 8, 0, 0) }
    let(:end_time) { Time.zone.local(2000, 1, 1, 20, 0, 0) }
    let(:recurrence_type) { "daily" }
    let(:weekdays) { nil }
    let(:specific_date) { nil }
    let(:attributes) do
      {
        challenge_id:,
        name:,
        description:,
        points:,
        start_time:,
        end_time:,
        recurrence_type:,
        weekdays:,
        specific_date:
      }
    end

    context "with daily recurrence" do
      it "returns a created success" do
        expect(result).to be_success(:created)
      end

      it "creates one task for each challenge day" do
        expect { result }.to change(ChallengeTask, :count).by(7)
      end

      it "returns the created tasks" do
        expect(result[:tasks].size).to eq(7)
      end

      it "creates tasks for the whole challenge period" do
        result

        expect(challenge.challenge_tasks.order(:scheduled_on).pluck(:scheduled_on)).to eq((start_date..end_date).to_a)
      end

      it "assigns all tasks to the challenge" do
        expect(result[:tasks].map(&:challenge)).to all(eq(challenge))
      end

      it "sets scheduled_on on every task" do
        expect(result[:tasks].map(&:scheduled_on)).to all(be_present)
      end

      it "sets the task attributes" do
        expect(result[:tasks].first).to have_attributes(
          name: "Beber água",
          description: "Registrar consumo diário",
          points: 10
        )
      end

      it "sets the allowed time window" do
        expect(result[:tasks].first).to have_attributes(
          allowed_start_time: have_attributes(hour: 8, min: 0),
          allowed_end_time: have_attributes(hour: 20, min: 0)
        )
      end
    end

    context "with only required fields" do
      let(:description) { nil }
      let(:start_time) { nil }
      let(:end_time) { nil }

      it "returns a created success" do
        expect(result).to be_success(:created)
      end

      it "creates tasks without optional attributes" do
        expect { result }.to change(ChallengeTask, :count).by(7)
      end

      it "leaves optional task attributes blank" do
        expect(result[:tasks].first).to have_attributes(
          description: nil,
          allowed_start_time: nil,
          allowed_end_time: nil
        )
      end
    end

    context "with weekdays recurrence" do
      let(:recurrence_type) { "weekdays" }
      let(:weekdays) { [ 1, 3, 5 ] }

      it "returns a created success" do
        expect(result).to be_success(:created)
      end

      it "creates tasks only for selected weekdays" do
        result

        expect(challenge.challenge_tasks.order(:scheduled_on).pluck(:scheduled_on)).to eq(
          [ start_date, start_date + 2.days, start_date + 4.days ]
        )
      end
    end

    context "with weekdays recurrence and boundary weekdays" do
      let(:recurrence_type) { "weekdays" }
      let(:weekdays) { [ 0, 6 ] }

      it "returns a created success" do
        expect(result).to be_success(:created)
      end

      it "creates tasks for Saturday and Sunday" do
        result

        expect(challenge.challenge_tasks.order(:scheduled_on).pluck(:scheduled_on)).to eq(
          [ start_date + 5.days, start_date + 6.days ]
        )
      end
    end

    context "with specific date recurrence" do
      let(:recurrence_type) { "specific_date" }
      let(:specific_date) { start_date + 3.days }

      it "returns a created success" do
        expect(result).to be_success(:created)
      end

      it "creates one task for the specific date" do
        result

        expect(challenge.challenge_tasks.pluck(:scheduled_on)).to contain_exactly(start_date + 3.days)
      end
    end

    context "when the challenge does not exist" do
      let(:challenge_id) { 0 }

      it "returns a challenge not found failure" do
        expect(result).to be_failure(:challenge_not_found)
      end

      it "returns a clear error" do
        expect(result[:errors]).to contain_exactly("Challenge not found")
      end

      it "does not create tasks" do
        expect { result }.not_to change(ChallengeTask, :count)
      end
    end

    context "when the challenge already started" do
      let(:challenge) do
        create(
          :challenge,
          start_date: Date.current,
          end_date: Date.current + 7.days
        )
      end

      it "returns an already started failure" do
        expect(result).to be_failure(:already_started)
      end

      it "returns a clear error" do
        expect(result[:errors]).to contain_exactly("Challenge has already started")
      end

      it "does not create tasks" do
        expect { result }.not_to change(ChallengeTask, :count)
      end
    end

    context "without a challenge id" do
      let(:challenge_id) { nil }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:challenge_id]).to include("can't be blank")
      end
    end

    context "without a name" do
      let(:name) { "" }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:name]).to include("can't be blank")
      end

      it "does not create tasks" do
        expect { result }.not_to change(ChallengeTask, :count)
      end
    end

    context "with non-positive points" do
      let(:points) { 0 }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:points]).to include("must be greater than 0")
      end

      it "does not create tasks" do
        expect { result }.not_to change(ChallengeTask, :count)
      end
    end

    context "with an invalid recurrence type" do
      let(:recurrence_type) { "monthly" }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:recurrence_type]).to include("is not included in the list")
      end
    end

    context "with only a start time" do
      let(:end_time) { nil }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:base]).to include("Start time and end time must be provided together")
      end
    end

    context "with only an end time" do
      let(:start_time) { nil }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:base]).to include("Start time and end time must be provided together")
      end
    end

    context "with an end time before the start time" do
      let(:start_time) { Time.zone.local(2000, 1, 1, 20, 0, 0) }
      let(:end_time) { Time.zone.local(2000, 1, 1, 8, 0, 0) }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:end_time]).to include("must be greater than start time")
      end
    end

    context "with an end time equal to the start time" do
      let(:start_time) { Time.zone.local(2000, 1, 1, 8, 0, 0) }
      let(:end_time) { Time.zone.local(2000, 1, 1, 8, 0, 0) }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:end_time]).to include("must be greater than start time")
      end
    end

    context "with weekdays recurrence and no weekdays" do
      let(:recurrence_type) { "weekdays" }
      let(:weekdays) { nil }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:weekdays]).to include("can't be blank")
      end
    end

    context "with weekdays recurrence and an empty weekdays list" do
      let(:recurrence_type) { "weekdays" }
      let(:weekdays) { [] }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:weekdays]).to include("can't be blank")
      end
    end

    context "with weekdays recurrence and an invalid weekday" do
      let(:recurrence_type) { "weekdays" }
      let(:weekdays) { [ 1, 7 ] }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:weekdays]).to include("must contain values from 0 to 6")
      end
    end

    context "with weekdays recurrence and a non-list weekday value" do
      let(:recurrence_type) { "weekdays" }
      let(:weekdays) { 1 }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:weekdays]).to include("must contain values from 0 to 6")
      end
    end

    context "with specific date recurrence and no specific date" do
      let(:recurrence_type) { "specific_date" }
      let(:specific_date) { nil }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:specific_date]).to include("can't be blank")
      end
    end

    context "with specific date recurrence outside the challenge period" do
      let(:recurrence_type) { "specific_date" }
      let(:specific_date) { end_date + 1.day }

      it "returns a specific date out of range failure" do
        expect(result).to be_failure(:specific_date_out_of_range)
      end

      it "returns a clear error" do
        expect(result[:errors]).to contain_exactly("Specific date must be within the challenge period")
      end

      it "does not create tasks" do
        expect { result }.not_to change(ChallengeTask, :count)
      end
    end

    context "when task persistence fails after creating a task" do
      subject(:result) { described_class.new(challenge_task_model: failing_challenge_task_model).call(attributes) }

      let(:failing_challenge_task_model) do
        Class.new do
          def self.create!(attributes)
            @created_count ||= 0
            @created_count += 1

            raise ActiveRecord::RecordInvalid.new(ChallengeTask.new(attributes)) if @created_count == 2

            ChallengeTask.create!(attributes)
          end
        end
      end

      it "returns a validation failure" do
        expect(result).to be_failure(:validation_failed)
      end

      it "rolls back all task creation" do
        expect { result }.not_to change(ChallengeTask, :count)
      end
    end
  end
end
