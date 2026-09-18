module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: [:show, :update]

      def me 
        render json: UserSerializer.new(current_user).as_json, status: :ok
      end

      def index
        authorize User, :index?
        users = policy_scope(User)
        render json: users.map { |u| UserSerializer.new(u).as_json }
      end

      def show
        authorize @user
        render json: UserSerializer.new(@user).as_json
      end

      def create
        @user = User.new(user_params)
        authorize @user
        @user.save!
        render json: UserSerializer.new(@user).as_json, status: :created
      end

      def update
        if deactivating?
          authorize @user, :deactivate?
        else
          authorize @user, :update?
        end
        @user.update!(user_params)
        render json: UserSerializer.new(@user).as_json
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(:name, :email, :password, :role, :team_id, :active)
      end

      def deactivating?
        user_params.key?(:active) && !ActiveModel::Type::Boolean.new.cast(user_params[:active])
      end
    end
  end
end