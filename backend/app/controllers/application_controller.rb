class ApplicationController < ActionController::API
  include Pundit::Authorization
  include Pagy::Backend

  before_action :authenticate_request

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordInvalid, with: :render_validation_error

  private

  def authenticate_request
    header = request.headers["Authorization"]
    token = header&.split(" ")&.last

    if token.nil?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    decoded = JsonWebToken.decode(token)

    if decoded.nil?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    @current_user = User.active.find_by(id: decoded[:user_id])

    unless @current_user
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end
  end

  def current_user
    @current_user
  end

  def user_not_authorized
    render json: { error: "Forbidden" }, status: :forbidden
  end

  def render_validation_error(exception)
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end
end
