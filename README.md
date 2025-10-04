L2TP/IPSec VPN Connect
======================

Brings up a VPN (IPSec + L2TP) on a self-hosted runner and exposes the PPP interface as outputs.

About
-----
This composite GitHub Action configures and starts an L2TP/IPSec VPN connection on the runner using strongSwan and xl2tpd. It configures IPSec and L2TP from the provided inputs, starts the VPN, waits for the PPP interface to appear, and returns the interface name and IP address as outputs.

Features
--------
- Installs required packages (strongSwan, xl2tpd and helpers) on Debian/Ubuntu runners.
- Configures IPSec (ipsec.conf / ipsec.secrets) and L2TP (xl2tpd and PPP options) dynamically from inputs.
- Starts services and brings up the VPN connection.
- Waits for the PPP interface and returns:
  - `ppp_interface` - detected PPP device name (e.g., ppp0)
  - `ppp_ip` - IPv4 address assigned to the PPP interface

Quick links
-----------
- Author: Alexandre-Roussel48
- Branding icon/color: lock / blue

Usage
-----
Example workflow snippet:

```yaml
name: Example VPN job
on: [workflow_dispatch]

jobs:
  vpn_job:
    runs-on: self-hosted
    steps:
      - name: Start L2TP/IPSec VPN
        uses: igdevx/l2tp-ipsec-vpn-action@v1
        id: vpn
        with:
          vpn_gateway: vpn.example.com
          vpn_psk: ${{ secrets.VPN_PSK }}
          vpn_username: ${{ secrets.VPN_USER }}
          vpn_password: ${{ secrets.VPN_PASS }}
          vpn_nt_domain: example.local
          vpn_ike: aes128-sha1-modp1024
          vpn_esp: aes128-sha1
```

After the action finishes you can use the outputs:

```yaml
      - name: Show VPN interface
        run: |
          echo "PPP interface: ${{ steps.vpn.outputs.ppp_interface }}"
          echo "PPP IP: ${{ steps.vpn.outputs.ppp_ip }}"
```

Inputs
------
- `vpn_gateway` (required) - VPN server hostname or IP.
- `vpn_psk` (required) - Pre-shared key (PSK) for IPSec. Treat as secret.
- `vpn_username` (required) - L2TP username.
- `vpn_password` (required) - L2TP password. Treat as secret.
- `vpn_nt_domain` (required) - Domain used for PPP options (NT domain).
- `vpn_ike` (required) - IKE (phase 1) cipher settings (e.g., `aes128-sha1-modp1024`).
- `vpn_esp` (required) - ESP (phase 2) cipher settings (e.g., `aes128-sha1`).

Outputs
-------
- `ppp_interface` - The detected VPN interface name (e.g., `ppp0`).
- `ppp_ip` - The IPv4 address assigned to the PPP interface.

Permissions & Runner requirements
---------------------------------
- This action must run on a self-hosted runner or a runner that allows installing packages and starting system services. It requires sudo privileges to:
  - install packages (apt-get)
  - write system config files under `/etc`
  - restart and control `strongswan`/`xl2tpd` and manipulate network interfaces
- OS tested: Debian/Ubuntu-based runners. The install commands and service names assume apt and systemd/init scripts.

Security notes
--------------
- The action masks the provided `vpn_password` and `vpn_psk` using GitHub's `::add-mask::` feature, but you should still store these secrets in repository or organization Secrets and pass them through `${{ secrets.NAME }}`.
- The action writes credentials to `/etc/ipsec.secrets` and `/etc/ppp/options.l2tpd.client` with restricted permissions (600) during runtime. Ensure you trust the runner environment.
- Running system-level network changes on shared runners is discouraged. Use dedicated self-hosted runners for safety and predictability.

Behavior & failure modes
------------------------
- The action waits up to 90 seconds for a PPP interface to appear. If no PPP interface appears, the step exits with status 1 and a clear timeout message.
- The action installs packages using `apt-get`. If package installation fails or network access is blocked, the job will fail.
- If the runner's OS or init system differs (non-Debian or missing systemctl/service), the install and service restart commands may fail.

Troubleshooting
---------------
- "Timeout: PPP interface did not appear" - check that:
  - VPN gateway is reachable from the runner.
  - Credentials and PSK are correct.
  - required packages were installed successfully.
  - services `strongswan`/`xl2tpd` started correctly (check logs on runner).
- Check system logs and `/var/log/syslog` or the appropriate journal for `strongswan`/`xl2tpd` messages.
- If your runner uses non-root shells or lacks sudo, provide a runner with sudo access.

Example advanced usage
----------------------
- Use the outputs to configure the job's network behavior, route traffic, or run integration tests that require the remote network.
- Tear down: To disconnect the VPN after your job completes, use the companion action [`igdevx/l2tp-ipsec-vpn-disconnect`](https://github.com/igdevx/l2tp-ipsec-vpn-disconnect). This action cleanly brings down the IPSec and L2TP connection. Example usage:

    ```yaml
            - name: Disconnect VPN
                uses: igdevx/l2tp-ipsec-vpn-disconnect@v1
    ```

Changelog
---------
- Initial release: configure and start L2TP/IPSec connection, return PPP interface and IP.

License
-------
Distributed under the repository license. See the top-level LICENSE file.
