class Checkin < ApplicationRecord
  belongs_to :participant
  belongs_to :challenge_task

  validates :checked_at, presence: true
  validates :challenge_task_id, uniqueness: { scope: :participant_id }

  before_validation :set_checked_at, on: :create

  private

  def set_checked_at
    self.checked_at ||= Time.current
  end
end
