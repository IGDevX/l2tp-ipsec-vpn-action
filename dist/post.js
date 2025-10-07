import { execFileSync } from "child_process";
import { join } from "path";
import * as core from "@actions/core";

try {
  const script = join(process.cwd(), "scripts/disconnect.sh");
  execFileSync("bash", [script], { stdio: "inherit" });
} catch (err) {
  core.warning(`Cleanup failed: ${err.message}`);
}
