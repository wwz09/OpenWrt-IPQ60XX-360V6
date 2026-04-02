#!/bin/bash
# OpenWrt Feeds配置管理脚本（优化版）
# 作者: 李杰
# 功能: 统一管理feeds配置，确保feeds源的正确性和一致性
# 执行时机: 在执行feeds更新之前
# 版本: 2.0
# 更新日期: 2026-04-02

# 设置错误处理
set -e  # 遇到错误立即退出
set -u  # 使用未定义变量时报错
set -o pipefail  # 管道命令失败时退出

# 定义日志函数
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 定义错误处理函数
handle_error() {
    log_error "脚本执行失败，错误发生在第 $1 行"
    exit 1
}

trap 'handle_error $LINENO' ERR

# 开始执行脚本
echo "============================================"
echo "开始执行 OpenWrt Feeds配置管理脚本 (优化版)"
echo "当前目录: $(pwd)"
echo "============================================"

# ==================== 检查环境 ====================
log_info "检查环境..."
if [ ! -d "package" ]; then
    log_error "未找到package目录，请确认当前目录是否正确"
    exit 1
fi
log_success "环境检查通过"

# ==================== 定义feeds源配置 ====================
log_info "定义feeds源配置..."

# 定义官方feeds源
declare -A OFFICIAL_FEEDS=(
    ["packages"]="https://github.com/immortalwrt/packages.git"
    ["luci"]="https://github.com/immortalwrt/luci.git"
    ["routing"]="https://github.com/openwrt/routing.git"
    ["telephony"]="https://github.com/openwrt/telephony.git"
)

# 定义第三方feeds源
declare -A THIRD_PARTY_FEEDS=(
    ["kenzo"]="https://github.com/kenzok8/openwrt-packages"
    ["small"]="https://github.com/kenzok8/small"
    ["fantastic_packages"]="https://github.com/fantastic-packages/packages.git;master"
    ["openclash"]="https://github.com/vernesong/OpenClash"
)

log_success "feeds源配置定义完成"

# ==================== 备份原始feeds配置 ====================
log_info "备份原始feeds配置..."

if [ -f "feeds.conf.default" ]; then
    # 创建备份目录
    mkdir -p .backups
    
    # 备份原始配置
    cp feeds.conf.default .backups/feeds.conf.default.$(date +%Y%m%d_%H%M%S).bak
    log_success "已备份原始feeds配置"
else
    log_warning "未找到feeds.conf.default文件，将创建新文件"
fi

# ==================== 创建新的feeds配置 ====================
log_info "创建新的feeds配置..."

# 创建新的feeds配置文件
cat > feeds.conf.default << 'EOF'
# OpenWrt Feeds配置文件
# 作者: 李杰
# 版本: 2.0
# 更新日期: 2026-04-02

# ==================== 官方feeds源 ====================
# 基础包源
src-git packages https://github.com/immortalwrt/packages.git

# LuCI界面源
src-git luci https://github.com/immortalwrt/luci.git

# 路由相关包源
src-git routing https://github.com/openwrt/routing.git

# 电话相关包源
src-git telephony https://github.com/openwrt/telephony.git

# ==================== 第三方feeds源 ====================
# kenzok8的常用软件包
src-git kenzo https://github.com/kenzok8/openwrt-packages

# kenzok8的代理软件依赖包
src-git small https://github.com/kenzok8/small

# fantastic-packages扩展包
src-git fantastic_packages https://github.com/fantastic-packages/packages.git;master

# OpenClash代理软件
src-git openclash https://github.com/vernesong/OpenClash
EOF

log_success "新的feeds配置创建完成"

# ==================== 验证feeds配置 ====================
log_info "验证feeds配置..."

# 检查配置文件是否存在
if [ ! -f "feeds.conf.default" ]; then
    log_error "feeds配置文件创建失败"
    exit 1
fi

# 检查配置文件内容
if [ ! -s "feeds.conf.default" ]; then
    log_error "feeds配置文件为空"
    exit 1
fi

# 检查是否有重复的feeds源
DUPLICATE_FEEDS=$(awk '{print $2}' feeds.conf.default | sort | uniq -d)
if [ -n "$DUPLICATE_FEEDS" ]; then
    log_warning "发现重复的feeds源: $DUPLICATE_FEEDS"
    # 清理重复的feeds源
    awk '!seen[$0]++' feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default
    log_success "已清理重复的feeds源"
else
    log_success "feeds配置验证通过，无重复源"
fi

# ==================== 清理旧的feeds目录 ====================
log_info "清理旧的feeds目录..."

# 检查是否存在feeds目录
if [ -d "feeds" ]; then
    # 备份旧的feeds目录
    if [ ! -d ".backups/feeds" ]; then
        mkdir -p .backups/feeds
    fi
    
    # 移动旧的feeds目录到备份目录
    mv feeds .backups/feeds/feeds.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    log_success "已备份旧的feeds目录"
else
    log_info "未找到旧的feeds目录，跳过清理"
fi

# ==================== 更新feeds ====================
log_info "更新feeds..."

# 执行feeds更新命令
if ./scripts/feeds update -a; then
    log_success "feeds更新完成"
else
    log_error "feeds更新失败"
    exit 1
fi

# ==================== 安装feeds ====================
log_info "安装feeds..."

# 执行feeds安装命令
if ./scripts/feeds install -a; then
    log_success "feeds安装完成"
else
    log_error "feeds安装失败"
    exit 1
fi

# ==================== 验证feeds安装 ====================
log_info "验证feeds安装..."

# 检查feeds目录是否存在
if [ ! -d "feeds" ]; then
    log_error "feeds目录不存在"
    exit 1
fi

# 统计feeds数量
FEED_COUNT=$(find feeds -maxdepth 1 -type d | wc -l)
log_success "已安装 $FEED_COUNT 个feeds"

# 显示feeds列表
log_info "已安装的feeds列表:"
ls -1 feeds/ | grep -v "^\.$" | grep -v "^\.\.$"

# ==================== 清理冲突包 ====================
log_info "清理冲突包..."

# 定义要清理的冲突包列表
declare -a CONFLICT_PACKAGES=(
    # NSS相关包
    "qca-nss*"
    "nss-*"
    "sqm-scripts-nss"
    
    # 冲突包
    "luci-app-fchomo"
    "nikki"
    "fwupd*"
    "onionshare-cli"
    "fail2ban"
    "setools"
    "trojan-plus"
    "luci-app-oaf"
    "luci-app-control-timewol"
    "luci-app-cpufreq"
    
    # Realtek相关包
    "*Realtek*"
    
    # 依赖冲突包
    "aic8800"
    "automount"
    "basicstation"
    "beep"
    "bigclown-gateway"
    "bluld"
    "comgt"
    "dmx_usb_module"
    "fibocom-qmi-wwan"
    "gl-puli-mcu"
    "keepalived"
)

# 清理feeds中的冲突包
for pkg in "${CONFLICT_PACKAGES[@]}"; do
    if find feeds -name "$pkg" -type d | grep -q .; then
        find feeds -name "$pkg" -type d | xargs rm -rf
        log_info "已删除feeds目录中的冲突包: $pkg"
    fi
done

log_success "冲突包清理完成"

# ==================== 修复版本号问题 ====================
log_info "修复版本号问题..."

# 修复luci-theme-design版本号格式
find feeds -name "luci-theme-design*" -type d | while read -r dir; do
    if [ -f "$dir/Makefile" ]; then
        # 修复版本号格式
        sed -i 's/5\.8\.0-[0-9]\{8\}-r[0-9]/5.8.0-r1/g' "$dir/Makefile"
        log_info "已修复 $dir/Makefile 中的版本号"
    fi
done

log_success "版本号问题修复完成"

# ==================== 创建feeds状态报告 ====================
log_info "创建feeds状态报告..."

# 创建状态报告文件
cat > feeds-status-report.txt << EOF
OpenWrt Feeds状态报告
====================
生成时间: $(date '+%Y-%m-%d %H:%M:%S')
作者: 李杰
版本: 2.0

Feeds配置:
--------
EOF

# 添加feeds配置到报告
cat feeds.conf.default >> feeds-status-report.txt

# 添加feeds统计信息到报告
cat >> feeds-status-report.txt << EOF

Feeds统计:
--------
总feeds数量: $FEED_COUNT

已安装的feeds:
--------
EOF

# 添加feeds列表到报告
ls -1 feeds/ | grep -v "^\.$" | grep -v "^\.\.$" >> feeds-status-report.txt

# 添加冲突包清理信息到报告
cat >> feeds-status-report.txt << EOF

已清理的冲突包:
--------
EOF

# 添加冲突包列表到报告
for pkg in "${CONFLICT_PACKAGES[@]}"; do
    echo "- $pkg" >> feeds-status-report.txt
done

log_success "feeds状态报告创建完成"

# ==================== 创建feeds更新脚本 ====================
log_info "创建feeds更新脚本..."

cat > update-feeds.sh << 'EOF'
#!/bin/bash
# Feeds更新脚本
# 作者: 李杰
# 版本: 2.0

echo "开始更新feeds..."

# 备份当前配置
if [ -f "feeds.conf.default" ]; then
    cp feeds.conf.default feeds.conf.default.bak
fi

# 更新feeds
./scripts/feeds update -a

# 安装feeds
./scripts/feeds install -a

echo "feeds更新完成"
EOF

chmod +x update-feeds.sh
log_success "feeds更新脚本创建完成"

# ==================== 创建feeds清理脚本 ====================
log_info "创建feeds清理脚本..."

cat > clean-feeds.sh << 'EOF'
#!/bin/bash
# Feeds清理脚本
# 作者: 李杰
# 版本: 2.0

echo "开始清理feeds..."

# 备份当前feeds
if [ -d "feeds" ]; then
    mkdir -p .backups/feeds
    mv feeds .backups/feeds/feeds.$(date +%Y%m%d_%H%M%S)
fi

# 清理临时文件
rm -rf tmp/* 2>/dev/null || true
rm -rf build_dir/* 2>/dev/null || true

echo "feeds清理完成"
EOF

chmod +x clean-feeds.sh
log_success "feeds清理脚本创建完成"

# ==================== 创建feeds验证脚本 ====================
log_info "创建feeds验证脚本..."

cat > validate-feeds.sh << 'EOF'
#!/bin/bash
# Feeds验证脚本
# 作者: 李杰
# 版本: 2.0

echo "开始验证feeds..."

# 检查feeds配置文件
if [ ! -f "feeds.conf.default" ]; then
    echo "错误: feeds.conf.default文件不存在"
    exit 1
fi

# 检查feeds目录
if [ ! -d "feeds" ]; then
    echo "错误: feeds目录不存在"
    exit 1
fi

# 检查是否有重复的feeds源
DUPLICATE_FEEDS=$(awk '{print $2}' feeds.conf.default | sort | uniq -d)
if [ -n "$DUPLICATE_FEEDS" ]; then
    echo "警告: 发现重复的feeds源: $DUPLICATE_FEEDS"
    exit 1
fi

# 检查feeds数量
FEED_COUNT=$(find feeds -maxdepth 1 -type d | wc -l)
if [ "$FEED_COUNT" -lt 5 ]; then
    echo "警告: feeds数量过少 ($FEED_COUNT)"
    exit 1
fi

echo "feeds验证通过"
exit 0
EOF

chmod +x validate-feeds.sh
log_success "feeds验证脚本创建完成"

# ==================== 脚本执行完成 ====================
echo "============================================"
echo "OpenWrt Feeds配置管理脚本执行完成 (优化版)"
echo "============================================"
log_success "所有操作已成功完成"

# 显示摘要
echo ""
echo "执行摘要:"
echo "✓ feeds源配置定义完成"
echo "✓ 原始feeds配置备份完成"
echo "✓ 新的feeds配置创建完成"
echo "✓ feeds配置验证完成"
echo "✓ 旧的feeds目录清理完成"
echo "✓ feeds更新完成"
echo "✓ feeds安装完成"
echo "✓ feeds安装验证完成"
echo "✓ 冲突包清理完成"
echo "✓ 版本号问题修复完成"
echo "✓ feeds状态报告创建完成"
echo "✓ feeds更新脚本创建完成"
echo "✓ feeds清理脚本创建完成"
echo "✓ feeds验证脚本创建完成"
echo ""
echo "现在可以使用以下脚本:"
echo "- ./update-feeds.sh  # 更新feeds"
echo "- ./clean-feeds.sh   # 清理feeds"
echo "- ./validate-feeds.sh # 验证feeds"
echo ""
echo "详细状态报告请查看: feeds-status-report.txt"
echo ""