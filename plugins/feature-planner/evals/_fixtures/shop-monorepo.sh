#!/usr/bin/env bash
# Large TypeScript monorepo (~300 files) for planning-at-scale evals. The code a
# "rate limit password reset" feature needs is buried in two of ~13 packages:
#   packages/auth/src/routes/passwordReset.ts   (the endpoint)
#   packages/shared/src/middleware/rateLimit.ts (an existing helper to reuse)
# Noise includes node_modules/, dist/, docs, and many unrelated packages.
# Writes into the current directory.
set -euo pipefail

cat > package.json <<'EOF'
{
  "name": "shop",
  "private": true,
  "workspaces": ["packages/*"],
  "scripts": { "test": "vitest run", "build": "tsc -b", "lint": "eslint ." },
  "devDependencies": { "typescript": "^5.6.0", "vitest": "^2.1.0", "eslint": "^9.12.0" }
}
EOF

cat > CLAUDE.md <<'EOF'
# shop monorepo
- Each package lives in packages/<name>, with src/routes, src/services, src/models and tests in test/.
- Cross-cutting middleware lives in packages/shared/src/middleware. Reuse it; do not add per-package copies.
- HTTP framework: Fastify. Routes register with `export async function register(app: FastifyInstance)`.
- Tests use vitest and `app.inject` from packages/shared/test/helpers.ts (`buildTestApp`).
EOF

cat > README.md <<'EOF'
# Shop
Monorepo for the shop backend: catalog, orders, payments, users, auth, and more.
Run `npm test` from the root.
EOF
cat > tsconfig.json <<'EOF'
{ "compilerOptions": { "strict": true, "module": "NodeNext", "target": "ES2022" }, "references": [] }
EOF

pkgs=(auth billing catalog orders inventory notifications search users shipping reviews analytics admin)
for p in "${pkgs[@]}"; do
  d="packages/$p"
  mkdir -p "$d/src/routes" "$d/src/services" "$d/src/models" "$d/test"
  printf '{ "name": "@shop/%s", "version": "1.0.0", "main": "src/index.ts" }\n' "$p" > "$d/package.json"
  printf '# @shop/%s\n\nThe %s domain of the shop backend.\n' "$p" "$p" > "$d/README.md"
  cat > "$d/src/index.ts" <<EOF
import type { FastifyInstance } from "fastify";
import * as routes from "./routes/index.js";
export async function register(app: FastifyInstance) { await routes.register(app); }
EOF
  for r in list get create update remove; do
    cat > "$d/src/routes/$r.ts" <<EOF
import type { FastifyInstance } from "fastify";
import { ${p}Service } from "../services/${p}Service.js";
export async function register(app: FastifyInstance) {
  app.${r/list/get}("/${p}/${r}", async (req, reply) => reply.send(await ${p}Service.${r}(req.body)));
}
EOF
  done
  printf 'export * from "./list.js";\n' > "$d/src/routes/index.ts"
  for s in "${p}Service" "${p}Repository" "${p}Events"; do
    cat > "$d/src/services/$s.ts" <<EOF
// ${s}: business logic for ${p}.
export const ${s} = {
  async list() { return []; },
  async get(id: string) { return { id }; },
  async create(input: unknown) { return input; },
  async update(input: unknown) { return input; },
  async remove(input: unknown) { return input; },
};
EOF
  done
  for m in "${p^}" "${p^}Status"; do
    printf 'export interface %s { id: string; createdAt: Date; }\n' "$m" > "$d/src/models/$m.ts"
  done
  for t in service routes; do
    cat > "$d/test/$t.test.ts" <<EOF
import { describe, it, expect } from "vitest";
describe("${p} ${t}", () => { it("works", () => { expect(true).toBe(true); }); });
EOF
  done
done

# --- The buried, relevant code -------------------------------------------
cat > packages/auth/src/routes/passwordReset.ts <<'EOF'
import type { FastifyInstance } from "fastify";
import { resetTokens } from "../services/resetTokens.js";
import { mailer } from "@shop/notifications/src/services/notificationsService.js";

// POST /auth/password-reset/request  { email }  -> 202 always (no user enumeration)
// POST /auth/password-reset/confirm  { token, password } -> 204 | 400
export async function register(app: FastifyInstance) {
  app.post("/auth/password-reset/request", async (req, reply) => {
    const { email } = req.body as { email: string };
    const token = await resetTokens.issue(email);
    if (token) await mailer.sendPasswordReset(email, token);
    return reply.code(202).send();
  });
  app.post("/auth/password-reset/confirm", async (req, reply) => {
    const { token, password } = req.body as { token: string; password: string };
    const ok = await resetTokens.consume(token, password);
    return ok ? reply.code(204).send() : reply.code(400).send({ error: "invalid_token" });
  });
}
EOF
cat > packages/auth/src/services/resetTokens.ts <<'EOF'
import { randomBytes } from "node:crypto";
const TTL_MS = 30 * 60 * 1000;
const tokens = new Map<string, { email: string; expires: number }>();
export const resetTokens = {
  async issue(email: string) {
    const token = randomBytes(32).toString("hex");
    tokens.set(token, { email, expires: Date.now() + TTL_MS });
    return token;
  },
  async consume(token: string, _password: string) {
    const t = tokens.get(token);
    tokens.delete(token);
    return !!t && t.expires > Date.now();
  },
};
EOF
cat > packages/auth/test/passwordReset.test.ts <<'EOF'
import { describe, it, expect } from "vitest";
import { buildTestApp } from "@shop/shared/test/helpers.js";
describe("password reset", () => {
  it("returns 202 for any email", async () => {
    const app = await buildTestApp();
    const res = await app.inject({ method: "POST", url: "/auth/password-reset/request", payload: { email: "a@b.c" } });
    expect(res.statusCode).toBe(202);
  });
});
EOF
cat > packages/users/src/routes/login.ts <<'EOF'
import type { FastifyInstance } from "fastify";
import { rateLimit } from "@shop/shared/src/middleware/rateLimit.js";
export async function register(app: FastifyInstance) {
  app.post("/users/login", { preHandler: rateLimit({ windowMs: 60_000, max: 10, key: (req) => req.ip }) },
    async (_req, reply) => reply.send({ ok: true }));
}
EOF

mkdir -p packages/shared/src/middleware packages/shared/src/utils packages/shared/test
printf '{ "name": "@shop/shared", "version": "1.0.0" }\n' > packages/shared/package.json
cat > packages/shared/src/middleware/rateLimit.ts <<'EOF'
import type { FastifyReply, FastifyRequest } from "fastify";

export interface RateLimitOptions {
  windowMs: number;
  max: number;
  /** Bucket key for a request, e.g. client IP or a body field. */
  key: (req: FastifyRequest) => string;
}

/** Fixed-window, in-memory limiter. Responds 429 with Retry-After when exceeded. */
export function rateLimit(opts: RateLimitOptions) {
  const hits = new Map<string, { count: number; resetAt: number }>();
  return async (req: FastifyRequest, reply: FastifyReply) => {
    const k = opts.key(req);
    const now = Date.now();
    const h = hits.get(k);
    if (!h || h.resetAt <= now) { hits.set(k, { count: 1, resetAt: now + opts.windowMs }); return; }
    if (++h.count > opts.max) {
      reply.header("Retry-After", Math.ceil((h.resetAt - now) / 1000));
      return reply.code(429).send({ error: "rate_limited" });
    }
  };
}
EOF
cat > packages/shared/test/rateLimit.test.ts <<'EOF'
import { describe, it, expect } from "vitest";
import { rateLimit } from "../src/middleware/rateLimit.js";
describe("rateLimit", () => { it("is a function factory", () => { expect(typeof rateLimit).toBe("function"); }); });
EOF
cat > packages/shared/test/helpers.ts <<'EOF'
import Fastify from "fastify";
export async function buildTestApp() { const app = Fastify(); /* registers all packages */ return app; }
EOF
for m in auth logging errors cors requestId; do
  printf '// %s middleware\nexport function %s() { return async () => {}; }\n' "$m" "$m" > "packages/shared/src/middleware/$m.ts"
done
for u in dates money ids strings retry config pagination validation; do
  printf '// %s helpers\nexport const %s = {};\n' "$u" "$u" > "packages/shared/src/utils/$u.ts"
done

# --- Noise -----------------------------------------------------------------
mkdir -p docs/adr docs/runbooks
for i in $(seq -w 1 15); do printf '# ADR %s\n\nDecision record %s.\n' "$i" "$i" > "docs/adr/$i-decision.md"; done
for r in deploy rollback oncall incidents backups; do printf '# %s\n\nRunbook.\n' "$r" > "docs/runbooks/$r.md"; done
for lib in fastify vitest zod pino undici; do
  mkdir -p "node_modules/$lib/lib"
  printf '{ "name": "%s", "version": "1.0.0" }\n' "$lib" > "node_modules/$lib/package.json"
  for f in index core util errors types rateLimit; do printf 'module.exports = {};\n' > "node_modules/$lib/lib/$f.js"; done
done
for p in auth users catalog; do
  mkdir -p "packages/$p/dist"
  for f in index routes services; do printf '"use strict";\n' > "packages/$p/dist/$f.js"; done
done
