import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { apiFetch } from "../api/client";
import type { Notification } from "../types";

export function NotificationsBell() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [open, setOpen] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    let cancelled = false;
    function load() {
      apiFetch<Notification[]>("/notifications")
        .then((data) => {
          if (!cancelled) setNotifications(data);
        })
        .catch(() => {});
    }
    load();
    const interval = setInterval(load, 30000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, []);

  const unreadCount = notifications.filter((n) => !n.read).length;

  async function handleClick(n: Notification) {
    setOpen(false);
    if (!n.read) {
      try {
        await apiFetch(`/notifications/${n.id}/mark_read`, { method: "POST" });
        setNotifications((prev) =>
          prev.map((x) => (x.id === n.id ? { ...x, read: true } : x)),
        );
      } catch {
        // not critical enough to block navigation if this fails
      }
    }
    navigate(`/expenses/${n.expense_id}`);
  }

  return (
    <div style={{ position: "relative", display: "inline-block", marginLeft: "0.75rem" }}>
      <button onClick={() => setOpen((o) => !o)} style={{ position: "relative" }}>
        🔔
        {unreadCount > 0 && (
          <span
            style={{
              position: "absolute",
              top: -6,
              right: -6,
              background: "red",
              color: "white",
              borderRadius: "50%",
              fontSize: "0.7rem",
              padding: "0.1rem 0.4rem",
            }}
          >
            {unreadCount}
          </span>
        )}
      </button>

      {open && (
        <div
          style={{
            position: "absolute",
            right: 0,
            top: "100%",
            background: "white",
            border: "1px solid #ccc",
            borderRadius: "4px",
            minWidth: "260px",
            maxHeight: "320px",
            overflowY: "auto",
            zIndex: 10,
            boxShadow: "0 2px 6px rgba(0,0,0,0.15)",
          }}
        >
          {notifications.length === 0 && <div style={{ padding: "0.75rem" }}>No notifications</div>}
          {notifications.map((n) => (
            <div
              key={n.id}
              onClick={() => handleClick(n)}
              style={{
                padding: "0.6rem 0.75rem",
                borderBottom: "1px solid #eee",
                cursor: "pointer",
                fontWeight: n.read ? "normal" : "bold",
                background: n.read ? "white" : "#f0f6ff",
              }}
            >
              {n.message}
              <div style={{ fontSize: "0.75rem", color: "#888" }}>
                {new Date(n.created_at).toLocaleString(undefined, {
                  dateStyle: "short",
                  timeStyle: "short",
                })}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}