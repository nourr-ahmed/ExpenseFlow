import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { apiFetch, ApiError } from "../api/client";
import type { Expense, Category } from "../types";

export function ExpenseForm() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();

  const [categories, setCategories] = useState<Category[]>([]);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [amount, setAmount] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [spentOn, setSpentOn] = useState("");
  const [errors, setErrors] = useState<string[]>([]);
  const [loading, setLoading] = useState(isEdit);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    apiFetch<Category[]>("/categories").then(setCategories).catch(() => {});
  }, []);

  // Only runs when editing — populates the form from the existing draft
  useEffect(() => {
    if (!isEdit) return;
    apiFetch<Expense>(`/expenses/${id}`)
      .then((e) => {
        setTitle(e.title);
        setDescription(e.description ?? "");
        setAmount(String(e.amount));
        setCategoryId(String(e.category.id));
        setSpentOn(e.spent_on);
      })
      .catch((err) => setErrors([err instanceof ApiError ? err.message : "Failed to load expense"]))
      .finally(() => setLoading(false));
  }, [id, isEdit]);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setErrors([]);
    setSubmitting(true);

    const payload = {
      expense: {
        title,
        description: description || null,
        amount: Number(amount),
        category_id: Number(categoryId),
        spent_on: spentOn,
      },
    };

    try {
      if (isEdit) {
        await apiFetch(`/expenses/${id}`, { method: "PATCH", body: JSON.stringify(payload) });
      } else {
        await apiFetch("/expenses", { method: "POST", body: JSON.stringify(payload) });
      }
      navigate("/expenses");
    } catch (err) {
      if (err instanceof ApiError && Array.isArray(err.body?.errors)) {
        setErrors(err.body.errors);
      } else {
        setErrors([err instanceof ApiError ? err.message : "Something went wrong"]);
      }
    } finally {
      setSubmitting(false);
    }
  }

  if (loading) return <p>Loading...</p>;

  return (
    <div>
      <Link to="/expenses">&larr; Back to list</Link>
      <h1>{isEdit ? "Edit Expense" : "New Expense"}</h1>
      {errors.length > 0 && (
        <ul style={{ color: "red" }}>
          {errors.map((msg, i) => <li key={i}>{msg}</li>)}
        </ul>
      )}
      <form onSubmit={handleSubmit}>
        <div className="full">
          <label>Title</label>
          <input value={title} onChange={(e) => setTitle(e.target.value)} required />
        </div>
        <div className="full">
          <label>Description</label>
          <textarea value={description} onChange={(e) => setDescription(e.target.value)} />
        </div>
        <div>
          <label>Amount</label>
          <input type="number" step="0.01" min="0.01" max="100000" value={amount} onChange={(e) => setAmount(e.target.value)} required />
        </div>
        <div> 
          <label>Category</label>
          <select value={categoryId} onChange={(e) => setCategoryId(e.target.value)} required>
            <option value="">Select a category</option>
            {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </div>
        <div>
          <label>Spent On</label>
          <input type="date" value={spentOn} onChange={(e) => setSpentOn(e.target.value)} required />
        </div>
        <button type="submit" disabled={submitting}>{submitting ? "Saving..." : "Save"}</button>
      </form>
    </div>
  );
}