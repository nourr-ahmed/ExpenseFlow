interface OwnerBadgeProps {
  name: string;
  role: string;
  team: { id: number; name: string } | null;
}

const ROLE_COLORS: Record<string, string> = {
  admin: "#fde2e2",
  manager: "#fff3cd",
  employee: "#e2f0fd",
};

export function OwnerBadge({ name, role, team }: OwnerBadgeProps) {
  return (
    <div>
      <div style={{ fontWeight: 500 }}>{name}</div>
      <div style={{ display: "flex", alignItems: "center", gap: "0.4rem", marginTop: "0.15rem" }}>
        <span
          style={{
            fontSize: "0.7rem",
            padding: "0.1rem 0.4rem",
            borderRadius: "4px",
            background: ROLE_COLORS[role] ?? "#eee",
            color: "#333",
          }}
        >
          {role}
        </span>
        {team && <span style={{ fontSize: "0.8rem", color: "#666" }}>{team.name}</span>}
      </div>
    </div>
  );
}