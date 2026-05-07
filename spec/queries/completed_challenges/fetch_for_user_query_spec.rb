require "rails_helper"

RSpec.describe CompletedChallenges::FetchForUserQuery do
  describe ".query" do
    subject(:query) { described_class.query(user_id: user.id) }

    let(:user) { create(:user) }

    context "when the user has completed challenges" do
      let(:challenge) { create(:challenge, status: "published", start_date: Date.current - 7.days, end_date: Date.current - 1.day) }
      let(:participant) { create(:participant, user:, challenge:) }
      let(:challenge_task) { create(:challenge_task, challenge:, points: 10, scheduled_on: Date.current - 2.days) }

      before do
        create(:checkin, participant:, challenge_task:)
      end

      it "returns the completed challenge item" do
        expect(query.data.first).to have_attributes(challenge:, participant:, rank: 1, total_points: 10, active_days: 1)
      end
    end

    context "when the user has current challenges" do
      before do
        challenge = create(:challenge, status: "published", start_date: Date.current - 1.day, end_date: Date.current)
        create(:participant, user:, challenge:)
      end

      it "does not return current challenges" do
        expect(query.data).to be_empty
      end
    end

    context "when another user has completed challenges" do
      before do
        challenge = create(:challenge, status: "published", start_date: Date.current - 7.days, end_date: Date.current - 1.day)
        create(:participant, challenge:)
      end

      it "does not return other users' challenges" do
        expect(query.data).to be_empty
      end
    end
  end
end
