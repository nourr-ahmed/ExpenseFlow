class Expense < ApplicationRecord
    belongs_to :user
    belongs_to :category
    has_many :expense_histories
    has_many :notifications

    STATUSES = %w[draft submitted approved rejected reimbursed].freeze

    validates :title, presence: true
    validates :amount, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100_000 }
    validates :spent_on, presence: true
    validates :status, inclusion: { in: STATUSES }
    validate :spent_on_within_valid_range
    validate :category_is_active

    private

    def spent_on_within_valid_range
        return unless spent_on
        if spent_on > Date.today
            errors.add(:spent_on, "cannot be in the future")
        elsif spent_on < Date.today - 90
            errors.add(:spent_on, "cannot be more than 90 days ago")
        end
    end

    def category_is_active
        if category.present? && !category.active?
            errors.add(:category, "must be active")
        end
    end

end