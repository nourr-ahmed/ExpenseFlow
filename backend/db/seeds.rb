# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Categories
travel = Category.create!(name: "Travel", auto_approve_limit: 200, active: true)
meals = Category.create!(name: "Meals", auto_approve_limit: 50, active: true)
supplies = Category.create!(name: "Supplies", auto_approve_limit: 100, active: true)

# Users
admin = User.create!(
  name: "Admin User",
  email: "admin@expenseflow.com",
  password: "password123",
  role: "admin"
)

manager = User.create!(
  name: "Manager User",
  email: "manager@expenseflow.com",
  password: "password123",
  role: "manager"
)

team = Team.create!(name: "Engineering", manager: manager)

employee = User.create!(
  name: "Employee User",
  email: "employee@expenseflow.com",
  password: "password123",
  role: "employee",
  team: team
)

employee2 = User.create!(
  name: "Employee2 User",
  email: "employee2@expenseflow.com",
  password: "password123",
  role: "employee",
  team: team
)

puts "Seeded: #{Category.count} categories, #{User.count} users, #{Team.count} team"