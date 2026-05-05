class Challenge < ApplicationRecord
  STATUSES = %w[draft published].freeze
  CHALLENGE_CODE_LENGTH = 6
  CHALLENGE_CODE_FORMAT = /\A[A-Z0-9]{6,8}\z/

  belongs_to :user
  has_many :challenge_tasks, dependent: :destroy
  has_many :participants, dependent: :destroy
  has_many :users, through: :participants

  attr_readonly :challenge_code

  before_validation :assign_challenge_code, on: :create

  validates :name, :start_date, :end_date, :timezone, :status, :challenge_code, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :challenge_code, uniqueness: true, format: { with: CHALLENGE_CODE_FORMAT }
  validate :end_date_not_before_start_date
  validate :challenge_code_cannot_change, on: :update

  def self.generate_unique_challenge_code
    loop do
      code = SecureRandom.alphanumeric(CHALLENGE_CODE_LENGTH).upcase

      return code unless exists?(challenge_code: code)
    end
  end

  private

  def assign_challenge_code
    self.challenge_code ||= self.class.generate_unique_challenge_code
  end

  def end_date_not_before_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "must be greater than or equal to start date")
  end

  def challenge_code_cannot_change
    return unless will_save_change_to_challenge_code?

    errors.add(:challenge_code, "can't be changed")
  end
end
