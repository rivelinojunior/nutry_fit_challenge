require "rails_helper"

RSpec.describe Challenge, type: :model do
  subject(:challenge) { build(:challenge) }

  describe "#valid?" do
    context "with valid attributes" do
      it { is_expected.to be_valid }
    end

    context "without a user" do
      before { challenge.user = nil }

      it "adds a user error" do
        challenge.validate

        expect(challenge.errors[:user]).to include("must exist")
      end
    end

    context "without a name" do
      before { challenge.name = nil }

      it "adds a name error" do
        challenge.validate

        expect(challenge.errors[:name]).to include("can't be blank")
      end
    end

    context "without a start date" do
      before { challenge.start_date = nil }

      it "adds a start date error" do
        challenge.validate

        expect(challenge.errors[:start_date]).to include("can't be blank")
      end
    end

    context "without an end date" do
      before { challenge.end_date = nil }

      it "adds an end date error" do
        challenge.validate

        expect(challenge.errors[:end_date]).to include("can't be blank")
      end
    end

    context "without a timezone" do
      before { challenge.timezone = nil }

      it "adds a timezone error" do
        challenge.validate

        expect(challenge.errors[:timezone]).to include("can't be blank")
      end
    end

    context "without a status" do
      before { challenge.status = nil }

      it "adds a status error" do
        challenge.validate

        expect(challenge.errors[:status]).to include("can't be blank")
      end
    end

    context "with draft status" do
      subject(:challenge) { build(:challenge, status: "draft") }

      it { is_expected.to be_valid }
    end

    context "with published status" do
      subject(:challenge) { build(:challenge, status: "published") }

      it { is_expected.to be_valid }
    end

    context "with an unsupported status" do
      before { challenge.status = "archived" }

      it "adds a status error" do
        challenge.validate

        expect(challenge.errors[:status]).to include("is not included in the list")
      end
    end

    context "when the end date equals the start date" do
      before { challenge.end_date = challenge.start_date }

      it { is_expected.to be_valid }
    end

    context "when the end date is before the start date" do
      before { challenge.end_date = challenge.start_date - 1.day }

      it "adds an end date error" do
        challenge.validate

        expect(challenge.errors[:end_date]).to include("must be greater than or equal to start date")
      end
    end
  end

  it "belongs to a user" do
    association = described_class.reflect_on_association(:user)

    expect(association.macro).to eq(:belongs_to)
  end
end
