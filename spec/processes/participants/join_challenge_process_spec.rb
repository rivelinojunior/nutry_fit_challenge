require "rails_helper"

RSpec.describe Participants::JoinChallengeProcess do
  describe ".call" do
    subject(:result) { described_class.call(user_id:, challenge_code:) }

    let(:user) { create(:user) }
    let(:user_id) { user.id }
    let(:challenge) { create(:challenge, challenge_code: "ABC123", status: "published", start_date: Date.current + 1.day) }
    let(:challenge_code) { challenge.challenge_code }

    context "when the challenge can be joined" do
      it "returns the created participant" do
        expect(result[:participant]).to have_attributes(user:, challenge:)
      end

      it "creates a participant" do
        expect { result }.to change(Participant, :count).by(1)
      end

      it "returns a participant created success" do
        expect(result).to be_success(:participant_created)
      end
    end

    context "with lowercase and spaced challenge code" do
      let(:challenge_code) { " abc123 " }

      before do
        challenge
      end

      it "creates a participant" do
        expect { result }.to change(Participant, :count).by(1)
      end
    end

    context "without a user id" do
      let(:user_id) { nil }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end
    end

    context "without a challenge code" do
      let(:challenge_code) { nil }

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end
    end

    context "when the user does not exist" do
      let(:user_id) { 0 }

      it "returns a user not found failure" do
        expect(result).to be_failure(:user_not_found)
      end
    end

    context "when the challenge does not exist" do
      let(:challenge_code) { "MISSING" }

      it "returns a challenge not found failure" do
        expect(result).to be_failure(:challenge_not_found)
      end
    end

    context "when the challenge is draft" do
      let(:challenge) { create(:challenge, challenge_code: "ABC123", status: "draft", start_date: Date.current + 1.day) }

      it "returns a challenge not published failure" do
        expect(result).to be_failure(:challenge_not_published)
      end

      it "does not create a participant" do
        expect { result }.not_to change(Participant, :count)
      end
    end

    context "when the challenge starts today" do
      let(:challenge) { create(:challenge, challenge_code: "ABC123", status: "published", start_date: Date.current) }

      it "returns a challenge already started failure" do
        expect(result).to be_failure(:challenge_already_started)
      end

      it "does not create a participant" do
        expect { result }.not_to change(Participant, :count)
      end
    end

    context "when the user already joined" do
      before do
        create(:participant, user:, challenge:)
      end

      it "returns an already joined failure" do
        expect(result).to be_failure(:already_joined)
      end

      it "does not create a participant" do
        expect { result }.not_to change(Participant, :count)
      end
    end

    context "when the already joined challenge starts today" do
      let(:challenge) { create(:challenge, challenge_code: "ABC123", status: "published", start_date: Date.current) }

      before do
        create(:participant, user:, challenge:)
      end

      it "returns an already joined failure" do
        expect(result).to be_failure(:already_joined)
      end
    end
  end
end
