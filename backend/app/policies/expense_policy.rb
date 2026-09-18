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
    owner?(record.user_id) 
  end
  
  def approve?
    eligible_reviewer?
  end

  def reject?
    eligible_reviewer? 
  end

  def reimburse?
    admin? 
  end

  def reopen?
    owner?(record.user_id) 
  end

  def report?
    admin?
  end

  class Scope < Scope
    def resolve
      if user.role == "admin"
        scope.all 
      elsif user.role == "manager"
        team_members_ids = user.managed_team&.members&.pluck(:id) || []
        scope.where(user_id: team_members_ids + [user.id])
      else
        scope.where(user_id: user.id)
      end 
    end
  end

  private 
  
  def manager_of_owner?
    manager? && user.managed_team&.members&.pluck(:id)&.include?(record.user_id)
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

