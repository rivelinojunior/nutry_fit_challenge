# frozen_string_literal: true

class ApplicationQuery
  Response = Data.define(:success, :data, :errors)

  def self.query(**args) = new(**args).query

  def query = raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"

  private_class_method :new

  private

  def success(data:)
    Response.new(success: true, data:, errors: [])
  end

  def failure(errors:, data: nil)
    Response.new(success: false, data:, errors:)
  end
end
