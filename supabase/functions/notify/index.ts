import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── APNs JWT ────────────────────────────────────────────────────────────────

async function buildAPNsJWT(): Promise<string> {
  const keyPem  = Deno.env.get("APNS_PRIVATE_KEY")!;
  const keyId   = Deno.env.get("APNS_KEY_ID")!;
  const teamId  = Deno.env.get("APNS_TEAM_ID")!;

  const encode = (o: object) =>
    btoa(JSON.stringify(o)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const unsigned = `${encode({ alg: "ES256", kid: keyId })}.${encode({
    iss: teamId,
    iat: Math.floor(Date.now() / 1000),
  })}`;

  const pem = keyPem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");

  const key = await crypto.subtle.importKey(
    "pkcs8",
    Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );

  const sig = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(unsigned),
  );

  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  return `${unsigned}.${sigB64}`;
}

// ─── Send to a single device token ──────────────────────────────────────────

async function sendToToken(token: string, title: string, body: string): Promise<void> {
  const jwt      = await buildAPNsJWT();
  const isSandbox = (Deno.env.get("APNS_ENV") ?? "sandbox") !== "production";
  const host     = isSandbox
    ? "https://api.sandbox.push.apple.com"
    : "https://api.push.apple.com";

  const res = await fetch(`${host}/3/device/${token}`, {
    method: "POST",
    headers: {
      authorization:    `bearer ${jwt}`,
      "apns-topic":     Deno.env.get("APNS_BUNDLE_ID")!,
      "apns-push-type": "alert",
      "content-type":   "application/json",
    },
    body: JSON.stringify({
      aps: { alert: { title, body }, badge: 1, sound: "default" },
    }),
  });

  if (!res.ok) {
    const detail = await res.text().catch(() => "");
    console.error(`APNs ${res.status}: ${detail}`);
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

// deno-lint-ignore no-explicit-any
async function notifyEmployee(supabase: any, employeeId: string, title: string, body: string) {
  const { data } = await supabase
    .from("device_tokens")
    .select("token")
    .eq("employee_id", employeeId)
    .single();

  if (data?.token) {
    await sendToToken(data.token, title, body);
  }
}

// ─── Main handler ─────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  try {
    const { type, table, record } = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Time off approved or denied → notify the employee who requested it
    if (table === "kn_time_off" && type === "UPDATE") {
      if (record.status === "approved" || record.status === "denied") {
        const verb = record.status === "approved" ? "approved ✓" : "denied";
        await notifyEmployee(
          supabase,
          record.employee_id,
          `Time off ${verb}`,
          `Your ${record.kind} request has been ${record.status}.`,
        );
      }
    }

    // Swap approved or denied → notify who submitted it
    // New swap request → notify the person being asked to swap
    if (table === "kn_swaps") {
      if (type === "UPDATE" && (record.status === "approved" || record.status === "denied")) {
        await notifyEmployee(
          supabase,
          record.from_employee_id,
          `Swap ${record.status}`,
          `Your shift swap request has been ${record.status}.`,
        );
      }
      if (type === "INSERT") {
        const { data: requester } = await supabase
          .from("employees").select("name").eq("id", record.from_employee_id).single();
        await notifyEmployee(
          supabase,
          record.with_employee_id,
          "Swap request",
          `${requester?.name ?? "A teammate"} wants to swap a shift with you.`,
        );
      }
    }

    // New shift added to schedule → notify the employee
    if (table === "kn_shifts" && type === "INSERT") {
      await notifyEmployee(
        supabase,
        record.employee_id,
        "New shift scheduled",
        `You're on for ${record.day} ${record.shift_date} (${record.start_time} – ${record.end_time}).`,
      );
    }

    // New message → notify all thread participants except the sender
    if (table === "kn_messages" && type === "INSERT") {
      const { data: participants } = await supabase
        .from("kn_message_participants")
        .select("employee_id")
        .eq("thread_id", record.thread_id)
        .neq("employee_id", record.sender_id);

      if (participants?.length) {
        const { data: sender } = await supabase
          .from("employees").select("name").eq("id", record.sender_id).single();
        const preview = record.text.length > 60
          ? record.text.slice(0, 57) + "…"
          : record.text;

        for (const p of participants) {
          await notifyEmployee(supabase, p.employee_id, sender?.name ?? "New message", preview);
        }
      }
    }

    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
