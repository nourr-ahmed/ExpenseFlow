module Api
  module V1
    class NotificationsController < ApplicationController
      def index
        notifications = current_user.notifications.order(created_at: :desc)
        render json: notifications.map { |n| NotificationSerializer.new(n).as_json }
      end

      def mark_read
        notification = current_user.notifications.find(params[:id])
        notification.update!(read: true)
        render json: NotificationSerializer.new(notification).as_json
      end
    end
  end
end