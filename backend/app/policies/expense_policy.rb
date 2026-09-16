class ExpensePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    owner?(record.user_id) || manager_of_owner? || admin?
  end

  def create?
    true
  end

  def update?
    owner?(record.user_id) && record.status == "draft"
  end

  def destroy?
    owner?(record.user_id) && record.status == "draft"
  end

  def submit?
    owner?(record.user_id) && record.status == "draft"
  end
  
  def approve?
    eligible_reviewer? && record.status == "submitted"
  end

  def reject?
    eligible_reviewer? && record.status == "submitted"
  end

  def reimburse?
    admin? && record.status == "approved"
  end

  def reopen?
    owner?(record.user_id) && record.status == "rejected"
  end


  private 
  
  def manager_of_owner?
    manager? && user.managed_team&.members&.include?(record.user_id)
  end

  def eligible_reviewer?
    return false if owner?(record.user_id)
    case record.user.role
    when "employee"
      manager? && manager_of_owner?
    when "manager", "admin"
      admin?
    end
  end

end

