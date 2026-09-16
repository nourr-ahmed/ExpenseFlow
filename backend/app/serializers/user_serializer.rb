class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json
    {
      id: @user.id,
      id: @user.id,
      name: @user.name,
      email: @user.email,
      role: @user.role,
      active: @user.active,
      team: team_data
    }
  end

  private

  def team_data
    return nil unless @user.team
    {
      id: @user.team.id,
      name: @user.team.name
    }
  end
end