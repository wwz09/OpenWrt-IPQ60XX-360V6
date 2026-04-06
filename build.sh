#!/usr/bin/env bash

set -e

# Determine wrt_core path
if [ -d "wrt_core" ]; then
    WRT_CORE_PATH="wrt_core"
elif [ -d "../wrt_core" ]; then
    WRT_CORE_PATH="../wrt_core"
else
    echo "Error: wrt_core directory not found!"
    exit 1
fi

BASE_PATH=$(cd "$WRT_CORE_PATH" && pwd)

Dev=$1
Build_Mod=$2

SUPPORTED_DEVS=()

collect_supported_devs() {
    local ini_file
    local dev_key
    local IFS

    SUPPORTED_DEVS=()

    for ini_file in "$BASE_PATH"/compilecfg/*.ini; do
        [[ -f "$ini_file" ]] || continue

        dev_key=$(basename "$ini_file" .ini)
        if [[ -f "$BASE_PATH/deconfig/$dev_key.config" ]]; then
            SUPPORTED_DEVS+=($dev_key)
        fi
    done

    if [[ ${#SUPPORTED_DEVS[@]} -eq 0 ]]; then
        return
    fi

    IFS=$'\n' SUPPORTED_DEVS=($(printf '%s\n' "${SUPPORTED_DEVS[@]}" | LC_ALL=C sort))
}

print_usage() {
    echo "Usage: $0 <device> [debug]"
}

print_supported_devs() {
    local index

    echo "Supported devices:"
    for ((index = 0; index < ${#SUPPORTED_DEVS[@]}; index++)); do
        printf "  %d) %s\n" "$((index + 1))" "${SUPPORTED_DEVS[index]}"
    done
}

prompt_select_dev() {
    local input
    local selected_index

    while true; do
        print_supported_devs
        printf "Select device by number (q to quit): "

        if ! read -r input; then
            echo
            echo "Cancelled."
            exit 1
        fi

        if [[ "$input" =~ ^[[:space:]]*[qQ][[:space:]]*$ ]]; then
            echo "Cancelled."
            exit 1
        fi

        if [[ "$input" =~ ^[[:space:]]*([0-9]+)[[:space:]]*$ ]]; then
            selected_index=${BASH_REMATCH[1]}
            if ((selected_index >= 1 && selected_index <= ${#SUPPORTED_DEVS[@]})); then
                Dev=${SUPPORTED_DEVS[selected_index - 1]}
                return
            fi
        fi

        echo "Invalid selection. Please enter a number between 1 and ${#SUPPORTED_DEVS[@]}."
    done
}

prompt_select_build_mode() {
    local input

    while true; do
        echo "Build mode:"
        echo "  1) normal"
        echo "  2) debug"
        printf "Select build mode (1-2, q to quit): "

        if ! read -r input; then
            echo
            echo "Cancelled."
            exit 1
        fi

        if [[ "$input" =~ ^[[:space:]]*[qQ][[:space:]]*$ ]]; then
            echo "Cancelled."
            exit 1
        fi

        if [[ "$input" =~ ^[[:space:]]*1[[:space:]]*$ ]]; then
            Build_Mod=""
            return
        fi

        if [[ "$input" =~ ^[[:space:]]*2[[:space:]]*$ ]]; then
            Build_Mod="debug"
            return
        fi

        echo "Invalid selection. Please enter 1 or 2."
    done
}

is_interactive_terminal() {
    [[ -t 0 && -t 1 ]]
}

if [[ $# -eq 0 ]]; then
    collect_supported_devs

    if [[ ${#SUPPORTED_DEVS[@]} -eq 0 ]]; then
        echo "Error: no supported devices found."
        exit 1
    fi

    if ! is_interactive_terminal; then
        print_usage
        print_supported_devs
        exit 1
    fi

    prompt_select_dev

    if [[ -z $Build_Mod ]]; then
        prompt_select_build_mode
    fi
fi

CONFIG_FILE="$BASE_PATH/deconfig/$Dev.config"
INI_FILE="$BASE_PATH/compilecfg/$Dev.ini"

if [[ ! -f $CONFIG_FILE ]]; then
    echo "Config not found: $CONFIG_FILE"
    exit 1
fi

if [[ ! -f $INI_FILE ]]; then
    echo "INI file not found: $INI_FILE"
    exit 1
fi

read_ini_by_key() {
    local key=$1
    awk -F"=" -v key="$key" '$1 == key {print $2}' "$INI_FILE"
}

remove_uhttpd_dependency() {
    local config_path="$BASE_PATH/../$BUILD_DIR/.config"
    local luci_makefile_path="$BASE_PATH/../$BUILD_DIR/feeds/luci/collections/luci/Makefile"

    if grep -q "CONFIG_PACKAGE_luci-app-quickfile=y" "$config_path"; then
        if [ -f "$luci_makefile_path" ]; then
            sed -i '/luci-light/d' "$luci_makefile_path"
            echo "Removed uhttpd (luci-light) dependency as luci-app-quickfile (nginx) is enabled."
        fi
    fi
}

fix_recursive_dependencies() {
    local build_dir="$BASE_PATH/../$BUILD_DIR"
    
    # 1. 修复 nikki -> firewall4 依赖
    if [ -f "$build_dir/feeds/packages/net/nikki/Makefile" ]; then
        sed -i 's/DEPENDS.*+firewall4/DEPENDS:=/g' "$build_dir/feeds/packages/net/nikki/Makefile"
        echo "已修复 nikki 的依赖"
    fi
    
    # 2. 修复 luci-app-fchomo -> nikki 依赖
    if [ -f "$build_dir/feeds/small/luci-app-fchomo/Makefile" ]; then
        sed -i 's/DEPENDS.*+nikki/DEPENDS:=/g' "$build_dir/feeds/small/luci-app-fchomo/Makefile"
        echo "已修复 luci-app-fchomo 的依赖"
    fi
    
    # 3. 修复 python3-email <-> python3-urllib 依赖
    if [ -f "$build_dir/feeds/packages/lang/python/python3-email/Makefile" ]; then
        sed -i 's/DEPENDS.*+python3-urllib/DEPENDS:=/g' "$build_dir/feeds/packages/lang/python/python3-email/Makefile"
        echo "已修复 python3-email 的依赖"
    fi
    if [ -f "$build_dir/feeds/packages/lang/python/python3-urllib/Makefile" ]; then
        sed -i 's/DEPENDS.*+python3-email/DEPENDS:=/g' "$build_dir/feeds/packages/lang/python/python3-urllib/Makefile"
        echo "已修复 python3-urllib 的依赖"
    fi
}

apply_config() {
    \cp -f "$CONFIG_FILE" "$BASE_PATH/../$BUILD_DIR/.config"
    
    # 强制禁用导致递归依赖的包
    cat >> "$BASE_PATH/../$BUILD_DIR/.config" << 'EOF'
# 禁用递归依赖的包
CONFIG_PACKAGE_luci-app-fchomo=n
CONFIG_PACKAGE_nikki=n
CONFIG_PACKAGE_fwupd=n
CONFIG_PACKAGE_python3-email=n
CONFIG_PACKAGE_python3-urllib=n
# 内核配置选项 - 避免交互式提示
CONFIG_NF_CONNTRACK_DSCPREMARK_EXT=n
EOF
}

REPO_URL=$(read_ini_by_key "REPO_URL")
REPO_BRANCH=$(read_ini_by_key "REPO_BRANCH")
REPO_BRANCH=${REPO_BRANCH:-}
BUILD_DIR=$(read_ini_by_key "BUILD_DIR")
COMMIT_HASH=$(read_ini_by_key "COMMIT_HASH")
COMMIT_HASH=${COMMIT_HASH:-none}

if [[ -d action_build ]]; then
    BUILD_DIR="action_build"
fi

# 克隆代码（如果不存在或仓库URL不匹配）
if [[ ! -d "$BASE_PATH/../$BUILD_DIR" ]] || [[ ! -d "$BASE_PATH/../$BUILD_DIR/.git" ]]; then
    echo "Cloning repository..."
    rm -rf "$BASE_PATH/../$BUILD_DIR"
    if [[ -n "$REPO_BRANCH" ]]; then
        git clone -b "$REPO_BRANCH" "$REPO_URL" "$BASE_PATH/../$BUILD_DIR"
    else
        git clone "$REPO_URL" "$BASE_PATH/../$BUILD_DIR"
    fi
    cd "$BASE_PATH/../$BUILD_DIR"
    if [[ "$COMMIT_HASH" != "none" ]]; then
        git checkout "$COMMIT_HASH"
    fi
    cd "$BASE_PATH/.."
else
    # 检查当前仓库URL是否匹配
    cd "$BASE_PATH/../$BUILD_DIR"
    current_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ "$current_url" != "$REPO_URL" ]]; then
        echo "Repository URL changed, re-cloning..."
        cd "$BASE_PATH/.."
        rm -rf "$BUILD_DIR"
        if [[ -n "$REPO_BRANCH" ]]; then
            git clone -b "$REPO_BRANCH" "$REPO_URL" "$BUILD_DIR"
        else
            git clone "$REPO_URL" "$BUILD_DIR"
        fi
        cd "$BUILD_DIR"
        if [[ "$COMMIT_HASH" != "none" ]]; then
            git checkout "$COMMIT_HASH"
        fi
        cd "$BASE_PATH/.."
    else
        # 检查分支是否匹配
        current_branch=$(git branch --show-current 2>/dev/null || echo "")
        if [[ -n "$REPO_BRANCH" && "$current_branch" != "$REPO_BRANCH" ]]; then
            echo "Branch changed, switching to $REPO_BRANCH..."
            git checkout "$REPO_BRANCH"
            if [[ "$COMMIT_HASH" != "none" ]]; then
                git checkout "$COMMIT_HASH"
            fi
        fi
        cd "$BASE_PATH/.."
    fi
fi

# 执行 DIY 脚本
if [ -f "Scripts/diy-part1.sh" ]; then
    chmod +x "Scripts/diy-part1.sh"
    "Scripts/diy-part1.sh"
fi

if [ -f "Scripts/diy-part2.sh" ]; then
    chmod +x "Scripts/diy-part2.sh"
    "Scripts/diy-part2.sh"
fi

apply_config
fix_recursive_dependencies
remove_uhttpd_dependency

cd "$BASE_PATH/../$BUILD_DIR"

# 设置环境变量确保完全非交互式
export KCONFIG_CONFIG=.config
export KCONFIG_NOTIMESTAMP=true
export KCONFIG_AUTOCONFIG=1

# 为内核编译添加非交互式处理
echo "export KCONFIG_AUTOCONFIG=1" >> .profile
echo "export KCONFIG_NOTIMESTAMP=true" >> .profile
echo "export KCONFIG_CONFIG=.config" >> .profile
source .profile

make defconfig

if [[ $Build_Mod == "debug" ]]; then
    exit 0
fi

TARGET_DIR="$BASE_PATH/../$BUILD_DIR/bin/targets"
if [[ -d $TARGET_DIR ]]; then
    find "$TARGET_DIR" -type f \( -name "*.bin" -o -name "*.manifest" -o -name "*efi.img.gz" -o -name "*.itb" -o -name "*.fip" -o -name "*.ubi" -o -name "*rootfs.tar.gz" \) -exec rm -f {} +
fi

make download -j$(($(nproc) * 2))
make -j$(($(nproc) + 1)) || make -j1 V=s

FIRMWARE_DIR="$BASE_PATH/../firmware"
\rm -rf "$FIRMWARE_DIR"
mkdir -p "$FIRMWARE_DIR"
find "$TARGET_DIR" -type f \( -name "*.bin" -o -name "*.manifest" -o -name "*efi.img.gz" -o -name "*.itb" -o -name "*.fip" -o -name "*.ubi" -o -name "*rootfs.tar.gz" \) -exec cp -f {} "$FIRMWARE_DIR/" \;
\rm -f "$BASE_PATH/../firmware/Packages.manifest" 2>/dev/null

if [[ -d action_build ]]; then
    make clean
fi