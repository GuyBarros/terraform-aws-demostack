#!/usr/bin/env bash
set -e

# Trap the reboot as an exit, because the script has to return 0 or else
# Terraform will think it failed.
function reboot {
  sudo systemctl reboot
}

trap reboot EXIT

echo "==> Rebooting"
