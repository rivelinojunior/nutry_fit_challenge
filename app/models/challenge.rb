class Challenge < ApplicationRecord
  STATUSES = %w[draft published].freeze

  belongs_to :user
  has_many :challenge_tasks, dependent: :destroy
  has_many :participants, dependent: :destroy
  has_many :users, through: :participants

  validates :name, :start_date, :end_date, :timezone, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :end_date_not_before_start_date

  private

  def end_date_not_before_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "must be greater than or equal to start date")
  end
end
