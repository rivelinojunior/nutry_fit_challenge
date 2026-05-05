require "rails_helper"

RSpec.describe "Participants" do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /join" do
    it "renders successfully" do
      get join_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the join title" do
      get join_path

      expect(response.body).to include("Join a Challenge")
    end

    it "renders the challenge code field" do
      get join_path

      expect(response.body).to include("Challenge Code")
    end
  end

  describe "GET /" do
    it "renders the join screen" do
      get root_path

      expect(response.body).to include("Join a Challenge")
    end
  end

  describe "POST /join" do
    let(:challenge) { create(:challenge, challenge_code: "ABC123", status: "published", start_date: Date.current + 1.day) }

    it "creates a participant by challenge code" do
      expect do
        post join_path, params: { challenge_code: challenge.challenge_code }
      end.to change(Participant, :count).by(1)
    end

    it "redirects to the waiting room" do
      post join_path, params: { challenge_code: challenge.challenge_code }

      expect(response).to redirect_to(participant_waiting_room_path(Participant.last))
    end

    it "looks up codes case insensitively" do
      expect do
        post join_path, params: { challenge_code: " #{challenge.challenge_code.downcase} " }
      end.to change(Participant, :count).by(1)
    end

    context "when the challenge code is invalid" do
      it "renders a clear inline error" do
        post join_path, params: { challenge_code: "NOPE12" }

        expect(response.body).to include("Challenge not found")
      end

      it "returns unprocessable entity" do
        post join_path, params: { challenge_code: "NOPE12" }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when the challenge is not published" do
      let(:challenge) { create(:challenge, challenge_code: "ABC123", status: "draft", start_date: Date.current + 1.day) }

      it "renders a clear inline error" do
        post join_path, params: { challenge_code: challenge.challenge_code }

        expect(response.body).to include("Challenge not available")
      end
    end

    context "when the challenge already started" do
      let(:challenge) { create(:challenge, challenge_code: "ABC123", status: "published", start_date: Date.current) }

      it "does not create a participant" do
        expect do
          post join_path, params: { challenge_code: challenge.challenge_code }
        end.not_to change(Participant, :count)
      end

      it "renders a clear inline error" do
        post join_path, params: { challenge_code: challenge.challenge_code }

        expect(response.body).to include("Challenge already started")
      end
    end

    context "when the user already joined" do
      let!(:participant) { create(:participant, user:, challenge:) }

      it "does not create a participant" do
        expect do
          post join_path, params: { challenge_code: challenge.challenge_code }
        end.not_to change(Participant, :count)
      end

      it "redirects to the dashboard" do
        post join_path, params: { challenge_code: challenge.challenge_code }

        expect(response).to redirect_to(participant_dashboard_path(participant))
      end
    end

    context "when the started challenge was already joined" do
      let(:challenge) { create(:challenge, challenge_code: "ABC123", status: "published", start_date: Date.current) }
      let!(:participant) { create(:participant, user:, challenge:) }

      it "redirects to the dashboard" do
        post join_path, params: { challenge_code: challenge.challenge_code }

        expect(response).to redirect_to(participant_dashboard_path(participant))
      end
    end
  end
end
