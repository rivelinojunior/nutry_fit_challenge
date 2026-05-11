require "rails_helper"

RSpec.describe "Participants" do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /join" do
    it "renders successfully" do
      get join_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the join title" do
      get join_path

      expect(response.body).to include("Entrar em um desafio")
    end

    it "renders the challenge code field" do
      get join_path

      expect(response.body).to include("Código do desafio")
    end

    it "renders the authenticated menu button" do
      get join_path

      expect(response.body).to include("Abrir menu")
    end

    it "renders the find challenge menu link" do
      get join_path

      document = Nokogiri::HTML(response.body)
      link = document.at_css("a[href='/join']")

      expect(link.text.squish).to eq("Encontrar desafio")
    end

    it "does not render the admin menu link" do
      get join_path

      document = Nokogiri::HTML(response.body)

      expect(document.at_css("a[href='#{admin_challenges_path}']")).to be_nil
      expect(response.body).not_to include("Administração")
    end

    context "when the user is an admin" do
      let(:user) { create(:user, :admin) }

      it "renders the admin menu link" do
        get join_path

        document = Nokogiri::HTML(response.body)
        link = document.at_css("a[href='#{admin_challenges_path}']")

        expect(link.text.squish).to eq("Administração")
      end
    end

    it "renders the authenticated install prompt container" do
      get join_path

      document = Nokogiri::HTML(response.body)

      expect(document.at_css("[data-controller='install-prompt']")).to be_present
      expect(response.body).to include("Instale o Nutry.fit")
    end
  end

  describe "GET /" do
    context "when the user is not signed in" do
      before do
        sign_out user
      end

      it "redirects to sign in" do
        get root_path

        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not set an alert" do
        get root_path

        expect(flash[:alert]).to be_nil
      end

      it "does not render the install prompt on the sign in screen" do
        get new_user_session_path

        document = Nokogiri::HTML(response.body)

        expect(document.at_css("[data-controller='install-prompt']")).to be_nil
        expect(response.body).not_to include("Instale o Nutry.fit")
      end
    end

    context "when the user is not participating in a challenge" do
      it "redirects to the join screen" do
        get root_path

        expect(response).to redirect_to(join_path)
      end
    end

    context "when the user is participating in a challenge" do
      let(:challenge) { create(:challenge, status: "published", start_date: Date.current) }
      let(:participant) { create(:participant, user:, challenge:) }

      before do
        participant
      end

      it "renders the participant dashboard" do
        get root_path

        expect(response.body).to include(challenge.name)
      end

      it "links the menu challenge item to the selected participant" do
        get root_path

        expect(response.body).to include("href=\"/?challenge_id=#{challenge.id}&amp;participant_id=#{participant.id}\"")
      end
    end

    context "when the user also has a completed challenge joined later" do
      let(:current_challenge) do
        create(
          :challenge,
          name: "Desafio de Movimento",
          status: "published",
          start_date: Date.current,
          end_date: Date.current + 6.days
        )
      end
      let(:completed_challenge) do
        create(
          :challenge,
          name: "Desafio Antigo",
          status: "published",
          start_date: Date.current - 14.days,
          end_date: Date.current - 1.day
        )
      end

      before do
        create(:participant, user:, challenge: current_challenge, joined_at: 2.days.ago)
        create(:participant, user:, challenge: completed_challenge, joined_at: 1.day.ago)
      end

      it "renders the current challenge dashboard" do
        get root_path

        expect(response.body).to include("Desafio de Movimento")
      end
    end

    context "when the user's challenge has not started" do
      let(:challenge) { create(:challenge, status: "published", start_date: Date.current + 1.day) }
      let(:participant) { create(:participant, user:, challenge:) }

      before do
        participant
      end

      it "redirects into the participant dashboard flow" do
        get root_path

        expect(response).to redirect_to(challenge_participant_waiting_room_path(challenge, participant))
      end
    end

    it "renders the join screen after following the fallback redirect" do
      get root_path
      follow_redirect!

      expect(response.body).to include("Entrar em um desafio")
    end
  end

  describe "POST /join" do
    let(:challenge) { create(:challenge, challenge_code: "ABC123", status: "published", start_date: Date.current + 1.day) }

    it "creates a participant by challenge code" do
      expect do
        post join_path, params: { challenge_code: challenge.challenge_code }
      end.to change(Participant, :count).by(1)
    end

    it "redirects to the waiting room" do
      post join_path, params: { challenge_code: challenge.challenge_code }

      expect(response).to redirect_to(challenge_participant_waiting_room_path(challenge, Participant.last))
    end

    it "looks up codes case insensitively" do
      expect do
        post join_path, params: { challenge_code: " #{challenge.challenge_code.downcase} " }
      end.to change(Participant, :count).by(1)
    end

    context "when the challenge code is invalid" do
      it "renders a clear inline error" do
        post join_path, params: { challenge_code: "NOPE12" }

        expect(response.body).to include("Desafio não encontrado")
      end

      it "returns unprocessable entity" do
        post join_path, params: { challenge_code: "NOPE12" }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when the challenge is not published" do
      let(:challenge) { create(:challenge, challenge_code: "ABC123", status: "draft", start_date: Date.current + 1.day) }

      it "renders a clear inline error" do
        post join_path, params: { challenge_code: challenge.challenge_code }

        expect(response.body).to include("Desafio indisponível")
      end
    end

    context "when the challenge already started" do
      let(:challenge) { create(:challenge, challenge_code: "ABC123", status: "published", start_date: Date.current) }

      it "does not create a participant" do
        expect do
          post join_path, params: { challenge_code: challenge.challenge_code }
        end.not_to change(Participant, :count)
      end

      it "renders a clear inline error" do
        post join_path, params: { challenge_code: challenge.challenge_code }

        expect(response.body).to include("Desafio já começou")
      end
    end

    context "when the user already joined" do
      let!(:participant) { create(:participant, user:, challenge:) }

      it "does not create a participant" do
        expect do
          post join_path, params: { challenge_code: challenge.challenge_code }
        end.not_to change(Participant, :count)
      end

      it "redirects to the waiting room" do
        post join_path, params: { challenge_code: challenge.challenge_code }

        expect(response).to redirect_to(challenge_participant_waiting_room_path(challenge, participant))
      end
    end

    context "when the started challenge was already joined" do
      let(:challenge) { create(:challenge, challenge_code: "ABC123", status: "published", start_date: Date.current) }
      let!(:participant) { create(:participant, user:, challenge:) }

      it "redirects to the dashboard" do
        post join_path, params: { challenge_code: challenge.challenge_code }

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /challenges/:challenge_id/participants/:participant_id/waiting_room" do
    let(:challenge) do
      create(
        :challenge,
        name: "Desafio Maio",
        description: "Complete tarefas em comunidade.",
        status: "published",
        start_date: Date.current + 3.days
      )
    end
    let(:participant) { create(:participant, user:, challenge:) }

    it "renders successfully" do
      get challenge_participant_waiting_room_path(challenge, participant)

      expect(response).to have_http_status(:ok)
    end

    it "renders the authenticated menu button" do
      get challenge_participant_waiting_room_path(challenge, participant)

      expect(response.body).to include("Abrir menu")
    end

    it "renders the challenge name" do
      get challenge_participant_waiting_room_path(challenge, participant)

      expect(response.body).to include("Desafio Maio")
    end

    it "renders the challenge description" do
      get challenge_participant_waiting_room_path(challenge, participant)

      expect(response.body).to include("Complete tarefas em comunidade.")
    end

    it "renders the days remaining message" do
      get challenge_participant_waiting_room_path(challenge, participant)

      expect(response.body).to include("Faltam 3 dias")
    end

    it "renders the waiting message" do
      get challenge_participant_waiting_room_path(challenge, participant)

      expect(response.body).to include("As tarefas serão liberadas quando a data de início chegar.")
    end

    context "when the challenge already started" do
      let(:challenge) { create(:challenge, status: "published", start_date: Date.current) }

      it "redirects to the dashboard" do
        get challenge_participant_waiting_room_path(challenge, participant)

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the participant belongs to another user" do
      let(:participant) { create(:participant, challenge:) }

      it "returns not found" do
        get challenge_participant_waiting_room_path(challenge, participant)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET / dashboard" do
    let(:current_time) { Time.zone.local(2026, 5, 6, 12, 0, 0) }
    let(:challenge) do
      create(
        :challenge,
        name: "Desafio Maio",
        status: "published",
        start_date: Date.current,
        end_date: Date.current + 6.days
      )
    end
    let(:participant) { create(:participant, user:, challenge:) }
    let!(:available_task) do
      create(
        :challenge_task,
        challenge:,
        name: "Registrar água",
        points: 5,
        scheduled_on: Date.current,
        allowed_start_time: nil,
        allowed_end_time: nil,
        links: [
          { "label" => "Grupo do WhatsApp", "url" => "https://chat.example.com/grupo" }
        ]
      )
    end
    let!(:checked_task) do
      create(
        :challenge_task,
        challenge:,
        name: "Caminhada",
        points: 10,
        scheduled_on: Date.current,
        allowed_start_time: nil,
        allowed_end_time: nil
      )
    end
    let!(:future_task) do
      create(
        :challenge_task,
        challenge:,
        name: "Sono",
        points: 8,
        scheduled_on: Date.current,
        allowed_start_time: Time.zone.parse("18:00"),
        allowed_end_time: Time.zone.parse("23:00")
      )
    end
    let!(:expired_task) do
      create(
        :challenge_task,
        challenge:,
        name: "Alongamento",
        points: 4,
        scheduled_on: Date.current,
        allowed_start_time: Time.zone.parse("06:00"),
        allowed_end_time: Time.zone.parse("08:00")
      )
    end

    around do |example|
      travel_to(current_time) { example.run }
    end

    before do
      create(:checkin, participant:, challenge_task: checked_task, checked_at: current_time)
    end

    it "renders successfully" do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the challenge name" do
      get root_path

      expect(response.body).to include("Desafio Maio")
    end

    it "renders today's task names" do
      get root_path

      expect(response.body).to include("Registrar água", "Caminhada", "Sono", "Alongamento")
    end

    it "renders the available task action" do
      get root_path

      expect(response.body).to include("Concluir")
    end

    it "renders the checked task state" do
      get root_path

      expect(response.body).to include("Feita")
    end

    it "renders the future task state" do
      get root_path

      expect(response.body).to include("Em breve")
    end

    it "renders the expired task state" do
      get root_path

      expect(response.body).to include("Expirada")
    end

    it "renders task groups in state order" do
      get root_path

      expect(response.body).to match(/Registrar água.*Sono.*Caminhada.*Alongamento/m)
    end

    it "renders today's task link labels" do
      get root_path

      expect(response.body).to include("Grupo do WhatsApp")
    end

    it "renders today's task link urls" do
      get root_path

      expect(response.body).to include('href="https://chat.example.com/grupo"')
    end

    it "renders today's task links to open in a new tab" do
      get root_path

      expect(response.body).to include('target="_blank"')
    end

    it "renders the participant total points" do
      get root_path

      expect(response.body).to include("10")
    end

    context "when the challenge has not started" do
      let(:challenge) { create(:challenge, status: "published", start_date: Date.current + 1.day) }

      it "redirects to the waiting room" do
        get root_path

        expect(response).to redirect_to(challenge_participant_waiting_room_path(challenge, participant))
      end
    end
  end

  describe "POST /participants/:participant_id/checkins" do
    let(:current_time) { Time.zone.local(2026, 5, 6, 12, 0, 0) }
    let(:challenge) do
      create(
        :challenge,
        status: "published",
        start_date: Date.current,
        end_date: Date.current + 6.days
      )
    end
    let(:participant) { create(:participant, user:, challenge:) }
    let(:challenge_task) do
      create(
        :challenge_task,
        challenge:,
        scheduled_on: Date.current,
        allowed_start_time: nil,
        allowed_end_time: nil
      )
    end

    around do |example|
      travel_to(current_time) { example.run }
    end

    it "creates a checkin" do
      expect do
        post participant_checkins_path(participant), params: { challenge_task_id: challenge_task.id }
      end.to change(Checkin, :count).by(1)
    end

    it "redirects to the dashboard" do
      post participant_checkins_path(participant), params: { challenge_task_id: challenge_task.id }

      expect(response).to redirect_to(root_path)
    end

    context "when the task is already checked" do
      before do
        create(:checkin, participant:, challenge_task:)
      end

      it "does not create another checkin" do
        expect do
          post participant_checkins_path(participant), params: { challenge_task_id: challenge_task.id }
        end.not_to change(Checkin, :count)
      end
    end

    context "when the task is outside the allowed window" do
      let(:challenge_task) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: Date.current,
          allowed_start_time: Time.zone.parse("18:00"),
          allowed_end_time: Time.zone.parse("23:00")
        )
      end

      it "does not create a checkin" do
        expect do
          post participant_checkins_path(participant), params: { challenge_task_id: challenge_task.id }
        end.not_to change(Checkin, :count)
      end
    end

    context "when the participant belongs to another user" do
      let(:participant) { create(:participant, challenge:) }

      it "returns not found" do
        post participant_checkins_path(participant), params: { challenge_task_id: challenge_task.id }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
