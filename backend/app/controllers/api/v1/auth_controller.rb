module Api
    module V1
        class AuthController < ApplicationController
            skip_before_action :authenticate_request, only: [:login]

            def login
                user = User.active.find_by(email: params[:email].to_s.downcase)

                if user&.authenticate(params[:password])
                    token = JsonWebToken.encode(user_id: user.id)
                    render json: {
                        token: token,
                        user: UserSerializer.new(user).as_json
                    }, status: :ok
                else
                    render json: {
                        error: "Invalid email or password"
                    }, status: :unauthorized
                end
            end

            def logout
                render json: {
                        error: "Logged out successfully"
                    }, status: :ok
            end
        end
    end
end