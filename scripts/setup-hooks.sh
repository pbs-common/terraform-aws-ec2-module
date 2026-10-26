#!/usr/bin/env bash
set -euo pipefail
cat > .git/hooks/pre-commit <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
scripts/validate.sh
scripts/format.sh
scripts/document.sh
HOOK
chmod +x .git/hooks/pre-commit
