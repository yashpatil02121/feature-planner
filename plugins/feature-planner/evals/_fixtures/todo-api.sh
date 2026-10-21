#!/usr/bin/env bash
# Small Express + node:test todo API. Writes into the current directory.
set -euo pipefail
mkdir -p src/routes test

cat > package.json <<'EOF'
{ "name": "todo-api", "version": "1.0.0", "type": "module",
  "scripts": { "start": "node src/server.js", "test": "node --test" },
  "dependencies": { "express": "^4.19.2" } }
EOF

cat > src/server.js <<'EOF'
import express from "express";
import { todosRouter } from "./routes/todos.js";
const app = express();
app.use(express.json());
app.use("/todos", todosRouter);
app.listen(3000);
EOF

cat > src/routes/todos.js <<'EOF'
import { Router } from "express";
import { store } from "../store.js";
export const todosRouter = Router();
todosRouter.get("/", (req, res) => res.json(store.list()));
todosRouter.post("/", (req, res) => {
  if (!req.body?.title) return res.status(400).json({ error: "title required" });
  res.status(201).json(store.add(req.body.title));
});
EOF

cat > src/store.js <<'EOF'
const todos = [];
let nextId = 1;
export const store = {
  list: () => todos,
  add: (title) => { const t = { id: nextId++, title, done: false }; todos.push(t); return t; },
};
EOF

cat > test/store.test.js <<'EOF'
import { test } from "node:test";
import assert from "node:assert";
import { store } from "../src/store.js";
test("add returns todo with id", () => { assert.equal(store.add("x").id, 1); });
EOF
