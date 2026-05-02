class Participant < ApplicationRecord
  belongs_to :user
  belongs_to :challenge
  has_many :checkins, dependent: :destroy

  before_validation :set_joined_at

  validates :joined_at, presence: true
  validates :user_id, uniqueness: { scope: :challenge_id }

  private

  def set_joined_at
    self.joined_at ||= Time.current
  end
end
