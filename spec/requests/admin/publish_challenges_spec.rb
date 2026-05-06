require "rails_helper"

RSpec.describe "Admin publish challenges" do
  let(:user) { create(:user, :admin) }

  before do
    sign_in user
  end

  describe "PATCH /admin/publish_challenge/:id" do
    context "when at least one task exists" do
      let!(:challenge) { create(:challenge, user:) }

      before do
        create(:challenge_task, challenge:)
      end

      it "redirects to the task list" do
        patch admin_publish_challenge_path(challenge)

        expect(response).to redirect_to(admin_challenge_tasks_path(challenge))
      end

      it "publishes the challenge" do
        patch admin_publish_challenge_path(challenge)

        expect(challenge.reload.status).to eq("published")
      end

      it "passes the route id to the publish process" do
        allow(Admin::PublishChallengeProcess).to receive(:call).and_call_original

        patch admin_publish_challenge_path(challenge)

        expect(Admin::PublishChallengeProcess).to have_received(:call).with(challenge_id: challenge.to_param)
      end
    end

    context "when no task exists" do
      let!(:challenge) { create(:challenge, user:) }

      it "redirects to the task list" do
        patch admin_publish_challenge_path(challenge)

        expect(response).to redirect_to(admin_challenge_tasks_path(challenge))
      end

      it "sets the process error as a flash alert" do
        patch admin_publish_challenge_path(challenge)

        expect(flash[:alert]).to eq("Challenge must have tasks before publishing")
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

      it "redirects to the task list" do
        patch admin_publish_challenge_path(challenge)

        expect(response).to redirect_to(admin_challenge_tasks_path(challenge))
      end

      it "sets the process error as a flash alert" do
        patch admin_publish_challenge_path(challenge)

        expect(flash[:alert]).to eq("Challenge must have a code before publishing")
      end
    end

    context "when the challenge does not exist" do
      it "redirects to the task list for the requested id" do
        patch admin_publish_challenge_path(0)

        expect(response).to redirect_to(admin_challenge_tasks_path(0))
      end

      it "sets a not found flash alert" do
        patch admin_publish_challenge_path(0)

        expect(flash[:alert]).to eq("Desafio não encontrado.")
      end
    end
  end

  describe "PUT /admin/publish_challenge/:id" do
    let!(:challenge) { create(:challenge, user:) }

    before do
      create(:challenge_task, challenge:)
    end

    it "publishes the challenge" do
      put admin_publish_challenge_path(challenge)

      expect(challenge.reload.status).to eq("published")
    end
  end
end
