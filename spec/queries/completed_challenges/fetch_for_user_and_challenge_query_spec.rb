require "rails_helper"

RSpec.describe CompletedChallenges::FetchForUserAndChallengeQuery do
  describe ".query" do
    subject(:query) { described_class.query(user_id: user.id, challenge_id: challenge.id) }

    let(:user) { create(:user) }
    let(:challenge) { create(:challenge, status: "published", start_date: Date.current - 7.days, end_date: Date.current - 1.day) }

    context "when the user participated in the completed challenge" do
      let(:participant) { create(:participant, user:, challenge:) }
      let(:challenge_task) { create(:challenge_task, challenge:, points: 30, scheduled_on: Date.current - 2.days) }

      before do
        create(:checkin, participant:, challenge_task:)
      end

      it "returns the completed challenge item" do
        expect(query.data.fetch(:completed_challenge_item)).to have_attributes(challenge:, participant:, rank: 1, total_points: 30, active_days: 1)
      end

      it "returns the final ranking items" do
        expect(query.data.fetch(:ranking_items).first).to have_attributes(participant:, total_points: 30)
      end
    end

    context "when the challenge is still current" do
      let(:challenge) { create(:challenge, status: "published", start_date: Date.current - 1.day, end_date: Date.current) }

      before do
        create(:participant, user:, challenge:)
      end

      it "fails" do
        expect(query.success).to be(false)
      end
    end

    context "when the user did not participate in the challenge" do
      it "fails" do
        expect(query.success).to be(false)
      end
    end
  end
end
