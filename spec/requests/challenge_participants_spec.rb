require "rails_helper"

RSpec.describe "ChallengeParticipants" do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /challenge_participant/new" do
    it "renders successfully" do
      get new_challenge_participant_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the join title" do
      get new_challenge_participant_path

      expect(response.body).to include("Entrar no desafio")
    end

    it "renders the challenge code field" do
      get new_challenge_participant_path

      expect(response.body).to include("Código do desafio")
    end
  end

  describe "POST /challenge_participant" do
    let(:challenge) { create(:challenge, challenge_code: "ABC123", status: "published", start_date: Date.current + 1.day) }

    it "joins a challenge by challenge code" do
      expect do
        post challenge_participant_path, params: { challenge_participant: { challenge_code: challenge.challenge_code } }
      end.to change(Participant, :count).by(1)
    end

    it "redirects back to the join screen" do
      post challenge_participant_path, params: { challenge_participant: { challenge_code: challenge.challenge_code } }

      expect(response).to redirect_to(new_challenge_participant_path)
    end

    it "redirects when the challenge code is invalid" do
      post challenge_participant_path, params: { challenge_participant: { challenge_code: "NOPE12" } }

      expect(response).to redirect_to(new_challenge_participant_path)
    end

    it "sets a clear error for invalid codes" do
      post challenge_participant_path, params: { challenge_participant: { challenge_code: "NOPE12" } }

      expect(flash[:alert]).to eq("Código do desafio não encontrado.")
    end

    it "does not join after the challenge starts" do
      challenge.update!(start_date: Date.current)

      expect do
        post challenge_participant_path, params: { challenge_participant: { challenge_code: challenge.challenge_code } }
      end.not_to change(Participant, :count)
    end

    it "sets a clear error after the challenge starts" do
      challenge.update!(start_date: Date.current)

      post challenge_participant_path, params: { challenge_participant: { challenge_code: challenge.challenge_code } }

      expect(flash[:alert]).to eq("Este desafio já começou.")
    end

    it "does not join the same challenge twice" do
      create(:participant, user:, challenge:)

      expect do
        post challenge_participant_path, params: { challenge_participant: { challenge_code: challenge.challenge_code } }
      end.not_to change(Participant, :count)
    end

    it "sets a clear error when the user already joined" do
      create(:participant, user:, challenge:)

      post challenge_participant_path, params: { challenge_participant: { challenge_code: challenge.challenge_code } }

      expect(flash[:alert]).to eq("Você já entrou neste desafio.")
    end
  end
end
