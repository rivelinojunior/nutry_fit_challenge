require "rails_helper"

RSpec.describe Admin::PublishChallengeProcess do
  describe ".call" do
    subject(:result) { described_class.call(challenge_id:) }

    let(:challenge) { create(:challenge, status: "draft") }
    let(:challenge_id) { challenge.id }

    context "when the challenge is draft and has tasks" do
      before do
        create(:challenge_task, challenge:)
      end

      it "returns the published challenge" do
        expect(result[:challenge]).to have_attributes(status: "published")
      end

      it "persists the published status" do
        expect { result }.to change { challenge.reload.status }.from("draft").to("published")
      end

      it "returns a published success" do
        expect(result).to be_success(:published)
      end
    end

    context "when the challenge has no tasks" do
      it "returns a missing tasks failure" do
        expect(result).to be_failure(:missing_tasks)
      end

      it "returns a clear error" do
        expect(result[:errors]).to contain_exactly("Challenge must have tasks before publishing")
      end

      it "does not publish the challenge" do
        expect { result }.not_to change { challenge.reload.status }
      end
    end

    context "when the challenge has no challenge code" do
      before do
        create(:challenge_task, challenge:)
        allow(challenge).to receive(:challenge_code).and_return(nil)
        allow(Challenge).to receive(:find_by).with(id: challenge_id).and_return(challenge)
      end

      it "returns a missing challenge code failure" do
        expect(result).to be_failure(:missing_challenge_code)
      end

      it "returns a clear error" do
        expect(result[:errors]).to contain_exactly("Challenge must have a code before publishing")
      end
    end

    context "when the challenge is already published" do
      let(:challenge) { create(:challenge, status: "published") }

      before do
        create(:challenge_task, challenge:)
      end

      it "returns an already published failure" do
        expect(result).to be_failure(:already_published)
      end

      it "returns a clear error" do
        expect(result[:errors]).to contain_exactly("Challenge is already published")
      end

      it "keeps the challenge published" do
        expect { result }.not_to change { challenge.reload.status }
      end
    end

    context "without a challenge id" do
      let(:challenge_id) { nil }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end
    end

    context "when the challenge does not exist" do
      let(:challenge_id) { 0 }

      it "returns a challenge not found failure" do
        expect(result).to be_failure(:challenge_not_found)
      end
    end
  end
end
