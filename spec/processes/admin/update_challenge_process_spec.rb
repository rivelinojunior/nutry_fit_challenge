require "rails_helper"

RSpec.describe Admin::UpdateChallengeProcess do
  describe ".call" do
    subject(:result) { described_class.call(**attributes) }

    let(:challenge) { create(:challenge, start_date: Date.current + 1.day, end_date: Date.current + 7.days) }
    let(:attributes) do
      {
        challenge_id: challenge.id,
        user_id: challenge.user_id,
        name: "Desafio Atualizado",
        description: "Checklist atualizado",
        start_date: Date.current + 2.days,
        end_date: Date.current + 10.days
      }
    end

    context "when the challenge has not started" do
      it "returns the updated challenge" do
        expect(result[:challenge]).to have_attributes(
          name: "Desafio Atualizado",
          description: "Checklist atualizado",
          start_date: attributes[:start_date],
          end_date: attributes[:end_date]
        )
      end

      it "persists the updates" do
        result

        expect(challenge.reload).to have_attributes(
          name: "Desafio Atualizado",
          description: "Checklist atualizado",
          start_date: attributes[:start_date],
          end_date: attributes[:end_date]
        )
      end

      it "returns an updated success" do
        expect(result).to be_success(:updated)
      end
    end

    context "when the challenge already started" do
      let(:challenge) { create(:challenge, start_date: Date.current - 1.day, end_date: Date.current + 7.days) }

      it "returns an already started failure" do
        expect(result).to be_failure(:already_started)
      end

      it "returns a clear error" do
        expect(result[:errors]).to contain_exactly("Challenge has already started")
      end

      it "does not update the challenge" do
        expect { result }.not_to change { challenge.reload.name }
      end
    end

    context "when the challenge starts today" do
      let(:challenge) { create(:challenge, start_date: Date.current, end_date: Date.current + 7.days) }

      it "returns an already started failure" do
        expect(result).to be_failure(:already_started)
      end
    end

    context "with an invalid date range" do
      let(:attributes) do
        {
          challenge_id: challenge.id,
          user_id: challenge.user_id,
          name: "Desafio Atualizado",
          description: "Checklist atualizado",
          start_date: Date.current + 2.days,
          end_date: Date.current + 1.day
        }
      end

      it "returns a validation failure" do
        expect(result).to be_failure(:validation_failed)
      end

      it "returns the validation errors" do
        expect(result[:errors]).to include("End date must be greater than or equal to start date")
      end

      it "does not persist the invalid update" do
        expect { result }.not_to change { challenge.reload.end_date }
      end
    end

    context "without a challenge id" do
      let(:attributes) do
        {
          challenge_id: nil,
          user_id: challenge.user_id,
          name: "Desafio Atualizado",
          description: "Checklist atualizado",
          start_date: Date.current + 2.days,
          end_date: Date.current + 10.days
        }
      end

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end
    end

    context "when the challenge does not exist" do
      let(:attributes) do
        {
          challenge_id: 0,
          user_id: challenge.user_id,
          name: "Desafio Atualizado",
          description: "Checklist atualizado",
          start_date: Date.current + 2.days,
          end_date: Date.current + 10.days
        }
      end

      it "returns a challenge not found failure" do
        expect(result).to be_failure(:challenge_not_found)
      end
    end

    context "without a name" do
      let(:attributes) do
        {
          challenge_id: challenge.id,
          user_id: challenge.user_id,
          name: nil,
          description: "Checklist atualizado",
          start_date: Date.current + 2.days,
          end_date: Date.current + 10.days
        }
      end

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end
    end

    context "without a start date" do
      let(:attributes) do
        {
          challenge_id: challenge.id,
          user_id: challenge.user_id,
          name: "Desafio Atualizado",
          description: "Checklist atualizado",
          start_date: nil,
          end_date: Date.current + 10.days
        }
      end

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end
    end

    context "without an end date" do
      let(:attributes) do
        {
          challenge_id: challenge.id,
          user_id: challenge.user_id,
          name: "Desafio Atualizado",
          description: "Checklist atualizado",
          start_date: Date.current + 2.days,
          end_date: nil
        }
      end

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end
    end

    context "without a user id" do
      let(:attributes) do
        {
          challenge_id: challenge.id,
          user_id: nil,
          name: "Desafio Atualizado",
          description: "Checklist atualizado",
          start_date: Date.current + 2.days,
          end_date: Date.current + 10.days
        }
      end

      it "returns an invalid input failure" do
        expect(result).to be_failure(:invalid_input)
      end
    end

    context "when the challenge belongs to another user" do
      let(:attributes) do
        {
          challenge_id: challenge.id,
          user_id: create(:user).id,
          name: "Desafio Atualizado",
          description: "Checklist atualizado",
          start_date: Date.current + 2.days,
          end_date: Date.current + 10.days
        }
      end

      it "returns an updated success" do
        expect(result).to be_success(:updated)
      end

      it "persists the updates" do
        result

        expect(challenge.reload).to have_attributes(name: "Desafio Atualizado", description: "Checklist atualizado")
      end
    end
  end
end
