#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Maps or overrides the regions

# v3: update for new regions
# v2: reverted the mapping for jp-osa to osa21
# v1: jp-osa: osa21 is remapped to tok04

REGION="$1"
OVERRIDE="$2"

case "$REGION" in
  ("us-south") echo "dal10";;
  ("us-east") echo "wdc06";;
  ("br-sao") echo "sao01";;
  ("ca-tor") echo "tor01";;
  ("ca-mon") echo "mon01";;
  ("eu-de") echo "eu-de-1";;
  ("eu-gb") echo "lon06";;
  ("eu-es") echo "mad02";;
  ("au-syd") echo "syd05" ;;
  ("jp-tok") echo "tok04" ;;
  ("jp-osa") echo "osa21";;
  (*) echo "$REGION" ;;
esac
