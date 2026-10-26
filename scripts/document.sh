#!/usr/bin/env bash
set -euo pipefail
terraform-docs markdown --header-from README-HEADER.md . > README.md
git add README.md
