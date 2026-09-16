class ApplicationController < ActionController::API
  before_action :authenticate_request

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
end
