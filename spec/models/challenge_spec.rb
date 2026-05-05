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

        expect(challenge.errors.of_kind?(:user, :blank)).to be(true)
      end
    end

    context "without a name" do
      before { challenge.name = nil }

      it "adds a name error" do
        challenge.validate

        expect(challenge.errors.of_kind?(:name, :blank)).to be(true)
      end
    end

    context "without a start date" do
      before { challenge.start_date = nil }

      it "adds a start date error" do
        challenge.validate

        expect(challenge.errors.of_kind?(:start_date, :blank)).to be(true)
      end
    end

    context "without an end date" do
      before { challenge.end_date = nil }

      it "adds an end date error" do
        challenge.validate

        expect(challenge.errors.of_kind?(:end_date, :blank)).to be(true)
      end
    end

    context "without a timezone" do
      before { challenge.timezone = nil }

      it "adds a timezone error" do
        challenge.validate

        expect(challenge.errors.of_kind?(:timezone, :blank)).to be(true)
      end
    end

    context "without a status" do
      before { challenge.status = nil }

      it "adds a status error" do
        challenge.validate

        expect(challenge.errors.of_kind?(:status, :blank)).to be(true)
      end
    end

    context "without a challenge code" do
      subject(:challenge) { build(:challenge, challenge_code: nil) }

      it "generates a challenge code" do
        challenge.validate

        expect(challenge.challenge_code).to match(/\A[A-Z0-9]{6,8}\z/)
      end
    end

    context "with a duplicate challenge code" do
      before do
        create(:challenge, challenge_code: "ABC123")
        challenge.challenge_code = "ABC123"
      end

      it "adds a challenge code error" do
        challenge.validate

        expect(challenge.errors.of_kind?(:challenge_code, :taken)).to be(true)
      end
    end

    context "with a lowercase challenge code" do
      before { challenge.challenge_code = "abc123" }

      it "adds a challenge code error" do
        challenge.validate

        expect(challenge.errors.of_kind?(:challenge_code, :invalid)).to be(true)
      end
    end

    context "with a short challenge code" do
      before { challenge.challenge_code = "ABC12" }

      it "adds a challenge code error" do
        challenge.validate

        expect(challenge.errors.of_kind?(:challenge_code, :invalid)).to be(true)
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

        expect(challenge.errors.of_kind?(:status, :inclusion)).to be(true)
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

  describe ".generate_unique_challenge_code" do
    before do
      create(:challenge, challenge_code: "ABC123")
      allow(SecureRandom).to receive(:alphanumeric).and_return("ABC123", "XYZ789")
    end

    it "retries until the generated code is unique" do
      expect(described_class.generate_unique_challenge_code).to eq("XYZ789")
    end
  end

  describe "#challenge_code" do
    context "when the challenge is persisted" do
      let(:challenge) { create(:challenge, challenge_code: "ABC123") }

      it "cannot be assigned" do
        expect { challenge.challenge_code = "XYZ789" }.to raise_error(ActiveRecord::ReadonlyAttributeError)
      end
    end
  end

  it "belongs to a user" do
    association = described_class.reflect_on_association(:user)

    expect(association.macro).to eq(:belongs_to)
  end

  it "has many challenge tasks with dependent destroy" do
    association = described_class.reflect_on_association(:challenge_tasks)

    expect(association).to have_attributes(macro: :has_many, options: include(dependent: :destroy))
  end

  it "has many participants with dependent destroy" do
    association = described_class.reflect_on_association(:participants)

    expect(association).to have_attributes(macro: :has_many, options: include(dependent: :destroy))
  end

  it "has many users through participants" do
    association = described_class.reflect_on_association(:users)

    expect(association).to have_attributes(macro: :has_many, options: include(through: :participants))
  end
end
