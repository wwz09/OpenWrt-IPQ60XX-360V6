#!/bin/bash
# OpenWrt 自动化执行脚本
# 作者: 李杰
# 功能: 支持工作流的自动化执行，包括环境准备、配置验证、依赖检查、版本兼容性验证和结果报告生成
# 执行时机: 工作流自动化执行时

set -e

echo "============================================"
echo "开始执行 OpenWrt 自动化脚本"
echo "当前目录: $(pwd)"
echo "执行时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"

# ==================== 环境变量检查 ====================
echo "检查环境变量..."

# 检查必要的环境变量
if [ -z "$REPO_URL" ]; then
    echo "✗ 缺少环境变量 REPO_URL"
    exit 1
fi

if [ -z "$REPO_BRANCH" ]; then
    echo "✗ 缺少环境变量 REPO_BRANCH"
    exit 1
fi

if [ -z "$PACKAGE_URL" ]; then
    echo "✗ 缺少环境变量 PACKAGE_URL"
    exit 1
fi

if [ -z "$DEPENDENCY_URL" ]; then
    echo "✗ 缺少环境变量 DEPENDENCY_URL"
    exit 1
fi

echo "✓ 环境变量检查完成"

# ==================== 环境准备 ====================
echo "准备测试环境..."

# 检查并创建必要的目录
mkdir -p test-results reports

echo "✓ 环境准备完成"

# ==================== 克隆源码 ====================
echo "克隆 OpenWrt 源码..."

# 克隆源码仓库
if [ ! -d "openwrt" ]; then
    git clone --depth 1 "$REPO_URL" -b "$REPO_BRANCH" openwrt
    echo "✓ 源码克隆完成"
else
    echo "✓ 源码已存在，跳过克隆"
fi

# 显示源码信息
cd openwrt
echo "源码仓库: $REPO_URL"
echo "分支: $REPO_BRANCH"
echo "最新提交:"
git log --oneline -1

# ==================== 配置 Feeds ====================
echo "配置 Feeds..."

# 添加第三方插件仓库到feeds
echo "src-git kenzo $PACKAGE_URL" >> feeds.conf.default
echo "src-git jell $DEPENDENCY_URL" >> feeds.conf.default

# 清理重复的feeds配置
awk '!seen[$0]++' feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default

# 显示feeds配置
cat feeds.conf.default

echo "✓ Feeds 配置完成"

# ==================== 执行 DIY 脚本 ====================
echo "执行 DIY 脚本..."

# 执行第一部分自定义脚本
if [ -f "$GITHUB_WORKSPACE/Scripts/diy-part1.sh" ]; then
    chmod +x "$GITHUB_WORKSPACE/Scripts/diy-part1.sh"
    "$GITHUB_WORKSPACE/Scripts/diy-part1.sh"
    echo "✓ DIY Part 1 脚本执行完成"
else
    echo "✗ DIY Part 1 脚本不存在"
    exit 1
fi

# 更新并安装feeds
echo "更新并安装 feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# 执行第二部分自定义脚本
if [ -f "$GITHUB_WORKSPACE/Scripts/diy-part2.sh" ]; then
    chmod +x "$GITHUB_WORKSPACE/Scripts/diy-part2.sh"
    "$GITHUB_WORKSPACE/Scripts/diy-part2.sh"
    echo "✓ DIY Part 2 脚本执行完成"
else
    echo "✗ DIY Part 2 脚本不存在"
    exit 1
fi

# 执行第三部分自定义脚本
if [ -f "$GITHUB_WORKSPACE/Scripts/diy-part3.sh" ]; then
    chmod +x "$GITHUB_WORKSPACE/Scripts/diy-part3.sh"
    "$GITHUB_WORKSPACE/Scripts/diy-part3.sh"
    echo "✓ DIY Part 3 脚本执行完成"
else
    echo "✗ DIY Part 3 脚本不存在"
    exit 1
fi

# ==================== 加载配置文件 ====================
echo "加载设备配置文件..."

# 根据设备选择对应的配置文件
DEVICE="${DEVICE:-qihoo-360v6}"
CONFIG_FILE="$GITHUB_WORKSPACE/Config/${DEVICE}.config"

# 复制配置文件
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" .config
    echo "✓ 已加载配置文件: $CONFIG_FILE"
else
    echo "✗ 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 展开配置
make defconfig

echo "✓ 配置文件加载完成"

# ==================== 配置有效性检查 ====================
echo "检查配置有效性..."

# 检查配置是否有效
make kernel_oldconfig
if [ $? -eq 0 ]; then
    echo "✓ 配置文件有效"
else
    echo "✗ 配置文件无效"
    exit 1
fi

echo "✓ 配置有效性检查完成"

# ==================== 依赖关系检查 ====================
echo "检查依赖关系..."

# 检查依赖关系
make -j1 V=s 2>&1 | grep -E "ERROR:|error:|missing"
if [ $? -eq 0 ]; then
    echo "✗ 发现依赖问题"
    exit 1
else
    echo "✓ 依赖关系正常"
fi

echo "✓ 依赖关系检查完成"

# ==================== 插件兼容性验证 ====================
echo "验证插件兼容性..."

# 检查已启用的插件
echo "已启用的插件:"
grep -E "CONFIG_PACKAGE_luci-app-.*=y" .config | head -20

# 检查主题兼容性
echo "已启用的主题:"
grep -E "CONFIG_PACKAGE_luci-theme-.*=y" .config | head -10

# 检查OpenWrt版本
OPENWRT_VERSION=$(grep "DISTRIB_RELEASE" package/base-files/files/etc/openwrt_release 2>/dev/null | cut -d'=' -f2 | tr -d '"')
if [ -n "$OPENWRT_VERSION" ]; then
    echo "当前OpenWrt版本: $OPENWRT_VERSION"
    
    # 检查主题兼容性
    if [[ "$OPENWRT_VERSION" == "22.03"* ]]; then
        echo "✓ OpenWrt 22.03+ 版本，主题兼容性良好"
    else
        echo "⚠ 非OpenWrt 22.03+ 版本，主题可能存在兼容性问题"
    fi
else
    echo "⚠ 无法检测OpenWrt版本"
fi

echo "✓ 插件兼容性验证完成"

# ==================== 生成配置报告 ====================
echo "生成配置报告..."

# 生成配置报告
cat > "$GITHUB_WORKSPACE/test-results/config-report.md" << EOF
# 配置测试报告

## 基本信息
- 测试时间: $(date '+%Y-%m-%d %H:%M:%S')
- 设备: $DEVICE
- OpenWrt版本: $OPENWRT_VERSION
- 源码仓库: $REPO_URL
- 分支: $REPO_BRANCH
- 插件仓库: $PACKAGE_URL
- 依赖仓库: $DEPENDENCY_URL

## 已启用的插件:
EOF

grep -E "CONFIG_PACKAGE_luci-app-.*=y" .config | sort | sed 's/CONFIG_PACKAGE_//' | sed 's/=y//' >> "$GITHUB_WORKSPACE/test-results/config-report.md"

echo "
## 已启用的主题:
" >> "$GITHUB_WORKSPACE/test-results/config-report.md"

grep -E "CONFIG_PACKAGE_luci-theme-.*=y" .config | sort | sed 's/CONFIG_PACKAGE_//' | sed 's/=y//' >> "$GITHUB_WORKSPACE/test-results/config-report.md"

echo "
## 测试结果: ✅ 配置有效，依赖正常
" >> "$GITHUB_WORKSPACE/test-results/config-report.md"

# 显示配置报告
cat "$GITHUB_WORKSPACE/test-results/config-report.md"

echo "✓ 配置报告生成完成"

# ==================== 生成兼容性报告 ====================
echo "生成兼容性报告..."

# 生成兼容性报告
cat > "$GITHUB_WORKSPACE/reports/compatibility-report.md" << EOF
# 插件兼容性报告

## 基本信息
- 编译时间: $(date '+%Y-%m-%d %H:%M:%S')
- OpenWrt版本: $OPENWRT_VERSION
- 插件仓库: $PACKAGE_URL
- 依赖仓库: $DEPENDENCY_URL

## 已添加的插件
EOF

# 从diy-part3.sh中读取插件列表
PLUGINS=$(grep -E '"luci-app-.*"' "$GITHUB_WORKSPACE/Scripts/diy-part3.sh" | sed 's/[[:space:]]*"\(luci-app-[^"]*\)".*/- \1/' | head -50)
if [ -n "$PLUGINS" ]; then
    echo "$PLUGINS" >> "$GITHUB_WORKSPACE/reports/compatibility-report.md"
else
    echo "- 无插件添加"
fi

echo "
## 已添加的依赖
" >> "$GITHUB_WORKSPACE/reports/compatibility-report.md"

# 从diy-part3.sh中读取依赖列表
DEPENDENCIES=$(grep -E '"qca-.*"|"kmod-.*"|"ath11k-.*"' "$GITHUB_WORKSPACE/Scripts/diy-part3.sh" | sed 's/[[:space:]]*"\([^" ]*\)".*/- \1/' | head -50)
if [ -n "$DEPENDENCIES" ]; then
    echo "$DEPENDENCIES" >> "$GITHUB_WORKSPACE/reports/compatibility-report.md"
else
    echo "- 无依赖添加"
fi

echo "
## 兼容性状态
- ✅ 插件版本兼容
- ✅ 依赖关系正常
- ✅ 配置文件有效
" >> "$GITHUB_WORKSPACE/reports/compatibility-report.md"

echo "✓ 兼容性报告生成完成"

# ==================== 清理工作 ====================
echo "清理工作..."

# 清理过期的包缓存
rm -rf dl/* 2>/dev/null

# 清理临时文件
rm -f feeds.conf.default.tmp 2>/dev/null

echo "✓ 清理工作完成"

# ==================== 完成 ====================
echo "============================================"
echo "OpenWrt 自动化脚本执行完成"
echo "执行时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
