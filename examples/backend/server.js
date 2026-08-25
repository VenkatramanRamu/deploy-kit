// Small Express app for trying out the deploy-kit flow.
// It reports which git commit is live, read from the COMMIT file the build stamps.
const express = require("express");
const fs = require("fs");
const path = require("path");

const app = express();
const port = process.env.PORT || 3000;

let commit = "dev";
try {
  commit = fs.readFileSync(path.join(__dirname, "COMMIT"), "utf8").trim();
} catch {
  /* no COMMIT file when running from source, that's fine */
}

app.get("/", (_req, res) =>
  res.json({ ok: true, service: "example-backend", commit })
);

app.listen(port, () =>
  console.log(`example-backend listening on :${port} (commit ${commit})`)
);
