import { useState } from "react";
import type { FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { ApiError } from "../api/client";

export function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await login(email, password);
      navigate("/expenses");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Something went wrong");
    } finally {
      setSubmitting(false);
    }
  }

  return (
  <div className="login-page">
        <form onSubmit={handleSubmit} className="login-card">
        <h1>ExpenseFlow</h1>
        {error && <p style={{ color: "red" }}>{error}</p>}
        <div>
            <label>Email</label>
            <input type="email" className="field" value={email} onChange={(e) => setEmail(e.target.value)} required />
        </div>
        <div>
            <label>Password</label>
            <input type="password" className="field" value={password} onChange={(e) => setPassword(e.target.value)} required />
        </div>
        <button type="submit" disabled={submitting} style={{ width: "100%" }}>
            {submitting ? "Signing in..." : "Sign in"}
        </button>
        </form>
    </div>
    );
}