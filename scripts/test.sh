#!/usr/bin/env bash
set -euo pipefail
cd tests
go test -v -timeout 30m ./...
