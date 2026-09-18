export interface Category {
  id: number;
  name: string;
  auto_approve_limit: number;
  active: boolean;
}

export interface HistoryEntry {
  from_status: string | null;
  to_status: string;
  comment: string | null;
  created_at: string;
  actor: { id?: number; name: string };
}

export interface Expense {
  id: number;
  title: string;
  description: string | null;
  amount: number;
  status: "draft" | "submitted" | "approved" | "rejected" | "reimbursed";
  spent_on: string;
  payment_reference: string | null;
  approved_at: string | null;
  reimbursed_at: string | null;
  category: Category;
  owner: {
    id: number;
    name: string;
    role: "employee" | "manager" | "admin";
    team: { id: number; name: string } | null;
  };
  created_at: string;
  updated_at: string;
  history: HistoryEntry[];
}

export interface Pagination {
  page: number;
  pages: number;
  count: number;
}

export interface ExpensesResponse {
  expenses: Expense[];
  pagination: Pagination;
}

export interface ReportRow {
  category: string;
  month: string; // "YYYY-MM"
  total_amount: number;
  count: number;
}

export interface Notification {
  id: number;
  message: string;
  read: boolean;
  expense_id: number;
  created_at: string;
}
