class UserPolicy < ApplicationPolicy
  def index?
    admin? || manager?
  end

  def show?
    admin? || owner?(record.id) || manager_of_target?
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

  class Scope < Scope
    def resolve
      if user.role == "admin"
        scope.all
      elsif user.role == "manager"
        if user.managed_team
          scope.where(team_id: user.managed_team.id)
        else
          scope.none
        end
      else
        scope.none
      end
    end
  end

  private

  def manager_of_target?
    manager? && user.managed_team.present? && user.managed_team.id == record.team_id #nil case: true == true on admins or anyone w/ no team_id
  end
end