class Category < ApplicationRecord
    has_many :expenses

    validates :name, presence: true, uniqueness: { case_sensitive: false }
    validates :auto_approve_limit, presence: true, numericality: { greater_than_or_equal_to: 0}

    scope :active, -> { where (active: true) }
end