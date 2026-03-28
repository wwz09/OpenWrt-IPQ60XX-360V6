#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

# 导入所有设置脚本
. "$(dirname "$0")/network.sh"

# 主设置函数
run_settings() {
    local WRT_THEME="$1"
    local WRT_MARK="$2"
    local WRT_DATE="$3"
    local WRT_NAME="$4"
    local WRT_PACKAGE="$5"
    local WRT_TARGET="$6"
    local WRT_CONFIG="$7"
    
    echo "Starting system settings..."
    
    # 配置网络设置
    configure_network "$WRT_THEME" "$WRT_MARK" "$WRT_DATE" "$WRT_NAME" "$WRT_PACKAGE" "$WRT_TARGET" "$WRT_CONFIG"
    
    echo "System settings completed!"
}

# 如果直接运行此脚本，则执行主设置函数
if [[ "$0" == "$BASH_SOURCE" ]]; then
    if [ $# -lt 7 ]; then
        echo "Usage: $0 <WRT_THEME> <WRT_MARK> <WRT_DATE> <WRT_NAME> <WRT_PACKAGE> <WRT_TARGET> <WRT_CONFIG>"
        exit 1
    fi
    run_settings "$1" "$2" "$3" "$4" "$5" "$6" "$7"
fi
