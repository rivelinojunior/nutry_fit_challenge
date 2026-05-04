# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rankings::FetchRankingQuery do
  describe ".query" do
    subject(:result) { described_class.query(challenge_id:) }

    let(:challenge) { create(:challenge) }
    let(:challenge_id) { challenge.id }

    context "when the challenge exists" do
      let(:participant_with_more_active_days) { create(:participant, challenge:) }
      let(:participant_with_later_checkin) { create(:participant, challenge:) }
      let(:participant_with_earlier_checkin) { create(:participant, challenge:) }
      let(:participant_with_fewer_points) { create(:participant, challenge:) }
      let(:participant_without_challenge_checkin) { create(:participant, challenge:) }
      let(:other_challenge) { create(:challenge) }
      let(:other_participant) { create(:participant, challenge: other_challenge) }

      let(:first_day) { challenge.start_date }
      let(:second_day) { challenge.start_date + 1.day }
      let(:third_day) { challenge.start_date + 2.days }
      let(:latest_checkin_at) { Time.zone.local(2026, 5, 3, 12, 0, 0) }

      let(:high_value_task) { create(:challenge_task, challenge:, points: 10, scheduled_on: first_day) }
      let(:medium_value_task) { create(:challenge_task, challenge:, points: 6, scheduled_on: second_day) }
      let(:low_value_task) { create(:challenge_task, challenge:, points: 4, scheduled_on: third_day) }
      let(:same_day_task) { create(:challenge_task, challenge:, points: 4, scheduled_on: first_day) }
      let(:other_challenge_task) { create(:challenge_task, challenge: other_challenge, points: 50, scheduled_on: first_day) }
      let(:more_active_days_item) do
        result.data.find { |item| item.participant == participant_with_more_active_days }
      end
      let(:later_checkin_item) do
        result.data.find { |item| item.participant == participant_with_later_checkin }
      end
      let(:without_challenge_checkin_item) do
        result.data.find { |item| item.participant == participant_without_challenge_checkin }
      end

      before do
        create(:checkin, participant: participant_with_more_active_days, challenge_task: high_value_task, checked_at: latest_checkin_at - 4.days)
        create(:checkin, participant: participant_with_more_active_days, challenge_task: medium_value_task, checked_at: latest_checkin_at - 3.days)
        create(:checkin, participant: participant_with_more_active_days, challenge_task: low_value_task, checked_at: latest_checkin_at - 2.days)

        create(:checkin, participant: participant_with_later_checkin, challenge_task: high_value_task, checked_at: latest_checkin_at - 4.days)
        create(:checkin, participant: participant_with_later_checkin, challenge_task: medium_value_task, checked_at: latest_checkin_at - 3.days)
        create(:checkin, participant: participant_with_later_checkin, challenge_task: same_day_task, checked_at: latest_checkin_at)

        create(:checkin, participant: participant_with_earlier_checkin, challenge_task: high_value_task, checked_at: latest_checkin_at - 4.days)
        create(:checkin, participant: participant_with_earlier_checkin, challenge_task: medium_value_task, checked_at: latest_checkin_at - 3.days)
        create(:checkin, participant: participant_with_earlier_checkin, challenge_task: same_day_task, checked_at: latest_checkin_at - 1.day)

        create(:checkin, participant: participant_with_fewer_points, challenge_task: high_value_task, checked_at: latest_checkin_at + 1.day)
        create(:checkin, participant: participant_without_challenge_checkin, challenge_task: other_challenge_task, checked_at: latest_checkin_at + 2.days)
        create(:checkin, participant: other_participant, challenge_task: other_challenge_task, checked_at: latest_checkin_at + 3.days)
      end

      it "returns success" do
        expect(result.success).to be(true)
      end

      it "includes every participant from the challenge" do
        expect(result.data.map(&:participant)).to contain_exactly(
          participant_with_more_active_days,
          participant_with_later_checkin,
          participant_with_earlier_checkin,
          participant_with_fewer_points,
          participant_without_challenge_checkin
        )
      end

      it "does not include participants from other challenges" do
        expect(result.data.map(&:participant)).not_to include(other_participant)
      end

      it "calculates total points from checked challenge tasks" do
        expect(more_active_days_item.total_points).to eq(20)
      end

      it "calculates active days from distinct checked task dates" do
        expect(later_checkin_item.active_days).to eq(2)
      end

      it "calculates the latest checkin from checked challenge tasks" do
        expect(later_checkin_item.last_checkin).to be_within(1.second).of(latest_checkin_at)
      end

      it "uses zero metrics for participants without challenge checkins" do
        expect(without_challenge_checkin_item).to have_attributes(
          total_points: 0,
          active_days: 0,
          last_checkin: nil
        )
      end

      it "orders by total points, active days, and last checkin descending" do
        expect(result.data.map(&:participant)).to eq(
          [
            participant_with_more_active_days,
            participant_with_later_checkin,
            participant_with_earlier_checkin,
            participant_with_fewer_points,
            participant_without_challenge_checkin
          ]
        )
      end

      it "does not create checkins" do
        expect { result }.not_to change(Checkin, :count)
      end

      it "does not create participants" do
        expect { result }.not_to change(Participant, :count)
      end
    end

    context "when the challenge has no participants" do
      it "returns an empty ranking" do
        expect(result.data).to eq([])
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
  end
end
