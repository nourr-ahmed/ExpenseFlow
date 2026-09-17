module Api
  module V1
    class ExpensesController < ApplicationController
      before_action :set_expense, except: [:index, :create]
      before_action :authorize_expense, except: [:index, :create]

      rescue_from ExpenseTransitionService::InvalidTransitionError, with: :handle_invalid_transition

      def index
        expenses = policy_scope(Expense)
        render json: expenses.map {|e| ExpenseSerializer.new(e).as_json}
      end

      def show
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
        unless @expense.status == "draft"
          return render json: { error: "Only draft expenses can be deleted" }, status: :unprocessable_entity
        end
        @expense.destroy
        head :no_content
      end

      def submit
        ExpenseTransitionService.new(@expense, current_user).submit!
        render json: ExpenseSerializer.new(@expense.reload).as_json
      end

      def approve
        ExpenseTransitionService.new(@expense, current_user).approve!(comment: params[:comment])
        render json: ExpenseSerializer.new(@expense.reload).as_json
      end

      def reject
        if params[:comment].blank?
          return render json: { error: "Comment is required to reject an expense" }, status: :unprocessable_entity
        end
        ExpenseTransitionService.new(@expense, current_user).reject!(comment: params[:comment])
        render json: ExpenseSerializer.new(@expense.reload).as_json
      end

      def reimburse
        if params[:payment_reference].blank?
          return render json: { error: "Payment reference is required" }, status: :unprocessable_entity
        end
        ExpenseTransitionService.new(@expense, current_user).reimburse!(payment_reference: params[:payment_reference])
        render json: ExpenseSerializer.new(@expense.reload).as_json
      end

      def reopen
        ExpenseTransitionService.new(@expense, current_user).reopen!
        render json: ExpenseSerializer.new(@expense.reload).as_json
      end

      private

      def set_expense
        @expense = Expense.find(params[:id])
      end

      def authorize_expense
        authorize @expense
      end

      def expense_params
        params.require(:expense).permit(:title, :description, :amount, :category_id, :spent_on)
      end

      def handle_invalid_transition(exception)
        render json: { error: exception.message }, status: :unprocessable_entity
      end

    end
  end
end

