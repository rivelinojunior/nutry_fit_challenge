# Controller Request Specs

Use request specs for controller behavior. Keep specs focused on observable HTTP
behavior and side effects, not implementation details that belong in process
specs.

## HTML Request Spec

```ruby
require "rails_helper"

RSpec.describe "Admin challenges", type: :request do
  let(:user) { create(:user) }

  describe "POST /admin/challenges" do
    subject(:request) { post admin_challenges_path, params: params }

    context "when the user is not authenticated" do
      let(:params) { { challenge: { name: "Desafio" } } }

      it "redirects to sign in" do
        request

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when the params are valid" do
      let(:params) do
        {
          challenge: {
            name: "Desafio",
            description: "Básico bem feito",
            start_date: Date.current.next_week,
            end_date: Date.current.next_week + 21.days,
            timezone: "America/Sao_Paulo"
          }
        }
      end

      before { sign_in user }

      it "creates a challenge" do
        expect { request }.to change(Challenge, :count).by(1)
      end
    end

    context "when the params are invalid" do
      let(:params) { { challenge: { name: "" } } }

      before { sign_in user }

      it "returns unprocessable entity" do
        request

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
```

## Process Result Handling Spec

When the controller delegates to a process, test representative process result
branches. Prefer using the real process for full-stack behavior. Stub only when
forcing rare branches would require duplicating process setup that is already
covered by process specs.

```ruby
RSpec.describe "Checkins", type: :request do
  let(:user) { create(:user) }
  let(:challenge_task) { create(:challenge_task) }

  describe "POST /challenge_tasks/:challenge_task_id/checkins" do
    subject(:request) { post challenge_task_checkins_path(challenge_task), params: params }

    let(:params) { {} }

    before { sign_in user }

    context "when the task can be checked in" do
      it "creates a checkin" do
        expect { request }.to change(Checkin, :count).by(1)
      end
    end

    context "when the user already checked in" do
      before { create(:checkin, user: user, challenge_task: challenge_task) }

      it "does not create another checkin" do
        expect { request }.not_to change(Checkin, :count)
      end
    end
  end
end
```

## Turbo Request Spec

```ruby
RSpec.describe "Checkins", type: :request do
  let(:user) { create(:user) }
  let(:challenge_task) { create(:challenge_task) }

  describe "POST /challenge_tasks/:challenge_task_id/checkins" do
    before { sign_in user }

    it "returns a turbo stream response" do
      post challenge_task_checkins_path(challenge_task),
        headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
```

## Checklist

- Use `describe "VERB /path"` or a human route name for request specs.
- Use `subject(:request)` for the HTTP call.
- Keep contexts condition-focused: "when", "with", or "without".
- Prefer one expectation per example to match project RSpec conventions.
- Assert the exact redirect, status, flash, rendered content, or database change.
- Cover unauthenticated access for protected endpoints.
- Cover one example per controller-handled process failure branch.
