module Api
  module V1
    class ExpensesController < ApplicationController
      before_action :set_expense, only: [:show, :update, :destroy]

      def index
        expenses = policy_scope(Expense)
        render json: expenses.map {|e| ExpenseSerializer.new(e).as_json}
      end

      def show
        authorize @expense
        render json: ExpenseSerializer.new(@expense).as_json
      end

      def create
        expense = current_user.expenses.build(expense_params)
        authorize expense
        if expense.save
          render json: ExpenseSerializer.new(expense).as_json, status: :created
        else
          render json: { error: "Only draft expenses can be edited" }, status: :unprocessable_entity
        end
      end

      def update
        authorize @expense
        if @expense.status != "draft"
          return render json: { error: "Only draft expenses can be edited" }, status: :unprocessable_entity
        end
        if @expense.update(expense_params)
          render json: ExpenseSerializer.new(@expense).as_json
        else
          render json: { errors: @expense.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @expense
        unless @expense.status == "draft"
          return render json: { error: "Only draft expenses can be deleted" }, status: :unprocessable_entity
        end
        @expense.destroy
        head :no_content
      end


      private

      def set_expense
        @expense = Expense.find(params[:id])
      end

      def expense_params
        params.require(:expense).permit(:title, :description, :amount, :category_id, :spent_on)
      end

    end
  end
end

