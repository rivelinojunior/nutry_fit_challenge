require "rails_helper"

RSpec.describe Admin::CreateChallengeProcess do
  describe ".call" do
    subject(:result) { described_class.call(**attributes) }

    let(:user) { create(:user) }
    let(:attributes) do
      {
        user: user,
        name: "Desafio de Maio",
        description: "Checklist diário de hábitos",
        start_date: Date.current + 1.day,
        end_date: Date.current + 7.days
      }
    end

    context "with valid attributes" do
      it "returns the created challenge" do
        expect(result[:challenge]).to have_attributes(
          name: "Desafio de Maio",
          description: "Checklist diário de hábitos",
          start_date: attributes[:start_date],
          end_date: attributes[:end_date]
        )
      end

      it "persists the challenge" do
        expect { result }.to change(Challenge, :count).by(1)
      end

      it "returns a created success" do
        expect(result).to be_success(:created)
      end

      it "creates the challenge in draft" do
        expect(result[:challenge]).to have_attributes(status: "draft")
      end

      it "assigns the current user" do
        expect(result[:challenge]).to have_attributes(user: user)
      end

      it "applies the default timezone" do
        expect(result[:challenge]).to have_attributes(timezone: "America/Sao_Paulo")
      end

      it "assigns a valid challenge code" do
        expect(result[:challenge].challenge_code).to match(/\A[A-Z0-9]{6,8}\z/)
      end
    end

    context "when the generator returns a challenge code" do
      before do
        allow(Challenge).to receive(:generate_unique_challenge_code).and_return("UNIQUE1")
      end

      it "uses the generated challenge code" do
        expect(result[:challenge]).to have_attributes(challenge_code: "UNIQUE1")
      end
    end

    context "with an invalid date range" do
      let(:attributes) do
        super().merge(end_date: super()[:start_date] - 1.day)
      end

      it "returns a validation failure" do
        expect(result).to be_failure(:validation_failed)
      end

      it "returns the validation errors" do
        expect(result[:errors]).to include("End date must be greater than or equal to start date")
      end

      it "does not persist a challenge" do
        expect { result }.not_to change(Challenge, :count)
      end
    end

    context "without a name" do
      let(:attributes) do
        super().merge(name: nil)
      end

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "does not persist a challenge" do
        expect { result }.not_to change(Challenge, :count)
      end
    end

    context "without a user" do
      let(:attributes) do
        super().merge(user: nil)
      end

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "does not persist a challenge" do
        expect { result }.not_to change(Challenge, :count)
      end
    end

    context "without a start date" do
      let(:attributes) do
        super().merge(start_date: nil)
      end

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "does not persist a challenge" do
        expect { result }.not_to change(Challenge, :count)
      end
    end

    context "without an end date" do
      let(:attributes) do
        super().merge(end_date: nil)
      end

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "does not persist a challenge" do
        expect { result }.not_to change(Challenge, :count)
      end
    end

    context "with a blank timezone" do
      let(:attributes) do
        super().merge(timezone: nil)
      end

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end

      it "does not persist a challenge" do
        expect { result }.not_to change(Challenge, :count)
      end
    end
  end
end
