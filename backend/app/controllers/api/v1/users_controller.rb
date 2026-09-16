module Api
  module V1
    class UsersController < ApplicationController
      def me 
        render json: UserSerializer.new(current_user).as_json, status: :ok
      end
    end
  end
end