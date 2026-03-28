#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

# 修改argon主题字体和颜色
handle_argon_theme() {
    local PKG_PATH="$1"
    
    if [ -d "$PKG_PATH"*"luci-theme-argon"* ]; then
        echo ""

        cd "$PKG_PATH/luci-theme-argon/"

        sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" ./luci-app-argon-config/root/etc/config/argon

        cd "$PKG_PATH" && echo "theme-argon has been fixed!"
    fi
}

# 修改aurora菜单式样
handle_aurora_theme() {
    local PKG_PATH="$1"
    
    if [ -d "$PKG_PATH"*"luci-app-aurora-config"* ]; then
        echo ""

        cd "$PKG_PATH/luci-app-aurora-config/"

        sed -i "s/nav_submenu_type '.*'/nav_submenu_type 'boxed-dropdown'/g" $(find ./root/ -type f -name "*aurora")

        cd "$PKG_PATH" && echo "theme-aurora has been fixed!"
    fi
}
