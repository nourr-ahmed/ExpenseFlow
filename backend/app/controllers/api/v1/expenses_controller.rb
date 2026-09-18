module Api
  module V1
    class ExpensesController < ApplicationController
      before_action :set_expense, except: [:index, :create, :review_queue, :report]
      before_action :authorize_expense, except: [:index, :create, :review_queue, :report]

      rescue_from ExpenseTransitionService::InvalidTransitionError, with: :handle_invalid_transition

      ALLOWED_SORT_COLUMNS = %w[spent_on amount created_at].freeze

      def index
        expenses = policy_scope(Expense)

        if params[:status].present?
          unless Expense::STATUSES.include?(params[:status])
            render json: { error: "Invalid status: #{params[:status]}" }, status: :unprocessable_entity 
            return
          end
          expenses = expenses.where(status: params[:status])
        end

        expenses = expenses.where(category_id: params[:category_id]) if params[:category_id].present?

        if params[:from].present? && params[:to].present?
          begin
            from_date = Date.parse(params[:from])
            to_date = Date.parse(params[:to])
          rescue ArgumentError
            render json: { error: "from and to must be valid dates (e.g. 2026-08-01)" }, status: :unprocessable_entity
            return
          end

          if from_date > to_date
            render json: { error: "from must be before or equal to to" }, status: :unprocessable_entity
            return
          end

          expenses = expenses.where(spent_on: from_date..to_date)
        end

        sort_column = ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "spent_on"
        sort_direction = params[:direction] == "asc" ? "asc" : "desc"

        expenses = expenses.order(sort_column => sort_direction)

        pagy, expenses = pagy(expenses, items: params[:per_page] || 20, overflow: :empty_page)

        render json: {
          expenses: expenses.map {|e| ExpenseSerializer.new(e).as_json},
          pagination: {page: pagy.page, pages: pagy.pages, count: pagy.count}
        }
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

      def review_queue
        submitted = Expense.where(status: "submitted").includes(:user, :category)
        expenses = submitted.select { |e| ExpensePolicy.new(current_user, e).approve? }
        render json: expenses.map { |e| ExpenseSerializer.new(e).as_json }
      end

      def report
        authorize Expense, :report?
        status = params[:status]

        unless %w[approved reimbursed].include?(status)
          render json: { error: "status is required and must be 'approved' or 'reimbursed'" }, status: :unprocessable_entity
          return
        end

        begin
          from_date = Date.parse(params[:from].to_s)
          to_date = Date.parse(params[:to].to_s)
        rescue ArgumentError, TypeError
          render json: { error: "from and to are required and must be valid dates (e.g. 2026-08-01)" }, status: :unprocessable_entity
          return
        end

        if from_date > to_date
          render json: { error: "from must be before or equal to to" }, status: :unprocessable_entity
          return
        end

        date_column = status == "approved" ? "approved_at" : "reimbursed_at"
        month_expr = Arel.sql("DATE_TRUNC('month', #{date_column})")

        rows = Expense
          .where(status: status)
          .where("#{date_column} BETWEEN ? AND ?", from_date, to_date)
          .joins(:category)
          .group("categories.name", month_expr)
          .order(month_expr)
          .select(
            "categories.name AS category_name",
            Arel.sql("#{month_expr} AS month"),
            Arel.sql("SUM(expenses.amount) AS total_amount"),
            Arel.sql("COUNT(expenses.id) AS expense_count")
          )

        data = rows.map do |r|
          {
            category: r.category_name,
            month: r.month.strftime("%Y-%m"),
            total_amount: r.total_amount.to_f,
            count: r.expense_count
          }
        end

        render json: data
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

