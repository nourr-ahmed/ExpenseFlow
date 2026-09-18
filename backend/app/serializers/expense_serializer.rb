class ExpenseSerializer
  def initialize(expense)
    @expense = expense
  end

  def as_json
    {
      id: @expense.id,
      title: @expense.title,
      description: @expense.description,
      amount: @expense.amount,
      status: @expense.status,
      payment_reference: @expense.payment_reference,
      spent_on: @expense.spent_on,
      approved_at: @expense.approved_at,
      reimbursed_at: @expense.reimbursed_at,
      created_at: @expense.created_at,
      updated_at: @expense.updated_at,
      category: category_data,
      owner: owner_data,
      history: history_data
    }
  end

  private

  def category_data
    {
      id: @expense.category.id,
      name: @expense.category.name,
      auto_approve_limit: @expense.category.auto_approve_limit
    }
  end

  def owner_data 
    {
      id: @expense.user.id,
      name: @expense.user.name,
      role: @expense.user.role,
      team: team_data
    }
  end

  def history_data
    @expense.expense_histories.order(:created_at).map do |h|
      {
        from_status: h.from_status,
        to_status: h.to_status,
        comment: h.comment,
        created_at: h.created_at,
        actor: actor_data(h)
      }
    end
  end

  def actor_data(history)
    if history.actor_user
      {
        id: history.actor_user.id,
        name: history.actor_user.name
      }
    else 
      {
        name: "system"
      }
    end
  end

  def team_data
    return nil unless @expense.user.team
    { id: @expense.user.team.id, name: @expense.user.team.name }
  end

end