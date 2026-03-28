#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

# 修复TailScale配置文件冲突
handle_tailscale() {
    local PKG_PATH="$1"
    local TS_FILE=$(find "$PKG_PATH/../feeds/packages/" -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
    
    if [ -f "$TS_FILE" ]; then
        echo ""

        sed -i '/\/files/d' "$TS_FILE"

        cd "$PKG_PATH" && echo "tailscale has been fixed!"
    fi
}

# 修复Rust编译失败
handle_rust() {
    local PKG_PATH="$1"
    local RUST_FILE=$(find "$PKG_PATH/../feeds/packages/" -maxdepth 3 -type f -wholename "*/rust/Makefile")
    
    if [ -f "$RUST_FILE" ]; then
        echo ""

        sed -i 's/ci-llvm=true/ci-llvm=false/g' "$RUST_FILE"

        cd "$PKG_PATH" && echo "rust has been fixed!"
    fi
}

# 修复DiskMan编译失败
handle_diskman() {
    local PKG_PATH="$1"
    local DM_FILE="$PKG_PATH/luci-app-diskman/applications/luci-app-diskman/Makefile"
    
    if [ -f "$DM_FILE" ]; then
        echo ""

        sed -i '/ntfs-3g-utils /d' "$DM_FILE"

        cd "$PKG_PATH" && echo "diskman has been fixed!"
    fi
}

# 修复luci-app-netspeedtest相关问题
handle_netspeedtest() {
    local PKG_PATH="$1"
    
    if [ -d "$PKG_PATH"*"luci-app-netspeedtest"* ]; then
        echo ""

        cd "$PKG_PATH/luci-app-netspeedtest/"

        sed -i '$a\exit 0' ./netspeedtest/files/99_netspeedtest.defaults
        sed -i 's/ca-certificates/ca-bundle/g' ./speedtest-cli/Makefile

        # 修复python3-pkg-resources依赖问题，替换为python3-setuptools
        if [ -f "./Makefile" ]; then
            sed -i 's/python3-pkg-resources/python3-setuptools/g' ./Makefile
        fi
        # 同时检查并修复speedtest-cli的依赖
        if [ -f "./speedtest-cli/Makefile" ]; then
            sed -i 's/python3-pkg-resources/python3-setuptools/g' ./speedtest-cli/Makefile
        fi
        # 检查并修复netspeedtest的依赖
        if [ -f "./netspeedtest/Makefile" ]; then
            sed -i 's/python3-pkg-resources/python3-setuptools/g' ./netspeedtest/Makefile
        fi

        cd "$PKG_PATH" && echo "netspeedtest has been fixed!"
    fi
}

# 修复python3-pkg-resources依赖问题
handle_python_deps() {
    local PKG_PATH="$1"
    local NETSPEEDTEST_MK="$PKG_PATH/netspeedtest/luci-app-netspeedtest/Makefile"
    
    if [ -f "$NETSPEEDTEST_MK" ]; then
        sed -i 's/python3-pkg-resources/python3-setuptools/g' "$NETSPEEDTEST_MK"
        echo "netspeedtest python3-pkg-resources dependency has been fixed!"
    fi
}
