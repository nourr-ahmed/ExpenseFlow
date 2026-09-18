module Api
  module V1
    class CategoriesController < ApplicationController
      before_action :set_category, only: [:update]

      def index
        categories = policy_scope(Category)
        render json: categories.map { |c| CategorySerializer.new(c).as_json }
      end

      def create
        @category = Category.new(category_params)
        authorize @category
        @category.save!
        render json: CategorySerializer.new(@category).as_json, status: :created
      end

      def update
        authorize @category
        @category.update!(category_params)
        render json: CategorySerializer.new(@category).as_json
      end

      private

      def set_category
        @category = Category.find(params[:id])
      end

      def category_params
        params.require(:category).permit(:name, :auto_approve_limit, :active)
      end
    end
  end
end