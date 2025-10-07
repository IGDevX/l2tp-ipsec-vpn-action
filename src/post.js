const { execFileSync } = require("child_process");
const { join } = require("path");
const core = require("@actions/core");

try {
  const script = join(process.cwd(), "scripts/disconnect.sh");
  execFileSync("bash", [script], { stdio: "inherit" });
} catch (err) {
  core.warning(`Cleanup failed: ${err.message}`);
}

