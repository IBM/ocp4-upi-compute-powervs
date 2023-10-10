#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# This file is a shortcut to generate the contents in the worker.ign

# v1: tx-checksumming off / restarts wait-online
# Content: IyEvYmluL2Jhc2gKaWYgWyAiIiA9ICJlbnYzIiBdICYmIFsgIiIgPSAidXAiIF0KdGhlbgogIC9zYmluL2V0aHRvb2wgLS1vZmZsb2FkIGVudjMgdHgtY2hlY2tzdW1taW5nIG9mZgogIHN5c3RlbWN0bCByZXN0YXJ0IE5ldHdvcmtNYW5hZ2VyLXdhaXQtb25saW5lLnNlcnZpY2UgCmZpCg==

# v2: missing details for interface and action 
# Content: aWYgWyAiIiA9ICJlbnYzIiBdICYmIFsgIiIgPSAidXAiIF0KdGhlbgogIC9zYmluL2V0aHRvb2wgLS1vZmZsb2FkIGVudjMgdHgtY2hlY2tzdW1taW5nIG9mZgogIHN5c3RlbWN0bCByZXN0YXJ0IE5ldHdvcmtNYW5hZ2VyLXdhaXQtb25saW5lLnNlcnZpY2UgCmVsc2UgCiAgImVjaG8gIm5vdCBydW5uaW5nIHR4LWNoZWNrc3VtbWluZyBvZmYiCmZpCg==

# v3: change to env2
# Content: aWYgWyAiIiA9ICJlbnYyIiBdICYmIFsgIiIgPSAidXAiIF0KdGhlbgogIGVjaG8gIlR1cm5pbmcgb2ZmIHR4LWNoZWNrc3VtbWluZyIKICAvc2Jpbi9ldGh0b29sIC0tb2ZmbG9hZCBlbnYyIHR4LWNoZWNrc3VtbWluZyBvZmYKZWxzZSAKICAiZWNobyAibm90IHJ1bm5pbmcgdHgtY2hlY2tzdW1taW5nIG9mZiIKZmkKaWYgISBzeXN0ZW1jdGwgaXMtZmFpbGVkIE5ldHdvcmtNYW5hZ2VyLXdhaXQtb25saW5lCnRoZW4Kc3lzdGVtY3RsIHJlc3RhcnQgTmV0d29ya01hbmFnZXItd2FpdC1vbmxpbmUKZmkK

# v4: update the logic and fix missing variables
# Content: aWYgWyAiJDEiID0gImVudjIiIF0gJiYgWyAiJDIiID0gInVwIiBdCnRoZW4KICBlY2hvICJUdXJuaW5nIG9mZiB0eC1jaGVja3N1bW1pbmciCiAgL3NiaW4vZXRodG9vbCAtLW9mZmxvYWQgZW52MiB0eC1jaGVja3N1bW1pbmcgb2ZmCmVsc2UgCiAgZWNobyAibm90IHJ1bm5pbmcgdHgtY2hlY2tzdW1taW5nIG9mZiIKZmkKaWYgc3lzdGVtY3RsIGlzLWZhaWxlZCBOZXR3b3JrTWFuYWdlci13YWl0LW9ubGluZQp0aGVuCnN5c3RlbWN0bCByZXN0YXJ0IE5ldHdvcmtNYW5hZ2VyLXdhaXQtb25saW5lCmZpCg==
cat ethtool.raw | base64 --wrap=0
echo ""
