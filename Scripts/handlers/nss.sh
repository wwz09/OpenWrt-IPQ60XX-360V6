#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

# 修改qca-nss-drv启动顺序
handle_nss_drv() {
    local PKG_PATH="$1"
    local NSS_DRV="$PKG_PATH/../feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
    
    if [ -f "$NSS_DRV" ]; then
        echo ""

        sed -i 's/START=.*/START=85/g' "$NSS_DRV"

        cd "$PKG_PATH" && echo "qca-nss-drv has been fixed!"
    fi
}

# 修改qca-nss-pbuf启动顺序
handle_nss_pbuf() {
    local PKG_PATH="$1"
    local NSS_PBUF="$PKG_PATH/kernel/mac80211/files/qca-nss-pbuf.init"
    
    if [ -f "$NSS_PBUF" ]; then
        echo ""

        sed -i 's/START=.*/START=86/g' "$NSS_PBUF"

        cd "$PKG_PATH" && echo "qca-nss-pbuf has been fixed!"
    fi
}
