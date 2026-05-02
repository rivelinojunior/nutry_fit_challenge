require "rails_helper"

RSpec.describe Participant, type: :model do
  subject(:participant) { build(:participant) }

  describe "#valid?" do
    context "with valid attributes" do
      it { is_expected.to be_valid }
    end

    context "without a user" do
      before { participant.user = nil }

      it "adds a user error" do
        participant.validate

        expect(participant.errors[:user]).to include("must exist")
      end
    end

    context "without a challenge" do
      before { participant.challenge = nil }

      it "adds a challenge error" do
        participant.validate

        expect(participant.errors[:challenge]).to include("must exist")
      end
    end

    context "without joined at" do
      let(:current_time) { Time.zone.local(2026, 5, 2, 12, 0, 0) }

      before do
        allow(Time).to receive(:current).and_return(current_time)
        participant.joined_at = nil
      end

      it "auto fills joined at" do
        participant.validate

        expect(participant.joined_at).to eq(current_time)
      end
    end

    context "with joined at validation" do
      it "validates joined at presence" do
        validators = described_class.validators_on(:joined_at)

        expect(validators).to include(an_object_having_attributes(kind: :presence))
      end
    end

    context "with the same user and challenge" do
      let(:user) { create(:user) }
      let(:challenge) { create(:challenge) }

      before do
        create(:participant, user: user, challenge: challenge)

        participant.user = user
        participant.challenge = challenge
      end

      it "adds a user error" do
        participant.validate

        expect(participant.errors[:user_id]).to include("has already been taken")
      end
    end

    context "with the same user and another challenge" do
      let(:user) { create(:user) }

      before do
        create(:participant, user: user)

        participant.user = user
      end

      it { is_expected.to be_valid }
    end

    context "with another user and the same challenge" do
      let(:challenge) { create(:challenge) }

      before do
        create(:participant, challenge: challenge)

        participant.challenge = challenge
      end

      it { is_expected.to be_valid }
    end
  end

  it "belongs to a user" do
    association = described_class.reflect_on_association(:user)

    expect(association.macro).to eq(:belongs_to)
  end

  it "belongs to a challenge" do
    association = described_class.reflect_on_association(:challenge)

    expect(association.macro).to eq(:belongs_to)
  end
end
