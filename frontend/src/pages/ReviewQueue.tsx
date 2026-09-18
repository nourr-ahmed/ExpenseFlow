import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { apiFetch, ApiError } from "../api/client";
import { OwnerBadge } from "../components/OwnerBadge";
import type { Expense } from "../types";

export function ReviewQueue() {
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiFetch<Expense[]>("/expenses/review_queue")
      .then(setExpenses)
      .catch((err) => setError(err instanceof ApiError ? err.message : "Failed to load review queue"))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <h1>Review Queue</h1>
      <p>Submitted expenses waiting for your decision.</p>

      {error && <p style={{ color: "red" }}>{error}</p>}
      {loading && <p>Loading...</p>}
      {!loading && !error && expenses.length === 0 && <p>Nothing to review right now.</p>}

      {!loading && !error && expenses.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Title</th>
              <th>Owner</th>
              <th>Category</th>
              <th>Amount</th>
              <th>Spent On</th>
            </tr>
          </thead>
          <tbody>
            {expenses.map((e) => (
              <tr key={e.id}>
                <td><Link to={`/expenses/${e.id}`}>{e.title}</Link></td>
                <td><OwnerBadge name={e.owner.name} role={e.owner.role} team={e.owner.team} /></td>
                <td>{e.category.name}</td>
                <td>{e.amount}</td>
                <td>{e.spent_on}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}