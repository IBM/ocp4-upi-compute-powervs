#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Maps or overrides the regions

# v2: reverted the mapping for jp-osa to osa21
# v1: jp-osa: osa21 is remapped to tok04

REGION="$1"
OVERRIDE="$2"

case "$REGION" in
  ("jp-osa") echo "osa21" ;;
  ("eu-gb") echo "lon05" ;;
  ("ca-tor") echo "mon01" ;;
  ("br-sao") echo "sao01" ;;
  ("au-syd") echo "syd05" ;;
  ("jp-tok") echo "tok04" ;;
  (*) echo "$REGION" ;;
esac
