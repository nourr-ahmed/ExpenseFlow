import { useState } from "react";
import type { FormEvent } from "react";
import { apiFetch, ApiError } from "../api/client";
import type { ReportRow } from "../types";

export function AdminReport() {
  const [status, setStatus] = useState("approved");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [rows, setRows] = useState<ReportRow[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    setRows(null);

    const params = new URLSearchParams({ status, from, to });

    try {
      const data = await apiFetch<ReportRow[]>(`/expenses/report?${params.toString()}`);
      setRows(data);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to load report");
    } finally {
      setLoading(false);
    }
  }

  const total = rows?.reduce((sum, r) => sum + r.total_amount, 0) ?? 0;

  return (
    <div>
      <h1>Report</h1>
      <form onSubmit={handleSubmit} style={{ display: "flex", gap: "1rem", alignItems: "end", marginBottom: "1rem" }}>
        <div>
          <label>Status</label><br />
          <select value={status} onChange={(e) => setStatus(e.target.value)}>
            <option value="approved">Approved</option>
            <option value="reimbursed">Reimbursed</option>
          </select>
        </div>
        <div>
          <label>From</label><br />
          <input type="date" value={from} onChange={(e) => setFrom(e.target.value)} required />
        </div>
        <div>
          <label>To</label><br />
          <input type="date" value={to} onChange={(e) => setTo(e.target.value)} required />
        </div>
        <button type="submit" disabled={loading}>{loading ? "Loading..." : "Run Report"}</button>
      </form>

      {error && <p style={{ color: "red" }}>{error}</p>}

      {rows && rows.length === 0 && <p>No data for this range.</p>}

      {rows && rows.length > 0 && (
        <>
          <table>
            <thead>
              <tr>
                <th>Category</th>
                <th>Month</th>
                <th>Total Amount</th>
                <th>Count</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r, i) => (
                <tr key={i}>
                  <td>{r.category}</td>
                  <td>{r.month}</td>
                  <td>{r.total_amount.toFixed(2)}</td>
                  <td>{r.count}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <p><strong>Grand total: {total.toFixed(2)}</strong></p>
        </>
      )}
    </div>
  );
}