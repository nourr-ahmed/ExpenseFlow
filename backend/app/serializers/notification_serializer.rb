class NotificationSerializer
  def initialize(notification)
    @notification = notification
  end

  def as_json
    {
      id: @notification.id,
      message: @notification.message,
      read: @notification.read,
      expense_id: @notification.expense_id,
      created_at: @notification.created_at,
    }
  end
end