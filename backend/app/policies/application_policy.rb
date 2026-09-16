class ApplicationPolicy
  attr_reader :user, :record
  
  def Initialize(user, record)
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