module Admin
  class ChallengeTasksController < BaseController
    def create
      result = Admin::GenerateChallengeTasksProcess.call(challenge_id: params[:challenge_id], user_id: current_user.id, **challenge_task_params)

      case result
      in Solid::Success[type: :created]
        render_success("Tarefas geradas com sucesso.", result[:challenge])
      in Solid::Failure[type: :invalid_input]
        render_failure(result[:input].errors.full_messages, result[:challenge])
      in Solid::Failure[type: :challenge_not_found | :already_started | :specific_date_out_of_range | :validation_failed]
        render_failure(result[:errors], result[:challenge])
      end
    end

    def destroy
      result = Admin::RemoveChallengeTaskProcess.call(challenge_id: params[:challenge_id], challenge_task_id: params[:id], user_id: current_user.id)

      case result
      in Solid::Success[type: :removed]
        render_success("Tarefa removida.", result[:challenge])
      in Solid::Failure[type: :invalid_input]
        render_failure(result[:input].errors.full_messages, result[:challenge])
      in Solid::Failure[type: :challenge_task_not_found | :already_started]
        render_failure(result[:errors], result[:challenge])
      end
    end

    private

    def prepare_view_state(challenge:, task_form: default_task_form)
      @challenge = challenge
      @task_form = task_form
      @challenge_started = @challenge.present? && @challenge.start_date <= Date.current
      @tasks_by_date = @challenge ? @challenge.challenge_tasks.order(:scheduled_on, :created_at).group_by(&:scheduled_on) : {}
    end

    def submitted_task_form
      return default_task_form unless params.key?(:challenge_task)

      default_task_form.merge(params[:challenge_task].permit!.to_h)
    end

    def default_task_form
      {
        "recurrence_type" => "daily",
        "weekdays" => [],
        "points" => 10
      }
    end

    def render_success(message, challenge)
      prepare_view_state(challenge:)
      respond_to do |format|
        format.turbo_stream { render_task_stream(message:) }
        format.html { redirect_to admin_challenge_path(challenge), notice: message }
      end
    end

    def render_failure(errors, challenge)
      prepare_view_state(challenge:, task_form: submitted_task_form)
      respond_to do |format|
        format.turbo_stream { render_task_stream(errors:, status: :unprocessable_entity) }
        format.html { redirect_to admin_challenge_path(params[:challenge_id]), alert: errors.to_sentence }
      end
    end

    def render_task_stream(message: nil, errors: [], status: :ok)
      render :update, status:, locals: {
        challenge: @challenge,
        task_form: @task_form,
        challenge_started: @challenge_started,
        tasks_by_date: @tasks_by_date,
        message:,
        errors:
      }
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
  end
end
