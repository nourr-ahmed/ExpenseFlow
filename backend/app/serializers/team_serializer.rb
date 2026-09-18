class TeamSerializer
  def initialize(team)
    @team = team
  end

  def as_json
    {
      id: @team.id,
      name: @team.name,
      manager: manager_data
    }
  end

  private

  def manager_data
    { id: @team.manager.id, name: @team.manager.name, email: @team.manager.email }
  end
end