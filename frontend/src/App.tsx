import { BrowserRouter, Routes, Route, Navigate, Link, NavLink } from "react-router-dom";
import { AuthProvider, useAuth } from "./context/AuthContext";
import { ProtectedRoute } from "./components/ProtectedRoute";
import { Login } from "./pages/Login";
import { ExpensesList } from "./pages/ExpensesList";
import { ExpenseForm } from "./pages/ExpenseForm";
import { ExpenseDetail } from "./pages/ExpenseDetail";
import { ReviewQueue } from "./pages/ReviewQueue";
import { AdminReport } from "./pages/AdminReport";
import { NotificationsBell } from "./components/NotificationsBell";


function Header() {
  const { user, logout } = useAuth();
  if (!user) return null;
  return (
    <div className="app-header">
      <nav>
        <NavLink to="/expenses" className={({ isActive }) => isActive ? "active" : undefined}>
          Expenses
        </NavLink>
        {(user.role === "manager" || user.role === "admin") && (
          <NavLink to="/review-queue" className={({ isActive }) => isActive ? "active" : undefined}>
            Review Queue
          </NavLink>
        )}
        {user.role === "admin" && (
          <NavLink to="/admin/report" className={({ isActive }) => isActive ? "active" : undefined}>
            Report
          </NavLink>
        )}
      </nav>
      <span>
        {user.name} ({user.role})
        <NotificationsBell />
        <button onClick={logout} style={{ marginLeft: "0.75rem" }}>Log out</button>
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