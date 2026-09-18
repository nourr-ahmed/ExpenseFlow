import { useEffect, useState } from "react";
import { useNavigate, useParams, Link } from "react-router-dom";
import { apiFetch, ApiError } from "../api/client";
import { useAuth } from "../context/AuthContext";
import type { Expense } from "../types";
import { OwnerBadge } from "../components/OwnerBadge";

export function ExpenseDetail() {
  const { id } = useParams();
  const { user } = useAuth();
  const navigate = useNavigate();

  const [expense, setExpense] = useState<Expense | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [acting, setActing] = useState(false);

  const [rejectComment, setRejectComment] = useState("");
  const [approveComment, setApproveComment] = useState("");
  const [paymentReference, setPaymentReference] = useState("");
  const [showRejectForm, setShowRejectForm] = useState(false);
  const [showReimburseForm, setShowReimburseForm] = useState(false);

  function load() {
    setLoading(true);
    apiFetch<Expense>(`/expenses/${id}`)
      .then(setExpense)
      .catch((err) => setError(err instanceof ApiError ? err.message : "Failed to load expense"))
      .finally(() => setLoading(false));
  }

  useEffect(load, [id]);

  async function runAction(path: string, body?: object) {
    setActing(true);
    setError(null);
    try {
      await apiFetch(`/expenses/${id}/${path}`, {
        method: "POST",
        body: body ? JSON.stringify(body) : undefined,
      });
      load();
      setShowRejectForm(false);
      setShowReimburseForm(false);
      setRejectComment("");
      setApproveComment("");
      setPaymentReference("");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Action failed");
    } finally {
      setActing(false);
    }
  }

  async function handleDelete() {
    if (!confirm("Delete this draft expense?")) return;
    setActing(true);
    try {
      await apiFetch(`/expenses/${id}`, { method: "DELETE" });
      navigate("/expenses");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Delete failed");
      setActing(false);
    }
  }

  if (loading) return <p>Loading...</p>;
  if (error && !expense) return <p style={{ color: "red" }}>{error}</p>;
  if (!expense || !user) return null;

  const isOwner = user.id === expense.owner.id;
  const canEdit = isOwner && expense.status === "draft";
  const canDelete = isOwner && expense.status === "draft";
  const canSubmit = isOwner && expense.status === "draft";
  const canReopen = isOwner && expense.status === "rejected";
  const canReview = !isOwner && (user.role === "manager" || user.role === "admin") && expense.status === "submitted";
  const canReimburse = user.role === "admin" && expense.status === "approved";

  return (
    <div>
      <Link to="/expenses">&larr; Back to list</Link>
      <h1>{expense.title}</h1>
      {error && <p style={{ color: "red" }}>{error}</p>}

      <dl>
        <dt>Status</dt><dd>{expense.status}</dd>
        <dt>Owner</dt>
        <dd><OwnerBadge name={expense.owner.name} role={expense.owner.role} team={expense.owner.team} /></dd>
        <dt>Category</dt><dd>{expense.category.name}</dd>
        <dt>Amount</dt><dd>{expense.amount}</dd>
        <dt>Spent On</dt><dd>{expense.spent_on}</dd>
        <dt>Description</dt><dd>{expense.description || "—"}</dd>
        {expense.payment_reference && (<><dt>Payment Reference</dt><dd>{expense.payment_reference}</dd></>)}
        {expense.approved_at && (<><dt>Approved At</dt><dd>{expense.approved_at.slice(0, 10)}</dd></>)}
        {expense.reimbursed_at && (<><dt>Reimbursed At</dt><dd>{expense.reimbursed_at.slice(0, 10)}</dd></>)}
      </dl>

      <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap", margin: "1rem 0" }}>
        {canEdit && <Link to={`/expenses/${id}/edit`}>Edit</Link>}
        {canDelete && <button disabled={acting} onClick={handleDelete}>Delete</button>}
        {canSubmit && <button disabled={acting} onClick={() => runAction("submit")}>Submit</button>}
        {canReopen && <button disabled={acting} onClick={() => runAction("reopen")}>Reopen</button>}

        {canReview && !showRejectForm && (
        <>
            <div>
            <label>Approve comment (optional): </label>
            <input value={approveComment} onChange={(e) => setApproveComment(e.target.value)} />
            </div>
            <button disabled={acting} onClick={() => runAction("approve", approveComment ? { comment: approveComment } : undefined)}>
            Approve
            </button>
            <button disabled={acting} onClick={() => setShowRejectForm(true)}>Reject</button>
        </>
        )}

        {canReimburse && !showReimburseForm && (
          <button disabled={acting} onClick={() => setShowReimburseForm(true)}>Mark Reimbursed</button>
        )}
      </div>


      {showRejectForm && (
        <div style={{ marginBottom: "1rem" }}>
          <label>Rejection comment (required): </label>
          <input value={rejectComment} onChange={(e) => setRejectComment(e.target.value)} />
          <button
            disabled={acting || !rejectComment.trim()}
            onClick={() => runAction("reject", { comment: rejectComment })}
          >
            Confirm Reject
          </button>
          <button onClick={() => setShowRejectForm(false)}>Cancel</button>
        </div>
      )}

      {showReimburseForm && (
        <div style={{ marginBottom: "1rem" }}>
          <label>Payment reference (required): </label>
          <input value={paymentReference} onChange={(e) => setPaymentReference(e.target.value)} />
          <button
            disabled={acting || !paymentReference.trim()}
            onClick={() => runAction("reimburse", { payment_reference: paymentReference })}
          >
            Confirm Reimburse
          </button>
          <button onClick={() => setShowReimburseForm(false)}>Cancel</button>
        </div>
      )}

      <h2>History</h2>
      <ul>
        {expense.history.map((h, i) => (
          <li key={i}>
            {h.created_at.slice(0, 10)} — {h.from_status ?? "created"} → {h.to_status} by {h.actor.name}
            {h.comment && ` — "${h.comment}"`}
          </li>
        ))}
      </ul>
    </div>
  );
}