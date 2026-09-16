class TeamPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin? || member_of_team? || manager_of_team?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def deactivate?
    admin? && !owner?(record.id)
  end

  private

  def member_of_team?
    user&.team_id == record.id
  end

  def manager_of_team?
    manager? && user.managed_team&.id == record.id
  end
end