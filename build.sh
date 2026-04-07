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
            SUPPORTED_DEVS+=("$dev_key")
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

apply_config() {
    \cp -f "$CONFIG_FILE" "$BASE_PATH/../$BUILD_DIR/.config"
    
    if grep -qE "(ipq60xx|ipq807x)" "$BASE_PATH/../$BUILD_DIR/.config" &&
        ! grep -q "CONFIG_GIT_MIRROR" "$BASE_PATH/../$BUILD_DIR/.config"; then
        cat "$BASE_PATH/deconfig/nss.config" >> "$BASE_PATH/../$BUILD_DIR/.config"
    fi

    cat "$BASE_PATH/deconfig/compile_base.config" >> "$BASE_PATH/../$BUILD_DIR/.config"

    cat "$BASE_PATH/deconfig/docker_deps.config" >> "$BASE_PATH/../$BUILD_DIR/.config"

    cat "$BASE_PATH/deconfig/proxy.config" >> "$BASE_PATH/../$BUILD_DIR/.config"
}

REPO_URL=$(read_ini_by_key "REPO_URL")
REPO_BRANCH=$(read_ini_by_key "REPO_BRANCH")
REPO_BRANCH=${REPO_BRANCH:-main}
BUILD_DIR=$(read_ini_by_key "BUILD_DIR")
COMMIT_HASH=$(read_ini_by_key "COMMIT_HASH")
COMMIT_HASH=${COMMIT_HASH:-none}

if [[ -d action_build ]]; then
    BUILD_DIR="action_build"
fi

"$BASE_PATH/update.sh" "$REPO_URL" "$REPO_BRANCH" "$BUILD_DIR" "$COMMIT_HASH"

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
remove_uhttpd_dependency

cd "$BASE_PATH/../$BUILD_DIR"

# 安装必要的系统依赖
echo "============================================"
echo "安装必要的系统依赖"
echo "============================================"
if command -v apt-get &> /dev/null; then
    sudo apt-get update -y
    sudo apt-get install -y ruby libev-dev lm-sensors libpam-dev libtirpc-dev liblzma-dev libzstd-dev libglib2.0-dev libgpiod-dev
fi

# 清理构建环境
echo "============================================"
echo "清理构建环境"
echo "============================================"
make clean
rm -rf build_dir/* staging_dir/* tmp/* logs/*

# 设置环境变量确保完全非交互式
export KCONFIG_CONFIG=.config
export KCONFIG_NOTIMESTAMP=true
export KCONFIG_AUTOCONFIG=1
export TERM=dumb
export CONFIG_SILENT=y
export DEBIAN_FRONTEND=noninteractive
export FORCE_UNSAFE_CONFIGURE=1
export NO_COLOR=1

# 为内核编译添加非交互式处理
echo "export KCONFIG_AUTOCONFIG=1" >> .profile
echo "export KCONFIG_NOTIMESTAMP=true" >> .profile
echo "export KCONFIG_CONFIG=.config" >> .profile
echo "export TERM=dumb" >> .profile
echo "export CONFIG_SILENT=y" >> .profile
echo "export DEBIAN_FRONTEND=noninteractive" >> .profile
echo "export FORCE_UNSAFE_CONFIGURE=1" >> .profile
echo "export NO_COLOR=1" >> .profile
source .profile

# 完全绕过 menuconfig，直接使用配置文件
export TERM=dumb
export KCONFIG_AUTOCONFIG=1
export KCONFIG_NOTIMESTAMP=true
export KCONFIG_CONFIG=.config
export CONFIG_SILENT=y
export DEBIAN_FRONTEND=noninteractive
export FORCE_UNSAFE_CONFIGURE=1
export NO_COLOR=1

# 直接复制配置文件，不使用任何可能调用 menuconfig 的命令
cp .config .config.tmp

# 检查配置文件是否存在
if [ ! -f ".config" ]; then
    echo "错误：配置文件 .config 不存在"
    exit 1
fi

echo "配置文件已准备就绪，跳过 menuconfig 调用"

# 手动创建必要的配置文件目录
mkdir -p include/config

# 生成 auto.conf 文件（menuconfig 的替代方案）
awk '/^CONFIG_/ {print $1}' .config > include/config/auto.conf

# 生成 auto.conf.cmd 文件
touch include/config/auto.conf.cmd

# 生成 .config.cmd 文件
touch .config.cmd

# 直接使用配置文件，完全绕过 menuconfig
# 跳过 make defconfig，避免触发 menuconfig
echo "配置文件已准备就绪，跳过所有配置步骤"

# 确保配置文件的时间戳是最新的
touch .config include/config/auto.conf include/config/auto.conf.cmd .config.cmd

# 确保配置文件存在且完整
if [ ! -f ".config" ]; then
    echo "错误：配置文件 .config 不存在"
    exit 1
fi

# 生成 Makefile 依赖文件，避免构建系统自动调用 menuconfig
echo "生成 Makefile 依赖文件..."
if [ -f "Makefile" ]; then
    # 手动创建 .config.cmd 文件，告诉构建系统配置已经完成
    echo "# Automatically generated - do not edit!" > .config.cmd
    echo "CONFIG_SHELL := /bin/sh" >> .config.cmd
    echo "KCONFIG_CONFIG := .config" >> .config.cmd
fi

# 创建假的 menuconfig 脚本，当构建系统尝试运行它时，它会简单地退出
echo "创建假的 menuconfig 脚本..."
if [ -d "scripts/config" ]; then
    cat > scripts/config/mconf << 'EOF'
#!/bin/sh
# 假的 menuconfig 脚本，用于在非交互式环境中避免终端错误
echo "跳过 menuconfig，使用现有配置文件"
exit 0
EOF
    chmod +x scripts/config/mconf
    
    # 同样创建假的 menuconfig 脚本
    cat > scripts/config/menuconfig << 'EOF'
#!/bin/sh
# 假的 menuconfig 脚本，用于在非交互式环境中避免终端错误
echo "跳过 menuconfig，使用现有配置文件"
exit 0
EOF
    chmod +x scripts/config/menuconfig
fi

# 确保配置文件的时间戳是最新的
touch .config include/config/auto.conf include/config/auto.conf.cmd .config.cmd

if grep -qE "^CONFIG_TARGET_x86_64=y" "$CONFIG_FILE"; then
    DISTFEEDS_PATH="$BASE_PATH/../$BUILD_DIR/package/emortal/default-settings/files/99-distfeeds.conf"
    if [ -d "${DISTFEEDS_PATH%/*}" ] && [ -f "$DISTFEEDS_PATH" ]; then
        sed -i 's/aarch64_cortex-a53/x86_64/g' "$DISTFEEDS_PATH"
    fi
fi

if [[ $Build_Mod == "debug" ]]; then
    exit 0
fi

TARGET_DIR="$BASE_PATH/../$BUILD_DIR/bin/targets"
if [[ -d $TARGET_DIR ]]; then
    find "$TARGET_DIR" -type f \( -name "*.bin" -o -name "*.manifest" -o -name "*efi.img.gz" -o -name "*.itb" -o -name "*.fip" -o -name "*.ubi" -o -name "*rootfs.tar.gz" \) -exec rm -f {} +
fi

# 执行下载，添加 KCONFIG 相关参数避免 menuconfig
make KCONFIG_AUTOCONFIG=1 KCONFIG_NOTIMESTAMP=true CONFIG_SILENT=y KCONFIG_NOHELP=1 KCONFIG_NOSAVECONFIG=1 KCONFIG_NOWARNING=1 DOWNLOAD_FOLDER=/tmp DL_DIR=/tmp download -j$(($(nproc) * 2))

# 跳过 oldconfig，因为我们已经手动创建了所有必要的配置文件
# 完全避免任何可能触发 menuconfig 的命令

echo "跳过 oldconfig，使用手动创建的配置文件"

# 使用单线程构建，便于排查错误，同样添加参数避免 menuconfig
make KCONFIG_AUTOCONFIG=1 KCONFIG_NOTIMESTAMP=true CONFIG_SILENT=y KCONFIG_NOHELP=1 KCONFIG_NOSAVECONFIG=1 KCONFIG_NOWARNING=1 -j1 V=s

FIRMWARE_DIR="$BASE_PATH/../firmware"
\rm -rf "$FIRMWARE_DIR"
mkdir -p "$FIRMWARE_DIR"
find "$TARGET_DIR" -type f \( -name "*.bin" -o -name "*.manifest" -o -name "*efi.img.gz" -o -name "*.itb" -o -name "*.fip" -o -name "*.ubi" -o -name "*rootfs.tar.gz" \) -exec cp -f {} "$FIRMWARE_DIR/" \;
\rm -f "$BASE_PATH/../firmware/Packages.manifest" 2>/dev/null

if [[ -d action_build ]]; then
    make clean
fi
