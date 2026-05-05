require "rails_helper"

RSpec.describe Checkin, type: :model do
  subject(:checkin) { build(:checkin) }

  describe "#valid?" do
    context "with valid attributes" do
      it { is_expected.to be_valid }
    end

    context "without a participant" do
      before { checkin.participant = nil }

      it "adds a participant error" do
        checkin.validate

        expect(checkin.errors.of_kind?(:participant, :blank)).to be(true)
      end
    end

    context "without a challenge task" do
      before { checkin.challenge_task = nil }

      it "adds a challenge task error" do
        checkin.validate

        expect(checkin.errors.of_kind?(:challenge_task, :blank)).to be(true)
      end
    end

    context "without checked at on creation" do
      let(:current_time) { Time.zone.local(2026, 5, 2, 12, 0, 0) }

      before { allow(Time).to receive(:current).and_return(current_time) }

      it "auto fills checked at" do
        checkin = create(:checkin, checked_at: nil)

        expect(checkin.checked_at).to eq(current_time)
      end
    end

    context "with checked at validation" do
      it "validates checked at presence" do
        validators = described_class.validators_on(:checked_at)

        expect(validators).to include(an_object_having_attributes(kind: :presence))
      end
    end

    context "with the same participant and challenge task" do
      let(:participant) { create(:participant) }
      let(:challenge_task) { create(:challenge_task) }

      before do
        create(:checkin, participant: participant, challenge_task: challenge_task)

        checkin.participant = participant
        checkin.challenge_task = challenge_task
      end

      it "adds a challenge task error" do
        checkin.validate

        expect(checkin.errors.of_kind?(:challenge_task_id, :taken)).to be(true)
      end
    end

    context "with the same participant and another challenge task" do
      let(:participant) { create(:participant) }

      before do
        create(:checkin, participant: participant)

        checkin.participant = participant
      end

      it { is_expected.to be_valid }
    end

    context "with another participant and the same challenge task" do
      let(:challenge_task) { create(:challenge_task) }

      before do
        create(:checkin, challenge_task: challenge_task)

        checkin.challenge_task = challenge_task
      end

      it { is_expected.to be_valid }
    end
  end

  it "belongs to a participant" do
    association = described_class.reflect_on_association(:participant)

    expect(association.macro).to eq(:belongs_to)
  end

  it "belongs to a challenge task" do
    association = described_class.reflect_on_association(:challenge_task)

    expect(association.macro).to eq(:belongs_to)
  end
end
