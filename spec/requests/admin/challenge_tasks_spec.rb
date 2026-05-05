require "rails_helper"

RSpec.describe "Admin challenge tasks" do
  let(:user) { create(:user, :admin) }

  before do
    sign_in user
  end

  describe "GET /admin/challenge/tasks" do
    context "when the user is not an admin" do
      let(:user) { create(:user) }

      it "returns forbidden" do
        get admin_challenge_tasks_path

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with a challenge" do
      let!(:challenge) { create(:challenge, user:) }
      let!(:task) { create(:challenge_task, challenge:, scheduled_on: challenge.start_date, name: "Caminhar") }

      it "shows the generation form" do
        get admin_challenge_tasks_path

        expect(response.body).to include("Gerar tarefas")
      end

      it "shows generated tasks grouped by date" do
        get admin_challenge_tasks_path

        expect(response.body).to include("Tarefas geradas")
        expect(response.body).to include("Caminhar")
        expect(response.body).to include(task.scheduled_on.strftime("%d/%m/%Y"))
      end
    end

    context "without a challenge" do
      it "shows an empty state" do
        get admin_challenge_tasks_path

        expect(response.body).to include("Nenhum desafio encontrado")
      end
    end
  end

  describe "POST /admin/challenge/tasks" do
    let(:challenge) { create(:challenge, user:, start_date: Date.current + 1.day, end_date: Date.current + 3.days) }

    before do
      challenge
    end

    it "generates daily tasks" do
      expect do
        post admin_challenge_tasks_path, params: { challenge_task: valid_params.merge(recurrence_type: "daily") }
      end.to change(ChallengeTask, :count).by(3)

      expect(response).to redirect_to(admin_challenge_tasks_path)
    end

    it "generates weekday-based tasks" do
      monday = next_weekday(1)
      challenge.update!(start_date: monday, end_date: monday + 6.days)

      post admin_challenge_tasks_path, params: { challenge_task: valid_params.merge(recurrence_type: "weekdays", weekdays: [ "1", "3" ]) }

      expect(challenge.challenge_tasks.order(:scheduled_on).pluck(:scheduled_on)).to eq([ monday, monday + 2.days ])
    end

    it "generates a specific-date task" do
      post admin_challenge_tasks_path, params: { challenge_task: valid_params.merge(recurrence_type: "specific_date", specific_date: challenge.start_date) }

      expect(challenge.challenge_tasks.pluck(:scheduled_on)).to contain_exactly(challenge.start_date)
    end

    it "shows errors when generation fails" do
      post admin_challenge_tasks_path, params: { challenge_task: valid_params.merge(name: "") }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Name não pode ficar em branco")
    end

    it "does not generate tasks after the challenge starts" do
      challenge.update!(start_date: Date.current, end_date: Date.current + 3.days)

      expect do
        post admin_challenge_tasks_path, params: { challenge_task: valid_params }
      end.not_to change(ChallengeTask, :count)

      expect(response.body).to include("Challenge has already started")
    end
  end

  describe "DELETE /admin/challenge/tasks/:id" do
    it "removes a task before challenge starts" do
      challenge = create(:challenge, user:, start_date: Date.current + 1.day)
      task = create(:challenge_task, challenge:)

      expect do
        delete admin_challenge_task_path(task)
      end.to change(ChallengeTask, :count).by(-1)
    end

    it "does not remove a task after challenge starts" do
      challenge = create(:challenge, user:, start_date: Date.current)
      task = create(:challenge_task, challenge:)

      expect do
        delete admin_challenge_task_path(task)
      end.not_to change(ChallengeTask, :count)

      expect(response.body).to include("Challenge has already started")
    end

    it "does not remove another user's task" do
      other_challenge = create(:challenge)
      task = create(:challenge_task, challenge: other_challenge)

      expect do
        delete admin_challenge_task_path(task)
      end.not_to change(ChallengeTask, :count)

      expect(response.body).to include("Tarefa não encontrada")
    end
  end

  describe "POST /admin/challenge/tasks/publish" do
    it "publishes when at least one task exists" do
      challenge = create(:challenge, user:)
      create(:challenge_task, challenge:)

      post admin_publish_challenge_tasks_path

      expect(response).to redirect_to(admin_challenge_tasks_path)
      expect(challenge.reload.status).to eq("published")
    end

    it "shows errors when no task exists" do
      create(:challenge, user:)

      post admin_publish_challenge_tasks_path

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Challenge must have tasks before publishing")
    end

    context "when the challenge code is missing" do
      before do
        create(:challenge, user:)
        allow(Admin::PublishChallengeProcess).to receive(:call).and_return(
          Solid::Output::Failure.new(
            type: :missing_challenge_code,
            value: { errors: [ "Challenge must have a code before publishing" ] }
          )
        )
      end

      it "returns unprocessable entity" do
        post admin_publish_challenge_tasks_path

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "shows the process error" do
        post admin_publish_challenge_tasks_path

        expect(response.body).to include("Challenge must have a code before publishing")
      end
    end
  end

  def valid_params
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

  def next_weekday(wday)
    days_until = (wday - Date.current.wday) % 7

    Date.current + (days_until.zero? ? 7.days : days_until.days)
  end
end
