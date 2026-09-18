import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { apiFetch, ApiError } from "../api/client";
import { useAuth } from "../context/AuthContext";
import type { Expense, ExpensesResponse, Category } from "../types";
import { OwnerBadge } from "../components/OwnerBadge";

const STATUSES = ["draft", "submitted", "approved", "rejected", "reimbursed"];

function titleForRole(role: string) {
  if (role === "admin") return "All Expenses";
  if (role === "manager") return "Team Expenses";
  return "My Expenses";
}

export function ExpensesList() {
  const { user } = useAuth();
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [pagination, setPagination] = useState<{
    page: number;
    pages: number;
  } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const [status, setStatus] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [sort, setSort] = useState("spent_on");
  const [direction, setDirection] = useState("desc");
  const [page, setPage] = useState(1);
  const [onlyMine, setOnlyMine] = useState(false);
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");

  const showOwnerColumn = user?.role !== "employee";

  useEffect(() => {
    apiFetch<Category[]>("/categories")
      .then(setCategories)
      .catch(() => {});
  }, []);

  useEffect(() => {
    setLoading(true);
    setError(null);

    const params = new URLSearchParams();
    if (status) params.set("status", status);
    if (categoryId) params.set("category_id", categoryId);
    if (onlyMine && user) params.set("user_id", String(user.id));
    if (dateFrom) params.set("from", dateFrom);
    if (dateTo) params.set("to", dateTo);
    params.set("sort", sort);
    params.set("direction", direction);
    params.set("page", String(page));

    apiFetch<ExpensesResponse>(`/expenses?${params.toString()}`)
      .then((data) => {
        setExpenses(data.expenses);
        setPagination(data.pagination);
      })
      .catch((err) =>
        setError(
          err instanceof ApiError ? err.message : "Failed to load expenses",
        ),
      )
      .finally(() => setLoading(false));
  }, [status, categoryId, sort, direction, page, onlyMine, user, dateFrom, dateTo]);

  return (
    <div>
      <h1>{user ? titleForRole(user.role) : "Expenses"}</h1>
      <Link to="/expenses/new" className="btn">+ New Expense</Link>

      {/* <div
        style={{
          display: "flex",
          gap: "1rem",
          margin: "1rem 0",
          alignItems: "center",
        }}
      >
        <select
          value={status}
          onChange={(e) => {
            setStatus(e.target.value);
            setPage(1);
          }}
        >
          <option value="">All statuses</option>
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>

        <select
          value={categoryId}
          onChange={(e) => {
            setCategoryId(e.target.value);
            setPage(1);
          }}
        >
          <option value="">All categories</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>

        <input
            type="date"
            value={dateFrom}
            onChange={(e) => {
                setDateFrom(e.target.value);
                setPage(1);
            }}
        />
        <input
        type="date"
        value={dateTo}
        min={dateFrom || undefined}
        onChange={(e) => {
            setDateTo(e.target.value);
            setPage(1);
        }}
        />

        <select value={sort} onChange={(e) => setSort(e.target.value)}>
          <option value="spent_on">Sort: Spent on</option>
          <option value="amount">Sort: Amount</option>
          <option value="created_at">Sort: Created</option>
        </select>

        <select
          value={direction}
          onChange={(e) => setDirection(e.target.value)}
        >
          <option value="desc">Descending</option>
          <option value="asc">Ascending</option>
        </select>

        {showOwnerColumn && (
          <label>
            <input
              type="checkbox"
              checked={onlyMine}
              onChange={(e) => {
                setOnlyMine(e.target.checked);
                setPage(1);
              }}
            />{" "}
            Only mine
          </label>
        )}
      </div> */}

      <div
  style={{
    display: "flex",
    gap: "1rem",
    margin: "1rem 0",
    alignItems: "center",
    flexWrap: "wrap",
  }}
>
  <select
    value={status}
    onChange={(e) => {
      setStatus(e.target.value);
      setPage(1);
    }}
  >
    <option value="">All statuses</option>
    {STATUSES.map((s) => (
      <option key={s} value={s}>
        {s}
      </option>
    ))}
  </select>

  <select
    value={categoryId}
    onChange={(e) => {
      setCategoryId(e.target.value);
      setPage(1);
    }}
  >
    <option value="">All categories</option>
    {categories.map((c) => (
      <option key={c.id} value={c.id}>
        {c.name}
      </option>
    ))}
  </select>

  <select value={sort} onChange={(e) => setSort(e.target.value)}>
    <option value="spent_on">Sort: Spent on</option>
    <option value="amount">Sort: Amount</option>
    <option value="created_at">Sort: Created</option>
  </select>

  <select value={direction} onChange={(e) => setDirection(e.target.value)}>
    <option value="desc">Descending</option>
    <option value="asc">Ascending</option>
  </select>

  <label style={{ display: "flex", gap: "0.4rem", alignItems: "center" }}>
    From
    <input
      type="date"
      value={dateFrom}
      onChange={(e) => {
        const value = e.target.value;
        setDateFrom(value);
        // if "From" is set but "To" is still empty, default "To" to today
        // so picking just one date behaves like "from that date until now",
        // instead of silently filtering nothing (backend only filters when
        // both from and to are present).
        if (value && !dateTo) {
          setDateTo(new Date().toISOString().slice(0, 10));
        }
        setPage(1);
      }}
    />
  </label>

  <label style={{ display: "flex", gap: "0.4rem", alignItems: "center" }}>
    To
    <input
      type="date"
      value={dateTo}
      min={dateFrom || undefined}
      disabled={!dateFrom}
      title={!dateFrom ? "Pick a \"From\" date first" : undefined}
      onChange={(e) => {
        setDateTo(e.target.value);
        setPage(1);
      }}
    />
  </label>

  {dateFrom && dateTo && (
    <span style={{ fontSize: "0.85rem", color: "#555" }}>
      Filtering: {dateFrom} → {dateTo}{" "}
      <button
        type="button"
        onClick={() => {
          setDateFrom("");
          setDateTo("");
          setPage(1);
        }}
      >
        Clear dates
      </button>
    </span>
  )}

  {showOwnerColumn && (
    <label>
      <input
        type="checkbox"
        checked={onlyMine}
        onChange={(e) => {
          setOnlyMine(e.target.checked);
          setPage(1);
        }}
      />{" "}
      Only mine
    </label>
  )}
</div>

      {error && <p style={{ color: "red" }}>{error}</p>}
      {loading && <p>Loading...</p>}

      {!loading && !error && (
        <table>
          <thead>
            <tr>
              <th>Title</th>
              {showOwnerColumn && <th>Owner</th>}
              <th>Category</th>
              <th>Amount</th>
              <th>Spent On</th>
              <th>Created</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {expenses.map((e) => (
              <tr key={e.id}>
                <td>
                  <Link to={`/expenses/${e.id}`}>{e.title}</Link>
                </td>
                {showOwnerColumn && (
                <td><OwnerBadge name={e.owner.name} role={e.owner.role} team={e.owner.team} /></td>
                )}
                <td>{e.category.name}</td>
                <td>{e.amount}</td>
                <td>{e.spent_on}</td>
                <td>{e.created_at.slice(0, 10)}</td>
                <td>{e.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      {pagination && (
        <div style={{ display: "flex", gap: "0.5rem", marginTop: "1rem" }}>
          <button disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
            Prev
          </button>
          <span>
            Page {pagination.page} of {pagination.pages || 1}
          </span>
          <button
            disabled={page >= pagination.pages}
            onClick={() => setPage((p) => p + 1)}
          >
            Next
          </button>
        </div>
      )}
    </div>
  );
}
