class ApplicationPolicy
  attr_reader :user, :record
  
  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve 
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end
  end

  private

  def admin?
    user.role == "admin"
  end

  def manager?
    user.role == "manager"
  end

  def employee?
    user.role == "employee"
  end

  def owner?(resource_user_id)
    user.id == resource_user_id
  end

end