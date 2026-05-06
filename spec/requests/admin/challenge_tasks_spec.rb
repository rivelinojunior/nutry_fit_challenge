require "rails_helper"

RSpec.describe "Admin challenge tasks" do
  let(:user) { create(:user, :admin) }

  before do
    sign_in user
  end

  describe "POST /admin/challenges/:challenge_id/tasks" do
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

      it "returns turbo stream updates" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }, as: :turbo_stream

        expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
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
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }, as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "shows validation errors" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }, as: :turbo_stream

        expect(response.body).to include("Name não pode ficar em branco")
      end
    end

    context "with weekday recurrence and no selected weekday" do
      let(:challenge_task_params) do
        {
          name: "Beber água",
          description: "Registrar consistência",
          points: 10,
          start_time: "08:00",
          end_time: "20:00",
          recurrence_type: "weekdays",
          weekdays: [],
          specific_date: nil
        }
      end

      it "returns unprocessable content" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }, as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "shows the weekday validation error" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }, as: :turbo_stream

        expect(CGI.unescapeHTML(response.body)).to include("Weekdays can't be blank")
      end
    end

    context "with an invalid weekday value" do
      let(:challenge_task_params) do
        {
          name: "Beber água",
          description: "Registrar consistência",
          points: 10,
          start_time: "08:00",
          end_time: "20:00",
          recurrence_type: "weekdays",
          weekdays: [ "7" ],
          specific_date: nil
        }
      end

      it "shows the weekday range error" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }, as: :turbo_stream

        expect(response.body).to include("Weekdays must contain values from 0 to 6")
      end
    end

    context "with only one time boundary" do
      let(:challenge_task_params) do
        {
          name: "Beber água",
          description: "Registrar consistência",
          points: 10,
          start_time: "08:00",
          end_time: "",
          recurrence_type: "daily",
          weekdays: [],
          specific_date: nil
        }
      end

      it "shows the paired time validation error" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }, as: :turbo_stream

        expect(response.body).to include("Start time and end time must be provided together")
      end
    end

    context "with an end time before the start time" do
      let(:challenge_task_params) do
        {
          name: "Beber água",
          description: "Registrar consistência",
          points: 10,
          start_time: "20:00",
          end_time: "08:00",
          recurrence_type: "daily",
          weekdays: [],
          specific_date: nil
        }
      end

      it "shows the time order validation error" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }, as: :turbo_stream

        expect(response.body).to include("End time must be greater than start time")
      end
    end

    context "with a specific date outside the challenge period" do
      let(:challenge_task_params) do
        {
          name: "Beber água",
          description: "Registrar consistência",
          points: 10,
          start_time: "08:00",
          end_time: "20:00",
          recurrence_type: "specific_date",
          weekdays: [],
          specific_date: challenge.start_date - 1.day
        }
      end

      it "returns unprocessable content" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }, as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "shows the date range error" do
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }, as: :turbo_stream

        expect(response.body).to include("Specific date must be within the challenge period")
      end
    end

    context "when the challenge does not exist" do
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
          post admin_challenge_tasks_path(0), params: { challenge_task: challenge_task_params }
        end.not_to change(ChallengeTask, :count)
      end

      it "shows not found" do
        post admin_challenge_tasks_path(0), params: { challenge_task: challenge_task_params }, as: :turbo_stream

        expect(response.body).to include("Challenge not found")
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
        post admin_challenge_tasks_path(challenge), params: { challenge_task: challenge_task_params }, as: :turbo_stream

        expect(response.body).to include("Challenge has already started")
      end
    end
  end

  describe "DELETE /admin/challenges/:challenge_id/tasks/:id" do
    context "when the challenge has not started" do
      let!(:challenge) { create(:challenge, user:, start_date: Date.current + 1.day) }
      let!(:task) { create(:challenge_task, challenge:) }

      it "removes the task" do
        expect do
          delete admin_challenge_task_path(challenge, task), as: :turbo_stream
        end.to change(ChallengeTask, :count).by(-1)
      end

      it "returns turbo stream updates" do
        delete admin_challenge_task_path(challenge, task), as: :turbo_stream

        expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
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
        delete admin_challenge_task_path(challenge, task), as: :turbo_stream

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
        delete admin_challenge_task_path(challenge, task), as: :turbo_stream

        expect(response.body).to include("Tarefa não encontrada")
      end
    end

    context "when the task belongs to another challenge from the same user" do
      let!(:challenge) { create(:challenge, user:) }
      let!(:other_challenge) { create(:challenge, user:) }
      let!(:task) { create(:challenge_task, challenge: other_challenge) }

      it "does not remove the task" do
        expect do
          delete admin_challenge_task_path(challenge, task)
        end.not_to change(ChallengeTask, :count)
      end

      it "shows not found" do
        delete admin_challenge_task_path(challenge, task), as: :turbo_stream

        expect(response.body).to include("Tarefa não encontrada")
      end
    end
  end
end
