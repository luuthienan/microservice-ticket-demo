class ApplicationController < ActionController::API
  include Authentication

  rescue_from ApiError do |error|
    render_errors [{ message: error.message }], error.status
  end

  rescue_from ActiveRecord::RecordNotFound do
    render_errors [{ message: "Not Found" }], 404
  end

  # A write lost a race, e.g. a seller's edit against a reservation. Nothing was saved.
  rescue_from ActiveRecord::StaleObjectError do
    render_errors [{ message: "The record was changed by someone else, reload and try again" }], 409
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    errors = error.record.errors.map { |e| { message: e.full_message, field: e.attribute.to_s } }
    render_errors errors, 400
  end

  private

  # Renders the errors of a validator or service (anything ActiveModel::Errors-backed) as a 400.
  def render_validation_errors(model)
    errors = model.errors.map do |e|
      e.attribute == :base ? { message: e.message } : { message: e.full_message, field: e.attribute.to_s }
    end
    render_errors errors, 400
  end

  def render_errors(errors, status)
    render json: { errors: }, status:
  end
end
