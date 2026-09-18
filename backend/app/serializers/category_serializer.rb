class CategorySerializer
  def initialize(category)
    @category = category
  end

  def as_json
    {
      id: @category.id,
      name: @category.name,
      auto_approve_limit: @category.auto_approve_limit.to_f,
      active: @category.active
    }
  end
end