# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChallengeTasks::FetchForTodayQuery do
  include ActiveSupport::Testing::TimeHelpers

  describe ".query" do
    subject(:result) { described_class.query(challenge_id:, participant_id:) }

    let(:current_time) { Time.utc(2026, 5, 3, 15, 0, 0) }
    let(:challenge) do
      create(
        :challenge,
        start_date: today,
        end_date: today + 6.days,
        timezone:
      )
    end
    let(:timezone) { "America/Sao_Paulo" }
    let(:today) { current_time.in_time_zone(timezone).to_date }
    let(:participant) { create(:participant, challenge:) }
    let(:challenge_id) { challenge.id }
    let(:participant_id) { participant.id }

    around do |example|
      travel_to(current_time) { example.run }
    end

    context "when the inputs are valid" do
      let!(:checked_task) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: today,
          allowed_start_time: Time.zone.parse("13:00"),
          allowed_end_time: Time.zone.parse("20:00")
        )
      end
      let!(:available_task_without_window) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: today,
          allowed_start_time: nil,
          allowed_end_time: nil
        )
      end
      let!(:available_task_with_window) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: today,
          allowed_start_time: Time.zone.parse("08:00"),
          allowed_end_time: Time.zone.parse("20:00")
        )
      end
      let!(:available_task_at_start_time) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: today,
          allowed_start_time: Time.zone.parse("12:00"),
          allowed_end_time: Time.zone.parse("20:00")
        )
      end
      let!(:available_task_at_end_time) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: today,
          allowed_start_time: Time.zone.parse("08:00"),
          allowed_end_time: Time.zone.parse("12:00")
        )
      end
      let!(:future_task) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: today,
          allowed_start_time: Time.zone.parse("13:00"),
          allowed_end_time: Time.zone.parse("20:00")
        )
      end
      let!(:expired_task) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: today,
          allowed_start_time: Time.zone.parse("08:00"),
          allowed_end_time: Time.zone.parse("11:00")
        )
      end
      let!(:other_day_task) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: today + 1.day
        )
      end

      before do
        create(:checkin, participant:, challenge_task: checked_task)
      end

      it "returns success" do
        expect(result.success).to be(true)
      end

      it "returns only tasks scheduled for today" do
        expect(result.data.map(&:challenge_task)).to eq(
          [
            checked_task,
            available_task_without_window,
            available_task_with_window,
            available_task_at_start_time,
            available_task_at_end_time,
            future_task,
            expired_task
          ]
        )
      end

      it "marks checked tasks" do
        expect(task_for(checked_task).checked).to be(true)
      end

      it "marks unchecked tasks" do
        expect(task_for(available_task_with_window).checked).to be(false)
      end

      it "sets checked state for checked tasks" do
        expect(task_for(checked_task).state).to eq("checked")
      end

      it "sets available state for tasks without time window" do
        expect(task_for(available_task_without_window).state).to eq("available")
      end

      it "sets available state for tasks inside the time window" do
        expect(task_for(available_task_with_window).state).to eq("available")
      end

      it "sets available state for tasks at the start time" do
        expect(task_for(available_task_at_start_time).state).to eq("available")
      end

      it "sets available state for tasks at the end time" do
        expect(task_for(available_task_at_end_time).state).to eq("available")
      end

      it "sets future state for tasks before the time window" do
        expect(task_for(future_task).state).to eq("future")
      end

      it "sets expired state for tasks after the time window" do
        expect(task_for(expired_task).state).to eq("expired")
      end

      it "does not create checkins" do
        expect { result }.not_to change(Checkin, :count)
      end
    end

    context "when the challenge timezone changes the current date" do
      let(:timezone) { "Asia/Tokyo" }
      let!(:today_task) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: today
        )
      end
      let!(:server_day_task) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: current_time.to_date
        )
      end

      it "uses the challenge timezone to select today's tasks" do
        expect(result.data.map(&:challenge_task)).to contain_exactly(today_task)
      end
    end

    context "when the challenge timezone changes the current time" do
      let(:timezone) { "Asia/Tokyo" }
      let!(:today_task) do
        create(
          :challenge_task,
          challenge:,
          scheduled_on: today,
          allowed_start_time: Time.zone.parse("00:00"),
          allowed_end_time: Time.zone.parse("00:30")
        )
      end

      it "uses the challenge timezone to calculate task state" do
        expect(task_for(today_task).state).to eq("available")
      end
    end

    context "when the challenge does not exist" do
      let(:challenge_id) { 0 }

      it "returns failure" do
        expect(result.success).to be(false)
      end

      it "returns a clear error" do
        expect(result.errors).to contain_exactly("Challenge not found")
      end
    end

    context "when the participant does not exist" do
      let(:participant_id) { 0 }

      it "returns failure" do
        expect(result.success).to be(false)
      end

      it "returns a clear error" do
        expect(result.errors).to contain_exactly("Participant not found")
      end
    end

    context "when the participant does not belong to the challenge" do
      let(:other_challenge) { create(:challenge) }
      let(:participant) { create(:participant, challenge: other_challenge) }

      it "returns failure" do
        expect(result.success).to be(false)
      end

      it "returns a clear error" do
        expect(result.errors).to contain_exactly("Participant does not belong to challenge")
      end
    end

    def task_for(challenge_task)
      result.data.find { |task| task.challenge_task == challenge_task }
    end
  end
end
