#!/bin/bash
# Outputs CR role definition and Role File Format spec for DCI injection.
# Called via !`cmd` DCI in /role-cr SKILL.md.
#
# Output: cr-role-creator.md content, then ---, then role-format.md content

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REFERENCE_DIR="$SCRIPT_DIR/../skills/role-init/reference"

cat "$REFERENCE_DIR/cr-role-creator.md"
echo ""
echo "---"
echo ""
cat "$REFERENCE_DIR/role-format.md"
