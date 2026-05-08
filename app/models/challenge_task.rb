class ChallengeTask < ApplicationRecord
  belongs_to :challenge
  has_many :checkins, dependent: :destroy

  validates :name, :points, :scheduled_on, presence: true
  validates :points, numericality: { only_integer: true, greater_than: 0 }, allow_blank: true
  validate :allowed_end_time_after_allowed_start_time
  validate :links_are_valid

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

  def links_are_valid
    return if links.blank?

    unless links.is_a?(Array)
      errors.add(:links, "must be a list")
      return
    end

    links.each do |link|
      validate_link(link)
    end
  end

  def validate_link(link)
    unless link.is_a?(Hash)
      errors.add(:links, "must include label and url")
      return
    end

    label = link[:label].presence || link["label"]
    url = link[:url].presence || link["url"]

    errors.add(:links, "label can't be blank") if label.blank?
    errors.add(:links, "url can't be blank") if url.blank?
    errors.add(:links, "url must start with http or https") if url.present? && !http_url?(url)
  end

  def http_url?(url)
    uri = URI.parse(url)

    uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end
end
