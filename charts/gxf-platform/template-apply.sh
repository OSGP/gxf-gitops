#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname -- "$DIR")"

"$CHART_DIR"/_template_apply.sh "$DIR" osgp-platform "$*"
