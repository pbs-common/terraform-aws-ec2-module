#!/usr/bin/env bash
set -euo pipefail
tflint --init
tflint --recursive
