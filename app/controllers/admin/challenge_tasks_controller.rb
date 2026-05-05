module Admin
  class ChallengeTasksController < BaseController
    before_action :set_challenge

    def index
      prepare_view_state
    end

    def create
      result = Admin::GenerateChallengeTasksProcess.call(challenge_id: @challenge&.id, **challenge_task_params)

      case result
      in Solid::Success[type: :created]
        redirect_to admin_challenge_tasks_path, notice: "Tarefas geradas com sucesso."
      in Solid::Failure[type: :invalid_input]
        render_index_with_errors(result[:input].errors.full_messages)
      in Solid::Failure[type: :challenge_not_found | :already_started | :specific_date_out_of_range | :validation_failed]
        render_index_with_errors(result[:errors])
      end
    end

    def destroy
      return render_index_with_errors([ "Tarefa não encontrada." ]) unless task_belongs_to_challenge?

      result = Admin::RemoveChallengeTaskProcess.call(challenge_task_id: params[:id])

      case result
      in Solid::Success[type: :removed]
        redirect_to admin_challenge_tasks_path, notice: "Tarefa removida."
      in Solid::Failure[type: :invalid_input]
        render_index_with_errors(result[:input].errors.full_messages)
      in Solid::Failure[type: :challenge_task_not_found | :already_started]
        render_index_with_errors(result[:errors])
      end
    end

    def publish
      result = Admin::PublishChallengeProcess.call(challenge_id: @challenge&.id)

      case result
      in Solid::Success[type: :published]
        redirect_to admin_challenge_tasks_path, notice: "Desafio publicado."
      in Solid::Failure[type: :invalid_input]
        render_index_with_errors(result[:input].errors.full_messages)
      in Solid::Failure[type: :challenge_not_found]
        render_index_with_errors([ "Desafio não encontrado." ])
      in Solid::Failure[type: :already_published | :missing_challenge_code | :missing_tasks | :validation_failed]
        render_index_with_errors(result[:errors])
      end
    end

    private

    def set_challenge
      @challenge = current_user.challenges.order(created_at: :desc).first
    end

    def prepare_view_state(errors = [])
      @errors = errors
      @task_form = default_task_form.merge(submitted_task_form)
      @challenge_started = @challenge.present? && @challenge.start_date <= Date.current
      @tasks_by_date = @challenge ? @challenge.challenge_tasks.order(:scheduled_on, :created_at).group_by(&:scheduled_on) : {}
    end

    def submitted_task_form
      return {} unless params[:challenge_task].respond_to?(:permit!)

      params[:challenge_task].permit!.to_h
    end

    def default_task_form
      {
        "recurrence_type" => "daily",
        "weekdays" => [],
        "points" => 10
      }
    end

    def render_index_with_errors(errors)
      prepare_view_state(errors)
      render :index, status: :unprocessable_entity
    end

    def challenge_task_params
      task_params = params.expect(
        challenge_task: [
          :name,
          :description,
          :points,
          :start_time,
          :end_time,
          :recurrence_type,
          :specific_date,
          { weekdays: [] }
        ]
      )
      task_params[:weekdays] = selected_weekdays(task_params[:weekdays])
      task_params
    end

    def selected_weekdays(weekdays)
      return [] if weekdays.blank?

      weekdays.reject(&:blank?).map(&:to_i)
    end

    def task_belongs_to_challenge?
      @challenge.present? && @challenge.challenge_tasks.exists?(id: params[:id])
    end
  end
end
