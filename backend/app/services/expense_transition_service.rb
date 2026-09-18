class ExpenseTransitionService

  class InvalidTransitionError < StandardError; end

  def initialize(expense, actor)
    @expense = expense
    @actor = actor
  end

  def submit!
    transition!(from: "draft", to: "submitted")
    auto_approve_check
  end

  def approve!(comment: nil)
    transition!(from: "submitted", to: "approved", comment: comment)
  end

  def reject!(comment:)
    transition!(from: "submitted", to: "rejected", comment: comment)
  end

  def reimburse!(payment_reference:)
    transition!(from: "approved", to: "reimbursed", payment_reference: payment_reference)
  end

  def reopen!
    transition!(from: "rejected", to: "draft")
  end

  private

  def transition!(from:, to:, comment: nil, payment_reference: nil, actor: @actor)
    raise InvalidTransitionError, "Invalid transition: expense is #{@expense.status}, expected #{from}" if @expense.status != from

    ActiveRecord::Base.transaction do
      update_attrs = { status: to }
      update_attrs[:payment_reference] = payment_reference if payment_reference.present?
      update_attrs[:approved_at] = Time.current if to == "approved"
      update_attrs[:reimbursed_at] = Time.current if to == "reimbursed"
      @expense.update!(update_attrs)
      ExpenseHistory.create!(
        expense: @expense,
        from_status: from,
        to_status: to,
        actor_user_id: actor&.id,
        comment: comment
      )
      Notification.create(
        user: @expense.user,
        expense: @expense,
        message: "Your expense '#{@expense.title}' was #{to}."
      )
    end
  end

  def auto_approve_check
    transition!(from: "submitted", to: "approved", actor: nil) if @expense.amount <= @expense.category.auto_approve_limit
  end

end