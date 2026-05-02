class Participant < ApplicationRecord
  belongs_to :user
  belongs_to :challenge

  before_validation :set_joined_at

  validates :joined_at, presence: true
  validates :user_id, uniqueness: { scope: :challenge_id }

  private

  def set_joined_at
    self.joined_at ||= Time.current
  end
end
