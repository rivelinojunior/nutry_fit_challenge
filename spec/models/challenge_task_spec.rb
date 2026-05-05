require "rails_helper"

RSpec.describe ChallengeTask, type: :model do
  subject(:challenge_task) { build(:challenge_task) }

  describe "#valid?" do
    context "with valid attributes" do
      it { is_expected.to be_valid }
    end

    context "without a challenge" do
      before { challenge_task.challenge = nil }

      it "adds a challenge error" do
        challenge_task.validate

        expect(challenge_task.errors.of_kind?(:challenge, :blank)).to be(true)
      end
    end

    context "without a name" do
      before { challenge_task.name = nil }

      it "adds a name error" do
        challenge_task.validate

        expect(challenge_task.errors.of_kind?(:name, :blank)).to be(true)
      end
    end

    context "without points" do
      before { challenge_task.points = nil }

      it "adds a points error" do
        challenge_task.validate

        expect(challenge_task.errors.of_kind?(:points, :blank)).to be(true)
      end
    end

    context "with zero points" do
      before { challenge_task.points = 0 }

      it "adds a points error" do
        challenge_task.validate

        expect(challenge_task.errors.of_kind?(:points, :greater_than)).to be(true)
      end
    end

    context "with non-integer points" do
      before { challenge_task.points = 1.5 }

      it "adds a points error" do
        challenge_task.validate

        expect(challenge_task.errors.of_kind?(:points, :not_an_integer)).to be(true)
      end
    end

    context "without a scheduled date" do
      before { challenge_task.scheduled_on = nil }

      it "adds a scheduled date error" do
        challenge_task.validate

        expect(challenge_task.errors.of_kind?(:scheduled_on, :blank)).to be(true)
      end
    end

    context "without an allowed time window" do
      before do
        challenge_task.allowed_start_time = nil
        challenge_task.allowed_end_time = nil
      end

      it { is_expected.to be_valid }
    end

    context "with a valid allowed time window" do
      before do
        challenge_task.allowed_start_time = Time.zone.parse("09:00")
        challenge_task.allowed_end_time = Time.zone.parse("10:00")
      end

      it { is_expected.to be_valid }
    end

    context "with an allowed start time and no allowed end time" do
      before do
        challenge_task.allowed_start_time = Time.zone.parse("09:00")
        challenge_task.allowed_end_time = nil
      end

      it "adds an allowed end time error" do
        challenge_task.validate

        expect(challenge_task.errors[:allowed_end_time]).to include("can't be blank")
      end
    end

    context "when the allowed end time equals the allowed start time" do
      before do
        challenge_task.allowed_start_time = Time.zone.parse("09:00")
        challenge_task.allowed_end_time = Time.zone.parse("09:00")
      end

      it "adds an allowed end time error" do
        challenge_task.validate

        expect(challenge_task.errors[:allowed_end_time]).to include("must be greater than allowed start time")
      end
    end

    context "when the allowed end time is before the allowed start time" do
      before do
        challenge_task.allowed_start_time = Time.zone.parse("10:00")
        challenge_task.allowed_end_time = Time.zone.parse("09:00")
      end

      it "adds an allowed end time error" do
        challenge_task.validate

        expect(challenge_task.errors[:allowed_end_time]).to include("must be greater than allowed start time")
      end
    end
  end

  it "belongs to a challenge" do
    association = described_class.reflect_on_association(:challenge)

    expect(association.macro).to eq(:belongs_to)
  end

  it "has many checkins with dependent destroy" do
    association = described_class.reflect_on_association(:checkins)

    expect(association).to have_attributes(macro: :has_many, options: include(dependent: :destroy))
  end
end
