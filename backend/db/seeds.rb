# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.

# Categories
travel = Category.find_or_create_by!(name: "Travel") do |c|
  c.auto_approve_limit = 200
  c.active = true
end

meals = Category.find_or_create_by!(name: "Meals") do |c|
  c.auto_approve_limit = 50
  c.active = true
end

supplies = Category.find_or_create_by!(name: "Supplies") do |c|
  c.auto_approve_limit = 100
  c.active = true
end

# Users — two admins, so "an admin's own expense is reviewed by a DIFFERENT admin" (spec 3.2) is actually testable
admin1 = User.find_or_create_by!(email: "admin@expenseflow.com") do |u|
  u.name = "Admin One"
  u.password = "password123"
  u.role = "admin"
end

admin2 = User.find_or_create_by!(email: "admin2@expenseflow.com") do |u|
  u.name = "Admin Two"
  u.password = "password123"
  u.role = "admin"
end

manager = User.find_or_create_by!(email: "manager@expenseflow.com") do |u|
  u.name = "Manager User"
  u.password = "password123"
  u.role = "manager"
end

team = Team.find_or_create_by!(name: "Engineering") do |t|
  t.manager = manager
end

employee = User.find_or_create_by!(email: "employee@expenseflow.com") do |u|
  u.name = "Employee User"
  u.password = "password123"
  u.role = "employee"
  u.team = team
end

employee2 = User.find_or_create_by!(email: "employee2@expenseflow.com") do |u|
  u.name = "Employee2 User"
  u.password = "password123"
  u.role = "employee"
  u.team = team
end

puts "Seeded: #{Category.count} categories, #{User.count} users, #{Team.count} team"

# Demo expenses — one per role/state scenario from the spec, driven through the real
# ExpenseTransitionService (not by setting `status:` directly) so history + notifications
# are generated exactly the way they would be in production. Guarded so re-running
# `db:seed` doesn't try to re-transition already-transitioned expenses (which would raise
# InvalidTransitionError, since e.g. an already-submitted expense can't be submitted again).
if Expense.where(user: [employee, employee2, manager, admin1]).none?
  # 1. Plain draft — untouched, owned by employee
  Expense.create!(
    title: "Team lunch (draft)",
    amount: 30.00,
    category: meals,
    user: employee,
    spent_on: Date.today - 5.days
  )

  # 2. Auto-approved on submit — under Travel's 200 limit
  auto_approved = Expense.create!(
    title: "Coffee with client",
    amount: 15.00,
    category: travel,
    user: employee,
    spent_on: Date.today - 10.days
  )
  ExpenseTransitionService.new(auto_approved, employee).submit!

  # 3. Submitted, pending manager review — over Travel's 200 limit
  pending_manager = Expense.create!(
    title: "Conference ticket",
    amount: 250.00,
    category: travel,
    user: employee,
    spent_on: Date.today - 20.days
  )
  ExpenseTransitionService.new(pending_manager, employee).submit!

  # 4. Approved by manager — over Supplies' 100 limit
  approved_by_manager = Expense.create!(
    title: "Team offsite venue",
    amount: 300.00,
    category: supplies,
    user: employee2,
    spent_on: Date.today - 15.days
  )
  ExpenseTransitionService.new(approved_by_manager, employee2).submit!
  ExpenseTransitionService.new(approved_by_manager, manager).approve!(comment: "Looks good")

  # 5. Rejected by manager
  rejected = Expense.create!(
    title: "Personal laptop bag",
    amount: 120.00,
    category: supplies,
    user: employee2,
    spent_on: Date.today - 18.days
  )
  ExpenseTransitionService.new(rejected, employee2).submit!
  ExpenseTransitionService.new(rejected, manager).reject!(comment: "Not a business expense")

  # 6. Full cycle: submitted → rejected → reopened back to draft (shows a 3-row history)
  reopened = Expense.create!(
    title: "Taxi to airport",
    amount: 250.00,
    category: travel,
    user: employee,
    spent_on: Date.today - 25.days
  )
  ExpenseTransitionService.new(reopened, employee).submit!
  ExpenseTransitionService.new(reopened, manager).reject!(comment: "Needs a receipt")
  ExpenseTransitionService.new(reopened, employee).reopen!

  # 7. Fully reimbursed — submitted → approved (manager) → reimbursed (admin)
  reimbursed = Expense.create!(
    title: "Hotel for conference",
    amount: 300.00,
    category: supplies,
    user: employee,
    spent_on: Date.today - 30.days
  )
  ExpenseTransitionService.new(reimbursed, employee).submit!
  ExpenseTransitionService.new(reimbursed, manager).approve!(comment: "Approved")
  ExpenseTransitionService.new(reimbursed, admin1).reimburse!(payment_reference: "PMT-SEED-001")

  # 8. Manager's OWN expense, submitted — must wait for an admin, never the manager themself
  manager_own = Expense.create!(
    title: "Team building dinner",
    amount: 80.00,
    category: meals,
    user: manager,
    spent_on: Date.today - 12.days
  )
  ExpenseTransitionService.new(manager_own, manager).submit!

  # 9. Admin's OWN expense, approved by the OTHER admin — proves "different admin" rule
  admin_own = Expense.create!(
    title: "Client dinner (admin travel)",
    amount: 250.00,
    category: travel,
    user: admin1,
    spent_on: Date.today - 8.days
  )
  ExpenseTransitionService.new(admin_own, admin1).submit!
  ExpenseTransitionService.new(admin_own, admin2).approve!(comment: "Approved by second admin")

  puts "Seeded #{Expense.count} demo expenses covering draft/submitted/approved/rejected/reimbursed across every role."
else
  puts "Demo expenses already exist, skipping."
end