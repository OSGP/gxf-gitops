#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

../_template_apply.sh $DIR osgp-platform $*
