#!/usr/bin/env bash
# Delete the rehearsal cluster. Colima keeps running; stop it with `colima stop`.
set -euo pipefail
kind delete cluster --name vks-rehearsal
