require "rails_helper"

RSpec.describe "Admin::Challenges" do
  let(:user) { create(:user, :admin) }

  before do
    sign_in user
  end

  describe "GET /admin/challenges/new" do
    it "returns ok" do
      get new_admin_challenge_path

      expect(response).to have_http_status(:ok)
    end

    it "shows the create title" do
      get new_admin_challenge_path

      expect(response.body).to include("Criar desafio")
    end

    it "shows the start date field" do
      get new_admin_challenge_path

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

  describe "GET /admin/challenges/:id" do
    let(:challenge) { create(:challenge, user:) }

    context "without an authenticated user" do
      before do
        sign_out user
      end

      it "redirects to sign in" do
        get admin_challenge_path(challenge)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when the user is not an admin" do
      let(:user) { create(:user) }

      it "returns forbidden" do
        get admin_challenge_path(challenge)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with a challenge" do
      let!(:task) { create(:challenge_task, challenge:, scheduled_on: challenge.start_date, name: "Caminhar") }

      it "shows the generation form" do
        get admin_challenge_path(challenge)

        expect(response.body).to include("Gerar tarefas")
      end

      it "shows the generated task list" do
        get admin_challenge_path(challenge)

        expect(response.body).to include("Tarefas geradas")
      end

      it "shows the generated task name" do
        get admin_challenge_path(challenge)

        expect(response.body).to include("Caminhar")
      end

      it "shows the grouped task date" do
        get admin_challenge_path(challenge)

        expect(response.body).to include(task.scheduled_on.strftime("%d/%m/%Y"))
      end
    end

    context "with an unknown challenge" do
      it "shows an empty state" do
        get admin_challenge_path(0)

        expect(response.body).to include("Nenhum desafio encontrado")
      end
    end
  end

  describe "POST /admin/challenges" do
    context "with valid attributes" do
      let(:challenge_attributes) do
        {
          name: "Desafio de Maio",
          description: "Checklist diário de hábitos",
          start_date: Date.current + 1.day,
          end_date: Date.current + 7.days
        }
      end

      it "creates a challenge" do
        expect do
          post admin_challenges_path, params: { challenge: challenge_attributes }
        end.to change(Challenge, :count).by(1)
      end

      it "creates a draft challenge for the current user" do
        post admin_challenges_path, params: { challenge: challenge_attributes }

        expect(Challenge.last).to have_attributes(user:, name: "Desafio de Maio", status: "draft")
      end

      it "generates a challenge code" do
        post admin_challenges_path, params: { challenge: challenge_attributes }

        expect(Challenge.last.challenge_code).to match(/\A[A-Z0-9]{6,8}\z/)
      end

      it "redirects to the challenge setup screen" do
        post admin_challenges_path, params: { challenge: challenge_attributes }

        expect(response).to redirect_to(admin_challenge_path(Challenge.last))
      end
    end

    context "with invalid attributes" do
      let(:challenge_attributes) do
        {
          name: "",
          description: "Checklist diário de hábitos",
          start_date: Date.current + 1.day,
          end_date: Date.current + 7.days
        }
      end

      it "returns unprocessable content" do
        post admin_challenges_path, params: { challenge: challenge_attributes }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "shows the form error summary" do
        post admin_challenges_path, params: { challenge: challenge_attributes }

        expect(response.body).to include("Revise os campos do desafio.")
      end

      it "shows the validation error" do
        post admin_challenges_path, params: { challenge: challenge_attributes }

        expect(response.body).to include("Name não pode ficar em branco")
      end
    end
  end

  describe "GET /admin/challenges/:id/edit" do
    let(:challenge) { create(:challenge, user:, name: "Desafio atual") }

    it "returns ok" do
      get edit_admin_challenge_path(challenge)

      expect(response).to have_http_status(:ok)
    end

    it "shows the edit title" do
      get edit_admin_challenge_path(challenge)

      expect(response.body).to include("Editar desafio")
    end

    it "shows the existing challenge name" do
      get edit_admin_challenge_path(challenge)

      expect(response.body).to include("Desafio atual")
    end
  end

  describe "PATCH /admin/challenges/:id" do
    let!(:challenge) { create(:challenge, user:, start_date: Date.current + 1.day, end_date: Date.current + 7.days) }

    context "when the challenge has not started" do
      it "redirects to the challenge setup screen" do
        patch admin_challenge_path(challenge), params: {
          challenge: {
            name: "Desafio atualizado",
            description: "Checklist atualizado",
            start_date: Date.current + 2.days,
            end_date: Date.current + 10.days
          }
        }

        expect(response).to redirect_to(admin_challenge_path(challenge))
      end

      it "updates the challenge attributes" do
        patch admin_challenge_path(challenge), params: {
          challenge: {
            name: "Desafio atualizado",
            description: "Checklist atualizado",
            start_date: Date.current + 2.days,
            end_date: Date.current + 10.days
          }
        }

        expect(challenge.reload).to have_attributes(name: "Desafio atualizado", description: "Checklist atualizado")
      end
    end

    context "when the challenge already started" do
      before do
        challenge.update!(start_date: Date.current - 1.day, end_date: Date.current + 7.days)
      end

      it "does not update the challenge name" do
        expect do
          patch admin_challenge_path(challenge), params: {
            challenge: {
              name: "Desafio bloqueado",
              description: "Checklist bloqueado",
              start_date: Date.current + 2.days,
              end_date: Date.current + 10.days
            }
          }
        end.not_to change { challenge.reload.name }
      end

      it "returns unprocessable content" do
        patch admin_challenge_path(challenge), params: {
          challenge: {
            name: "Desafio bloqueado",
            description: "Checklist bloqueado",
            start_date: Date.current + 2.days,
            end_date: Date.current + 10.days
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "shows the process error" do
        patch admin_challenge_path(challenge), params: {
          challenge: {
            name: "Desafio bloqueado",
            description: "Checklist bloqueado",
            start_date: Date.current + 2.days,
            end_date: Date.current + 10.days
          }
        }

        expect(response.body).to include("Challenge has already started")
      end
    end

    it "renders errors when the update is invalid" do
      patch admin_challenge_path(challenge), params: {
        challenge: {
          name: "Desafio atualizado",
          description: "Checklist atualizado",
          start_date: Date.current + 3.days,
          end_date: Date.current + 2.days
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "shows update validation errors" do
      patch admin_challenge_path(challenge), params: {
        challenge: {
          name: "Desafio atualizado",
          description: "Checklist atualizado",
          start_date: Date.current + 3.days,
          end_date: Date.current + 2.days
        }
      }

      expect(response.body).to include("End date must be greater than or equal to start date")
    end

    it "does not update another user's challenge" do
      other_challenge = create(:challenge, start_date: Date.current + 1.day, end_date: Date.current + 7.days)

      expect do
        patch admin_challenge_path(other_challenge), params: {
          challenge: {
            name: "Desafio externo",
            description: "Checklist externo",
            start_date: Date.current + 2.days,
            end_date: Date.current + 10.days
          }
        }
      end.not_to change { other_challenge.reload.name }
    end
  end
end
