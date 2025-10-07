import { execFileSync } from "child_process";
import { join } from "path";
import * as core from "@actions/core";

try {
  const script = join(process.cwd(), "scripts/connect.sh");
  execFileSync("bash", [script], {
    stdio: "inherit",
    env: {
      ...process.env,
      VPN_GATEWAY: core.getInput("vpn_gateway"),
      VPN_PSK: core.getInput("vpn_psk"),
      VPN_USERNAME: core.getInput("vpn_username"),
      VPN_PASSWORD: core.getInput("vpn_password"),
      VPN_NT_DOMAIN: core.getInput("vpn_nt_domain"),
      VPN_IKE: core.getInput("vpn_ike"),
      VPN_ESP: core.getInput("vpn_esp"),
    },
  });
} catch (err) {
  core.setFailed(err.message);
}
