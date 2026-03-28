#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

# 导入所有处理脚本
. "$(dirname "$0")/homeproxy.sh"
. "$(dirname "$0")/theme.sh"
. "$(dirname "$0")/nss.sh"
. "$(dirname "$0")/package_fixes.sh"

# 主处理函数
run_handlers() {
    local PKG_PATH="$1"
    
    echo "Starting package handlers..."
    
    # 运行所有处理函数
    handle_homeproxy "$PKG_PATH"
    handle_argon_theme "$PKG_PATH"
    handle_aurora_theme "$PKG_PATH"
    handle_nss_drv "$PKG_PATH"
    handle_nss_pbuf "$PKG_PATH"
    handle_tailscale "$PKG_PATH"
    handle_rust "$PKG_PATH"
    handle_diskman "$PKG_PATH"
    handle_netspeedtest "$PKG_PATH"
    handle_python_deps "$PKG_PATH"
    
    echo "Package handlers completed!"
}

# 如果直接运行此脚本，则执行主处理函数
if [[ "$0" == "$BASH_SOURCE" ]]; then
    if [ -z "$1" ]; then
        echo "Usage: $0 <package_path>"
        exit 1
    fi
    run_handlers "$1"
fi
