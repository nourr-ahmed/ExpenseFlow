import { BrowserRouter, Routes, Route, Navigate, Link } from "react-router-dom";
import { AuthProvider, useAuth } from "./context/AuthContext";
import { ProtectedRoute } from "./components/ProtectedRoute";
import { Login } from "./pages/Login";
import { ExpensesList } from "./pages/ExpensesList";
import { ExpenseForm } from "./pages/ExpenseForm";
import { ExpenseDetail } from "./pages/ExpenseDetail";
import { ReviewQueue } from "./pages/ReviewQueue";
import { AdminReport } from "./pages/AdminReport";

function Header() {
  const { user, logout } = useAuth();
  if (!user) return null;
  return (
    <div style={{ display: "flex", justifyContent: "space-between", padding: "0.5rem 1rem" }}>
      <div style={{ display: "flex", gap: "1rem" }}>
        <Link to="/expenses">Expenses</Link>
        {(user.role === "manager" || user.role === "admin") && (
          <Link to="/review-queue">Review Queue</Link>
        )}
        {user.role === "admin" && <Link to="/admin/report">Report</Link>}
      </div>
      <span>
        {user.name} ({user.role})
        <button onClick={logout} style={{ marginLeft: "0.5rem" }}>Log out</button>
      </span>
    </div>
  );
}

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Header />
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/expenses" element={<ProtectedRoute><ExpensesList /></ProtectedRoute>} />
          <Route path="/expenses/new" element={<ProtectedRoute><ExpenseForm /></ProtectedRoute>} />
          <Route path="/expenses/:id/edit" element={<ProtectedRoute><ExpenseForm /></ProtectedRoute>} />
          <Route path="/expenses/:id" element={<ProtectedRoute><ExpenseDetail /></ProtectedRoute>} />
          <Route path="/review-queue" element={<ProtectedRoute><ReviewQueue /></ProtectedRoute>} />
          <Route path="/admin/report" element={<ProtectedRoute><AdminReport /></ProtectedRoute>} />
          <Route path="*" element={<Navigate to="/expenses" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;