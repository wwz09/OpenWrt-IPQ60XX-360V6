#!/bin/bash

# LibWrt 多设备构建脚本
# 作者：李杰

# 启用错误处理
set -e

# 检查必要的命令是否存在
function check_commands() {
    local commands=(git make curl awk grep sed)
    local missing=0
    
    echo "检查必要的命令..."
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "❌ 缺少命令: $cmd"
            missing=1
        else
            echo "✅ 命令存在: $cmd"
        fi
    done
    
    if [ $missing -eq 1 ]; then
        echo "========================================"
        echo "错误: 缺少必要的命令，请安装后再运行"
        echo "========================================"
        exit 1
    fi
}

# 检查环境
function check_environment() {
    echo "检查构建环境..."
    
    # 检查是否在 Linux 环境中
    if [[ "$(uname -s)" != "Linux" ]]; then
        echo "⚠️ 警告: 建议在 Linux 环境中运行构建脚本"
        echo "当前环境: $(uname -s)"
    fi
    
    # 检查磁盘空间
    if command -v df &> /dev/null; then
        local free_space=$(df -h | grep "^/dev/" | head -1 | awk '{print $4}')
        echo "可用磁盘空间: $free_space"
    fi
}

# 重试命令
function retry() {
    local max_attempts=3
    local attempt=1
    local delay=5
    
    while [ $attempt -le $max_attempts ]; do
        echo "尝试 $attempt/$max_attempts: $@"
        if "$@"; then
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            echo "失败，$delay 秒后重试..."
            sleep $delay
            attempt=$((attempt + 1))
            delay=$((delay * 2))
        else
            echo "已达到最大重试次数"
            return 1
        fi
    done
}

# 默认参数
DEFAULT_CONFIG="wrt_core/deconfig/jdcloud_re-ss-01.config"
DEVICE_CONFIG=""
# 限制并行编译线程为 1，最小化内存使用
THREADS=1

# 检查环境和命令
check_environment
check_commands

# 打印系统信息（精简）
echo "========================================"
echo "系统信息:"
echo "========================================"
if command -v nproc &> /dev/null; then
    echo "CPU 核心数: $(nproc)"
else
    echo "CPU 核心数: 未知"
fi

if command -v free &> /dev/null; then
    echo "内存总量: $(free -h | grep Mem | awk '{print $2}')"
else
    echo "内存总量: 未知"
fi

if command -v df &> /dev/null; then
    echo "可用磁盘: $(df -h | grep -E '^/dev/' | head -1 | awk '{print $4}')"
else
    echo "可用磁盘: 未知"
fi
echo "========================================"

# 显示帮助信息
function show_help() {
    echo "========================================"
    echo "LibWrt 多设备构建脚本"
    echo "========================================"
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help      显示帮助信息"
    echo "  -d, --dir       指定源码目录 (默认: $SOURCE_DIR)"
    echo "  -c, --config    指定配置文件 (默认: $DEFAULT_CONFIG)"
    echo "  -t, --threads   指定构建线程数 (默认: $THREADS)"
    echo "  -D, --device    指定设备型号 (可选)"
    echo ""
    echo "支持的设备:"
    echo "  jdcloud_re-ss-01    京东云 re-ss-01"
    echo "  link_nn6000-v1      Link NN6000-v1"
    echo "  link_nn6000-v2      Link NN6000-v2"
    echo "  qihoo_360v6         360V6"
    echo "  xiaomi_ax1800       小米 AX1800"
    echo "  zn_m2               ZN M2"
    echo "  cmcc_rax3000m_nand  CMCC RAX3000M (NAND 版本)"
    echo ""
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dir)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -c|--config)
            DEFAULT_CONFIG="$2"
            shift 2
            ;;
        -t|--threads)
            THREADS="$2"
            shift 2
            ;;
        -D|--device)
            DEVICE_CONFIG="wrt_core/deconfig/$2.config"
            shift 2
            ;;
        *)
            echo "错误：未知选项 $1"
            show_help
            exit 1
            ;;
    esac
done

# 主构建流程
echo "========================================"
echo "LibWrt 多设备构建脚本"
echo "========================================"

# 为每个设备使用独立的构建目录
if [ -n "$DEVICE_CONFIG" ]; then
    DEVICE_NAME=$(basename "$DEVICE_CONFIG" .config)
    SOURCE_DIR="openwrt-${DEVICE_NAME}"
else
    SOURCE_DIR="openwrt"
fi

# 1. 管理源码
if [ ! -d "$SOURCE_DIR" ]; then
    echo "克隆 LibWrt 源码..."
    retry git clone --depth 1 --single-branch -b main-nss https://github.com/LiBwrt/openwrt-6.x.git "$SOURCE_DIR"
    cd "$SOURCE_DIR"
else
    echo "更新 LibWrt 源码..."
    cd "$SOURCE_DIR"
    retry git fetch && git reset --hard origin/main-nss
fi

# 复制 feeds 配置文件
echo "复制 feeds 配置文件..."
cp "../feeds.conf.default" .

# 2. 运行自定义脚本第一部分
echo "运行自定义脚本第一部分..."
if [ -f "../Scripts/diy-part1.sh" ]; then
    retry bash ../Scripts/diy-part1.sh
else
    echo "警告：未找到 diy-part1.sh 脚本"
fi

# 3. 更新 feeds
echo "更新 feeds..."
retry ./scripts/feeds update -a
retry ./scripts/feeds install -a

# 4. 应用配置
if [ -n "$DEVICE_CONFIG" ]; then
    echo "应用设备配置: $(basename "$DEVICE_CONFIG" .config)"
    if [ -f "../$DEVICE_CONFIG" ]; then
        cp "../$DEVICE_CONFIG" .config
        make defconfig
    else
        echo "错误：未找到设备配置文件 $DEVICE_CONFIG"
        exit 1
    fi
else
    echo "应用默认配置..."
    if [ -f "../$DEFAULT_CONFIG" ]; then
        cp "../$DEFAULT_CONFIG" .config
        make defconfig
    else
        echo "错误：未找到默认配置文件 $DEFAULT_CONFIG"
        exit 1
    fi
fi

# 5. 运行自定义脚本第二部分
echo "运行自定义脚本第二部分..."
if [ -f "../Scripts/diy-part2.sh" ]; then
    retry bash ../Scripts/diy-part2.sh
else
    echo "警告：未找到 diy-part2.sh 脚本"
fi

# 6. 开始构建
echo "开始构建..."
echo "========================================"
echo "构建前内存使用:"
free -h | grep Mem

# 尝试构建，只输出错误信息
echo "开始编译..."
echo "========================================"

# 运行构建，捕获错误信息
BUILD_OUTPUT=$(make -j"$THREADS" 2>&1)
BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo "========================================"
    echo "构建完成！"
    echo "========================================"
else
    echo "========================================"
    echo "构建失败！显示错误信息:"
    echo "========================================"
    # 只显示错误信息
    echo "$BUILD_OUTPUT" | grep -E "(error|Error|ERROR|failed|Failed|FAILED)"
    echo "========================================"
    echo "内存使用:"
    free -h | grep Mem
    echo "磁盘空间:"
    df -h | grep /dev/sda1
    echo "========================================"
    echo "构建失败，请查看详细日志..."
    exit 1
fi

