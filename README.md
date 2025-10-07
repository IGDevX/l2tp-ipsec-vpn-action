L2TP/IPSec VPN Connect
======================

Brings up a VPN (IPSec + L2TP) on a self-hosted runner and exposes the PPP interface as outputs. Brings up a VPN (IPSec + L2TP) on a self-hosted runner and exposes the PPP interface as outputs. Supports a post-step disconnect to cleanly tear down the connection at the end of the workflow.

---

## About

This composite GitHub Action configures and starts an L2TP/IPSec VPN connection on the runner using strongSwan and xl2tpd. It configures IPSec and L2TP from the provided inputs, starts the VPN, waits for the PPP interface to appear, and returns the interface name and IP address as outputs.

It uses a **main + post workflow structure**, which means:

1. The **main** step starts the VPN, configures IPSec/L2TP, waits for the PPP interface, and outputs the interface name and IP.
2. The **post** step automatically **disconnects the VPN** when the workflow step ends.

> ⚠️ The VPN will be disconnected automatically when the job ends thanks to the **post-step**. Users should **not** call a separate disconnect.

---

## Features

* Installs required packages (`strongswan`, `xl2tpd`) on Debian/Ubuntu runners.
* Dynamically configures VPN using inputs.
* Starts services and brings up the VPN connection.
* Returns outputs:

  * `ppp_interface` - detected PPP device name (e.g., `ppp0`)
  * `ppp_ip` - IPv4 address assigned to the PPP interface
* Automatically disconnects the VPN at the end of the workflow using the post-step.

---

## Quick links

* Author: Alexandre-Roussel48
* Branding icon/color: lock / blue

---

## Usage

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

      - name: Show VPN interface
        run: |
          echo "PPP interface: ${{ steps.vpn.outputs.ppp_interface }}"
          echo "PPP IP: ${{ steps.vpn.outputs.ppp_ip }}"

      - name: Configure VPN routes
        run: |
          HOST_IP=192.168.1.100  # the IP you want to reach through VPN
          IFACE=${{ steps.vpn.outputs.ppp_interface }}
          sudo ip route add "$HOST_IP" dev "$IFACE"
```

---

## Inputs

| Name            | Required | Description                                                   |
| --------------- | -------- | ------------------------------------------------------------- |
| `vpn_gateway`   | ✅        | VPN server hostname or IP.                                    |
| `vpn_psk`       | ✅        | Pre-shared key (PSK) for IPSec. Treat as secret.              |
| `vpn_username`  | ✅        | L2TP username.                                                |
| `vpn_password`  | ✅        | L2TP password. Treat as secret.                               |
| `vpn_nt_domain` | ✅        | Domain used for PPP options (NT domain).                      |
| `vpn_ike`       | ✅        | IKE (phase 1) cipher settings (e.g., `aes128-sha1-modp1024`). |
| `vpn_esp`       | ✅        | ESP (phase 2) cipher settings (e.g., `aes128-sha1`).          |

---

## Outputs

| Name            | Description                                     |
| --------------- | ----------------------------------------------- |
| `ppp_interface` | The detected VPN interface name (e.g., `ppp0`). |
| `ppp_ip`        | The IPv4 address assigned to the PPP interface. |

---

## Permissions & Runner requirements

* Must run on a **self-hosted runner** with sudo access.
* Required sudo privileges:

  * install packages (`apt-get`)
  * write system config files under `/etc`
  * restart/control `strongswan` and `xl2tpd`
  * manipulate network interfaces
* Tested on Debian/Ubuntu-based runners.

---

## Security notes

* Masks `vpn_password` and `vpn_psk` using `::add-mask::`.
* Writes credentials to `/etc/ipsec.secrets` and `/etc/ppp/options.l2tpd.client` with permissions 600.
* Use dedicated self-hosted runners; do **not** run on shared runners.

---

## Behavior & failure modes

* Waits up to 90 seconds for a PPP interface; fails with exit code 1 if none appears.
* Installation or service restart failures cause job failure.
* Non-Debian OS or missing init system may break commands.

---

## Troubleshooting

* "Timeout: PPP interface did not appear" - check that:
  * VPN gateway is reachable from the runner.
  * Credentials and PSK are correct.
  * required packages were installed successfully.
  * services `strongswan`/`xl2tpd` started correctly (check logs on runner).
* Check system logs and `/var/log/syslog` or the appropriate journal for `strongswan`/`xl2tpd` messages.
* If your runner uses non-root shells or lacks sudo, provide a runner with sudo access.

---

## Advanced usage / Routing

* Use `ppp_interface` to route specific traffic through the VPN:

```bash
HOST_IP=192.168.1.100
IFACE=${{ steps.vpn.outputs.ppp_interface }}
sudo ip route add "$HOST_IP" dev "$IFACE"
```

---

## Changelog

* Initial release: configure/start L2TP/IPSec VPN, return PPP interface/IP, mandatory post-step disconnect integrated.

---

## License

Distributed under the repository license. See the top-level LICENSE file.