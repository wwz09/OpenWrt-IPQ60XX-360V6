#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

# 导入所有脚本
. "$(dirname "$0")/common/utils.sh"
. "$(dirname "$0")/common/config.sh"
. "$(dirname "$0")/packages/manager.sh"
. "$(dirname "$0")/settings/main.sh"
. "$(dirname "$0")/handlers/main.sh"

# 主函数
main() {
    local action="$1"
    shift
    
    case "$action" in
        "packages")
            # 管理包
            manage_packages "$@"
            ;;
        "settings")
            # 配置系统
            run_settings "$@"
            ;;
        "handlers")
            # 处理包
            run_handlers "$@"
            ;;
        "utils")
            # 工具函数
            if [ "$1" == "update_version" ]; then
                shift
                update_package_version "$@"
            fi
            ;;
        *)
            echo "Usage: $0 <action> [args]"
            echo "Actions:"
            echo "  packages <target> <config> - Manage packages"
            echo "  settings <theme> <mark> <date> <name> <package> <target> <config> - Configure system"
            echo "  handlers <package_path> - Run package handlers"
            echo "  utils update_version <package_name> [prerelease] - Update package version"
            exit 1
            ;;
    esac
}

# 如果直接运行此脚本，则执行主函数
if [[ "$0" == "$BASH_SOURCE" ]]; then
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <action> [args]"
        exit 1
    fi
    main "$@"
fi
