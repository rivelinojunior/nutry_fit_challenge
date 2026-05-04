require "rails_helper"

RSpec.describe Checkins::PerformCheckinProcess do
  describe ".call" do
    subject(:result) { described_class.call(**attributes) }

    let(:challenge) do
      create(
        :challenge,
        start_date: Date.current,
        end_date: Date.current + 6.days,
        timezone: "America/Sao_Paulo"
      )
    end
    let(:participant) { create(:participant, challenge:) }
    let(:challenge_task) do
      create(
        :challenge_task,
        challenge:,
        scheduled_on: checked_at.in_time_zone(challenge.timezone).to_date,
        allowed_start_time: Time.zone.parse("08:00"),
        allowed_end_time: Time.zone.parse("20:00")
      )
    end
    let(:challenge_id) { challenge.id }
    let(:participant_id) { participant.id }
    let(:challenge_task_id) { challenge_task.id }
    let(:checked_at) { Time.zone.local(2026, 5, 3, 12, 0, 0) }
    let(:attributes) do
      {
        challenge_id:,
        participant_id:,
        challenge_task_id:,
        checked_at:
      }
    end

    context "when the checkin is valid" do
      it "returns a created success" do
        expect(result).to be_success(:created)
      end

      it "creates a checkin" do
        expect { result }.to change(Checkin, :count).by(1)
      end

      it "returns the created checkin with the checked time" do
        expect(result[:checkin]).to have_attributes(
          checked_at: checked_at.in_time_zone(challenge.timezone)
        )
      end

      it "assigns the checkin to the participant" do
        expect(result[:checkin].participant).to eq(participant)
      end

      it "assigns the checkin to the challenge task" do
        expect(result[:checkin].challenge_task).to eq(challenge_task)
      end
    end

    context "when the task does not belong to the challenge" do
      let(:other_challenge) { create(:challenge) }
      let(:challenge_task) do
        create(
          :challenge_task,
          challenge: other_challenge,
          scheduled_on: checked_at.in_time_zone(challenge.timezone).to_date
        )
      end

      it "returns a task outside challenge failure" do
        expect(result).to be_failure(:task_outside_challenge)
      end

      it "returns a clear error" do
        expect(result[:errors]).to contain_exactly("Challenge task does not belong to challenge")
      end

      it "does not create a checkin" do
        expect { result }.not_to change(Checkin, :count)
      end
    end

    context "when the task is not scheduled for today" do
      let(:challenge_task) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: checked_at.in_time_zone(challenge.timezone).to_date + 1.day
        )
      end

      it "returns a not scheduled for today failure" do
        expect(result).to be_failure(:not_scheduled_for_today)
      end

      it "returns a clear error" do
        expect(result[:errors]).to contain_exactly("Challenge task is not scheduled for today")
      end

      it "does not create a checkin" do
        expect { result }.not_to change(Checkin, :count)
      end
    end

    context "when the checkin is outside the allowed time window" do
      let(:checked_at) { Time.zone.local(2026, 5, 3, 7, 59, 0) }

      it "returns an outside allowed window failure" do
        expect(result).to be_failure(:outside_allowed_window)
      end

      it "returns a clear error" do
        expect(result[:errors]).to contain_exactly("Checkin is outside the allowed time window")
      end

      it "does not create a checkin" do
        expect { result }.not_to change(Checkin, :count)
      end
    end

    context "when the task has no allowed time window" do
      let(:challenge_task) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: checked_at.in_time_zone(challenge.timezone).to_date,
          allowed_start_time: nil,
          allowed_end_time: nil
        )
      end

      it "returns a created success" do
        expect(result).to be_success(:created)
      end

      it "creates a checkin" do
        expect { result }.to change(Checkin, :count).by(1)
      end
    end

    context "when the checkin is duplicated" do
      before do
        create(:checkin, participant:, challenge_task:)
      end

      it "returns a duplicate checkin failure" do
        expect(result).to be_failure(:duplicate_checkin)
      end

      it "returns a clear error" do
        expect(result[:errors]).to contain_exactly("Checkin has already been performed")
      end

      it "does not create a checkin" do
        expect { result }.not_to change(Checkin, :count)
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

    context "without a participant id" do
      let(:participant_id) { nil }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:participant_id]).to include("can't be blank")
      end
    end

    context "without a challenge task id" do
      let(:challenge_task_id) { nil }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:challenge_task_id]).to include("can't be blank")
      end
    end

    context "without a checked at" do
      let(:challenge_task_id) { 1 }
      let(:checked_at) { nil }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "returns a clear error" do
        expect(result[:input].errors[:checked_at]).to include("can't be blank")
      end
    end

    context "when the challenge does not exist" do
      let(:challenge_id) { 0 }

      it "returns a challenge not found failure" do
        expect(result).to be_failure(:challenge_not_found)
      end

      it "does not create a checkin" do
        expect { result }.not_to change(Checkin, :count)
      end
    end

    context "when the challenge task does not exist" do
      let(:challenge_task_id) { 0 }

      it "returns a challenge task not found failure" do
        expect(result).to be_failure(:challenge_task_not_found)
      end

      it "returns a clear error" do
        expect(result[:errors]).to contain_exactly("Challenge task not found")
      end

      it "does not create a checkin" do
        expect { result }.not_to change(Checkin, :count)
      end
    end

    context "when the participant does not belong to the challenge" do
      let(:other_challenge) { create(:challenge) }
      let(:participant) { create(:participant, challenge: other_challenge) }

      it "returns a participant not found failure" do
        expect(result).to be_failure(:participant_not_found)
      end

      it "does not create a checkin" do
        expect { result }.not_to change(Checkin, :count)
      end
    end
  end
end
