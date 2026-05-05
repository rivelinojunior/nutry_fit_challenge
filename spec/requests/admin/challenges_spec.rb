require "rails_helper"

RSpec.describe "Admin::Challenges" do
  let(:user) { create(:user, :admin) }

  before do
    sign_in user
  end

  describe "GET /admin/challenge/new" do
    it "renders an empty challenge form" do
      get new_admin_challenge_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Criar desafio")
      expect(response.body).to include("Data de início")
    end

    context "when the user is not an admin" do
      let(:user) { create(:user) }

      it "returns forbidden" do
        get new_admin_challenge_path

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /admin/challenge" do
    let(:challenge_attributes) do
      {
        name: "Desafio de Maio",
        description: "Checklist diário de hábitos",
        start_date: Date.current + 1.day,
        end_date: Date.current + 7.days
      }
    end

    it "creates a draft challenge" do
      expect do
        post admin_challenge_path, params: { challenge: challenge_attributes }
      end.to change(Challenge, :count).by(1)

      expect(Challenge.last).to have_attributes(
        user: user,
        name: "Desafio de Maio",
        status: "draft",
        challenge_code: match(/\A[A-Z0-9]{6,8}\z/)
      )
    end

    it "redirects to the challenge tasks screen" do
      post admin_challenge_path, params: { challenge: challenge_attributes }

      expect(response).to redirect_to(admin_challenge_tasks_path)
    end

    it "renders errors when the process rejects the attributes" do
      post admin_challenge_path, params: { challenge: challenge_attributes.merge(name: "") }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Revise os campos do desafio.")
      expect(response.body).to include("Name não pode ficar em branco")
    end
  end

  describe "GET /admin/challenge/edit" do
    it "renders the existing challenge form" do
      create(:challenge, user: user, name: "Desafio atual")

      get edit_admin_challenge_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Editar desafio")
      expect(response.body).to include("Desafio atual")
    end
  end

  describe "PATCH /admin/challenge" do
    let!(:challenge) { create(:challenge, user: user, start_date: Date.current + 1.day, end_date: Date.current + 7.days) }

    it "updates a challenge before it starts" do
      patch admin_challenge_path, params: {
        challenge: {
          name: "Desafio atualizado",
          description: "Checklist atualizado",
          start_date: Date.current + 2.days,
          end_date: Date.current + 10.days
        }
      }

      expect(response).to redirect_to(admin_challenge_tasks_path)
      expect(challenge.reload).to have_attributes(name: "Desafio atualizado", description: "Checklist atualizado")
    end

    it "does not update a challenge after it starts" do
      challenge.update!(start_date: Date.current - 1.day, end_date: Date.current + 7.days)

      expect do
        patch admin_challenge_path, params: {
          challenge: {
            name: "Desafio bloqueado",
            description: "Checklist bloqueado",
            start_date: Date.current + 2.days,
            end_date: Date.current + 10.days
          }
        }
      end.not_to change { challenge.reload.name }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Challenge has already started")
    end

    it "renders errors when the update is invalid" do
      patch admin_challenge_path, params: {
        challenge: {
          name: "Desafio atualizado",
          description: "Checklist atualizado",
          start_date: Date.current + 3.days,
          end_date: Date.current + 2.days
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("End date must be greater than or equal to start date")
    end
  end
end
