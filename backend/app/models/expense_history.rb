class ExpenseHistory < ApplicationRecord
    belongs_to :expense
    belongs_to :actor_user, class_name: "User", optional: true #system

    validates :to_status, presence: true 
    validate :comment_required_for_rejection

    private

    def comment_required_for_rejection
        if to_status == "rejected" && comment.blank?
            errors.add(:comment, "is required when rejecting an expense")
        end
    end
end