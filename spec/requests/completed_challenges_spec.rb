require "rails_helper"

RSpec.describe "Completed challenges" do
  let(:user) { create(:user) }

  describe "GET /completed_challenges" do
    context "when the user is not signed in" do
      it "redirects to sign in" do
        get completed_challenges_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when the user is signed in" do
      before do
        sign_in user
      end

      it "renders successfully" do
        get completed_challenges_path

        expect(response).to have_http_status(:ok)
      end

      it "renders the completed challenges title" do
        get completed_challenges_path

        expect(response.body).to include("Desafios concluídos")
      end
    end

    context "when the user has a completed challenge" do
      let(:challenge) { create(:challenge, name: "Desafio de Maio", status: "published", start_date: Date.current - 7.days, end_date: Date.current - 1.day) }
      let(:participant) { create(:participant, user:, challenge:) }
      let(:challenge_task) { create(:challenge_task, challenge:, points: 10, scheduled_on: Date.current - 2.days) }

      before do
        sign_in user
        create(:participant, challenge:)
        create(:checkin, participant:, challenge_task:)
      end

      it "renders the completed challenge name" do
        get completed_challenges_path

        expect(response.body).to include("Desafio de Maio")
      end

      it "renders the participant count" do
        get completed_challenges_path

        expect(response.body).to include("2 participantes")
      end

      it "renders the challenge duration" do
        get completed_challenges_path

        expect(response.body).to include("6 dias")
      end

      it "renders the details action" do
        get completed_challenges_path

        expect(response.body).to include("Detalhes")
      end

      it "does not render the final position" do
        get completed_challenges_path

        expect(response.body).not_to include("#1")
      end

      it "links to the completed challenge page" do
        get completed_challenges_path

        expect(response.body).to include(completed_challenge_path(challenge))
      end
    end
  end

  describe "GET /completed_challenges/:id" do
    context "when the user is not signed in" do
      let(:challenge) { create(:challenge, status: "published", start_date: Date.current - 7.days, end_date: Date.current - 1.day) }

      it "redirects to sign in" do
        get completed_challenge_path(challenge)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when the user has a completed challenge" do
      let(:challenge) { create(:challenge, name: "Desafio de Movimento", status: "published", start_date: Date.current - 7.days, end_date: Date.current - 1.day) }
      let(:participant) { create(:participant, user:, challenge:) }
      let(:challenge_task) { create(:challenge_task, challenge:, points: 30, scheduled_on: Date.current - 2.days) }

      before do
        sign_in user
        create(:checkin, participant:, challenge_task:)
      end

      it "renders the challenge name" do
        get completed_challenge_path(challenge)

        expect(response.body).to include("Desafio de Movimento")
      end

      it "renders the final position" do
        get completed_challenge_path(challenge)

        expect(response.body).to include("1º")
      end

      it "renders the final score" do
        get completed_challenge_path(challenge)

        expect(response.body).to include("30")
      end

      it "renders the back navigation" do
        get completed_challenge_path(challenge)

        expect(response.body).to include("Voltar para desafios concluídos")
      end
    end

    context "when the challenge is still current" do
      let(:challenge) { create(:challenge, status: "published", start_date: Date.current - 1.day, end_date: Date.current) }

      before do
        sign_in user
        create(:participant, user:, challenge:)
      end

      it "redirects to completed challenges" do
        get completed_challenge_path(challenge)

        expect(response).to redirect_to(completed_challenges_path)
      end
    end
  end
end
