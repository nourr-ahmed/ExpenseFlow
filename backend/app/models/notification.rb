class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :expense

  validates :message, presence: true
end