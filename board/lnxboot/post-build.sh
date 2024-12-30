#!/bin/sh

set -u
set -e

# Add my special init script
if [ -d ${TARGET_DIR} ]; then
  cp -av \
    ${BR2_EXTERNAL_LNXBOOT_PATH}/board/lnxboot/init.sh \
    ${TARGET_DIR}/init
fi
