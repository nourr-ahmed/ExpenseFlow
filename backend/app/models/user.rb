class User < ApplicationRecord
  has_secure_password

  belongs_to :team, optional: true
  has_many :expenses, foreign_key: :user_id
  has_many :notifications
  has_one :managed_team, class_name: "Team", foreign_key: :manager_id

  validates :name, presence: true
  validates :email, presence: true, 
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: %w[employee manager admin] }

  validates :team_id, presence: true, if: -> { role == "employee" }

  scope :active, -> { where(active: true) }

  def active_for_authentication?
    active?
  end
end