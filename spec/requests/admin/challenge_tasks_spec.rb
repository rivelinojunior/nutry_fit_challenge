require "rails_helper"

RSpec.describe "Admin challenge tasks" do
  let(:user) { create(:user, :admin) }

  before do
    sign_in user
  end

  describe "GET /admin/challenge/:challenge_id/tasks" do
    context "without an authenticated user" do
      let!(:challenge) { create(:challenge, user:) }

      before do
        sign_out user
      end

      it "redirects to sign in" do
        get admin_challenge_tasks_path(challenge)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when the user is not an admin" do
      let(:user) { create(:user) }
      let!(:challenge) { create(:challenge, user:) }

      it "returns forbidden" do
        get admin_challenge_tasks_path(challenge)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with a challenge" do
      let!(:challenge) { create(:challenge, user:) }
      let!(:task) { create(:challenge_task, challenge:, scheduled_on: challenge.start_date, name: "Caminhar") }

      it "shows the generation form" do
        get admin_challenge_tasks_path(challenge)

        expect(response.body).to include("Gerar tarefas")
      end

      it "shows the generated task list" do
        get admin_challenge_tasks_path(challenge)

        expect(response.body).to include("Tarefas geradas")
      end

      it "shows the generated task name" do
        get admin_challenge_tasks_path(challenge)

        expect(response.body).to include("Caminhar")
      end

      it "shows the grouped task date" do
        get admin_challenge_tasks_path(challenge)

        expect(response.body).to include(task.scheduled_on.strftime("%d/%m/%Y"))
      end

      it "loads the challenge from the route id" do
        other_challenge = create(:challenge, user:, name: "Outro desafio")
        create(:challenge_task, challenge: other_challenge, name: "Outra tarefa")

        get admin_challenge_tasks_path(challenge)

        expect(response.body).to include("Caminhar")
        expect(response.body).not_to include("Outra tarefa")
      end
    end

    context "with an unknown challenge id" do
      it "shows an empty state" do
        get admin_challenge_tasks_path(0)

        expect(response.body).to include("Nenhum desafio encontrado")
      end
    end
  end

  describe "POST /admin/challenge/:challenge_id/tasks" do
    let!(:challenge) { create(:challenge, user:, start_date:, end_date:) }
    let(:start_date) { Date.current + 1.day }
    let(:end_date) { Date.current + 3.days }

    context "with daily recurrence" do
      let(:challenge_task_params) do
        {
          name: "Beber água",
          description: "Registrar consistência",
          points: 10,
          start_time: "08:00",
          end_time: "20:00",
          recurrence_type: "daily",
          weekdays: [],
          specific_date: nil
        }
      end

      it "generates daily tasks" do
        expect do
          post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }
        end.to change(ChallengeTask, :count).by(3)
      end

      it "redirects to the task list" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }

        expect(response).to redirect_to(admin_challenge_tasks_path(challenge))
      end
    end

    context "with weekday recurrence" do
      let(:start_date) { monday }
      let(:end_date) { monday + 6.days }
      let(:days_until_monday) { (1 - Date.current.wday) % 7 }
      let(:monday) { Date.current + (days_until_monday.zero? ? 7.days : days_until_monday.days) }
      let(:challenge_task_params) do
        {
          name: "Beber água",
          description: "Registrar consistência",
          points: 10,
          start_time: "08:00",
          end_time: "20:00",
          recurrence_type: "weekdays",
          weekdays: [ "1", "3" ],
          specific_date: nil
        }
      end

      it "generates tasks on selected weekdays" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }

        expect(challenge.challenge_tasks.order(:scheduled_on).pluck(:scheduled_on)).to eq([ monday, monday + 2.days ])
      end
    end

    context "with a specific date recurrence" do
      let(:challenge_task_params) do
        {
          name: "Beber água",
          description: "Registrar consistência",
          points: 10,
          start_time: "08:00",
          end_time: "20:00",
          recurrence_type: "specific_date",
          weekdays: [],
          specific_date: challenge.start_date
        }
      end

      it "generates the specific-date task" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }

        expect(challenge.challenge_tasks.pluck(:scheduled_on)).to contain_exactly(challenge.start_date)
      end
    end

    context "with invalid attributes" do
      let(:challenge_task_params) do
        {
          name: "",
          description: "Registrar consistência",
          points: 10,
          start_time: "08:00",
          end_time: "20:00",
          recurrence_type: "daily",
          weekdays: [],
          specific_date: nil
        }
      end

      it "returns unprocessable entity" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "shows validation errors" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }

        expect(response.body).to include("Name não pode ficar em branco")
      end
    end

    context "when the challenge already started" do
      let(:start_date) { Date.current }
      let(:end_date) { Date.current + 3.days }
      let(:challenge_task_params) do
        {
          name: "Beber água",
          description: "Registrar consistência",
          points: 10,
          start_time: "08:00",
          end_time: "20:00",
          recurrence_type: "daily",
          weekdays: [],
          specific_date: nil
        }
      end

      it "does not generate tasks" do
        expect do
          post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }
        end.not_to change(ChallengeTask, :count)
      end

      it "shows the process error" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }

        expect(response.body).to include("Challenge has already started")
      end
    end
  end

  describe "DELETE /admin/challenge/:challenge_id/tasks/:id" do
    context "when the challenge has not started" do
      let!(:challenge) { create(:challenge, user:, start_date: Date.current + 1.day) }
      let!(:task) { create(:challenge_task, challenge:) }

      it "removes the task" do
        expect do
          delete admin_challenge_task_path(challenge, task)
        end.to change(ChallengeTask, :count).by(-1)
      end
    end

    context "when the challenge already started" do
      let!(:challenge) { create(:challenge, user:, start_date: Date.current) }
      let!(:task) { create(:challenge_task, challenge:) }

      it "does not remove the task" do
        expect do
          delete admin_challenge_task_path(challenge, task)
        end.not_to change(ChallengeTask, :count)
      end

      it "shows the process error" do
        delete admin_challenge_task_path(challenge, task)

        expect(response.body).to include("Challenge has already started")
      end
    end

    context "when the task belongs to another user" do
      let!(:challenge) { create(:challenge, user:) }
      let!(:other_challenge) { create(:challenge) }
      let!(:task) { create(:challenge_task, challenge: other_challenge) }

      it "does not remove the task" do
        expect do
          delete admin_challenge_task_path(challenge, task)
        end.not_to change(ChallengeTask, :count)
      end

      it "shows not found" do
        delete admin_challenge_task_path(challenge, task)

        expect(response.body).to include("Tarefa não encontrada")
      end
    end
  end

  describe "POST /admin/challenge/:challenge_id/tasks/publish" do
    context "when at least one task exists" do
      let!(:challenge) { create(:challenge, user:) }

      before do
        create(:challenge_task, challenge:)
      end

      it "redirects to the task list" do
        post admin_publish_challenge_tasks_path(challenge)

        expect(response).to redirect_to(admin_challenge_tasks_path(challenge))
      end

      it "publishes the challenge" do
        post admin_publish_challenge_tasks_path(challenge)

        expect(challenge.reload.status).to eq("published")
      end
    end

    context "when no task exists" do
      let!(:challenge) { create(:challenge, user:) }

      it "returns unprocessable entity" do
        post admin_publish_challenge_tasks_path(challenge)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "shows the process error" do
        post admin_publish_challenge_tasks_path(challenge)

        expect(response.body).to include("Challenge must have tasks before publishing")
      end
    end

    context "when the challenge code is missing" do
      let!(:challenge) { create(:challenge, user:) }

      before do
        allow(Admin::PublishChallengeProcess).to receive(:call).and_return(
          Solid::Output::Failure.new(
            type: :missing_challenge_code,
            value: { errors: [ "Challenge must have a code before publishing" ] }
          )
        )
      end

      it "returns unprocessable entity" do
        post admin_publish_challenge_tasks_path(challenge)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "shows the process error" do
        post admin_publish_challenge_tasks_path(challenge)

        expect(response.body).to include("Challenge must have a code before publishing")
      end
    end
  end
end
