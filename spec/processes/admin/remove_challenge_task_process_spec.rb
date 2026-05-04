require "rails_helper"

RSpec.describe Admin::RemoveChallengeTaskProcess do
  describe ".call" do
    subject(:result) { described_class.call(challenge_task_id:) }

    let(:challenge) do
      create(
        :challenge,
        start_date: Date.current + 1.day,
        end_date: Date.current + 7.days
      )
    end
    let!(:challenge_task) { create(:challenge_task, challenge:) }
    let(:challenge_task_id) { challenge_task.id }

    context "when the challenge has not started" do
      it "returns a removed success" do
        expect(result).to be_success(:removed)
      end

      it "returns the removed task" do
        expect(result[:challenge_task]).to eq(challenge_task)
      end

      it "removes the task" do
        expect { result }.to change(ChallengeTask, :count).by(-1)
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

      it "does not remove the task" do
        expect { result }.not_to change(ChallengeTask, :count)
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

      it "does not remove the task" do
        expect { result }.not_to change(ChallengeTask, :count)
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

      it "does not remove a task" do
        expect { result }.not_to change(ChallengeTask, :count)
      end
    end
  end
end
