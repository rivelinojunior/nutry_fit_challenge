class ChallengeTask < ApplicationRecord
  belongs_to :challenge
  has_many :checkins, dependent: :destroy

  validates :name, :points, :scheduled_on, presence: true
  validates :points, numericality: { only_integer: true, greater_than: 0 }, allow_blank: true
  validate :allowed_end_time_after_allowed_start_time

  private

  def allowed_end_time_after_allowed_start_time
    return if allowed_start_time.blank?

    if allowed_end_time.blank?
      errors.add(:allowed_end_time, "can't be blank")
      return
    end

    return if allowed_end_time > allowed_start_time

    errors.add(:allowed_end_time, "must be greater than allowed start time")
  end
end
