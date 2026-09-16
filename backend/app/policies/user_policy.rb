class UserPolicy < ApplicationPolicy
  def index?
    admin? || manager?
  end

  def show?
    admin? || owner?(record.id)
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
end