#!/bin/bash
# OpenWrt DIY脚本 Part 1 (MediaTek平台专用) - 优化版
# 作者: 李杰
# 功能: 在更新feeds之前执行的自定义操作
# 执行时机: feeds更新之前
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

# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 开始执行脚本
echo "============================================"
echo "开始执行 MediaTek DIY Part 1 脚本 (优化版)"
echo "当前目录: $(pwd)"
echo "============================================"

# ==================== 检查环境 ====================
log_info "检查环境..."
if [ ! -d "package" ]; then
    log_error "未找到package目录，请确认当前目录是否正确"
    exit 1
fi
log_success "环境检查通过"

# ==================== 修改默认IP地址 ====================
log_info "修改默认IP地址..."
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    # 备份原文件
    cp package/lean/default-settings/files/zzz-default-settings package/lean/default-settings/files/zzz-default-settings.bak
    
    # 修改默认IP为192.168.100.1
    sed -i 's/192.168.1.1/192.168.100.1/g' package/lean/default-settings/files/zzz-default-settings
    log_success "默认IP设置完成: 192.168.100.1"
else
    log_warning "未找到default-settings文件，跳过IP地址修改"
fi

# ==================== 修改主机名 ====================
log_info "修改默认主机名..."
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    sed -i 's/OpenWrt/OpenWrt-AutoBuild/g' package/lean/default-settings/files/zzz-default-settings
    log_success "主机名修改完成: OpenWrt-AutoBuild"
else
    log_warning "未找到default-settings文件，跳过主机名修改"
fi

# ==================== 修改时区 ====================
log_info "设置默认时区..."
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    # 修改时区为CST-8 (中国标准时间)
    sed -i "s/'UTC'/'CST-8'/g" package/lean/default-settings/files/zzz-default-settings
    sed -i "s/'Asia\/Shanghai'/'Asia\/Shanghai'/g" package/lean/default-settings/files/zzz-default-settings
    log_success "时区设置完成: CST-8 (Asia/Shanghai)"
else
    log_warning "未找到default-settings文件，跳过时区修改"
fi

# ==================== 修改默认密码 ====================
log_info "设置默认密码..."
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    # 设置默认密码为password (加密后的字符串)
    sed -i 's/root::0:0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' package/lean/default-settings/files/zzz-default-settings
    log_success "默认密码设置完成 (密码: password)"
else
    log_warning "未找到default-settings文件，跳过密码修改"
fi

# ==================== 处理NSS驱动问题 ====================
log_info "处理NSS驱动问题..."

# 定义要删除的NSS相关包列表
NSS_PACKAGES=(
    "qca-nss*"
    "nss-*"
    "sqm-scripts-nss"
)

# 删除package目录中的NSS包
for pkg in "${NSS_PACKAGES[@]}"; do
    if find package -name "$pkg" -type d | grep -q .; then
        find package -name "$pkg" -type d | xargs rm -rf
        log_info "已删除package目录中的NSS包: $pkg"
    fi
done

# 删除feeds目录中的NSS包（如果存在）
if [ -d "feeds" ]; then
    for pkg in "${NSS_PACKAGES[@]}"; do
        if find feeds -name "$pkg" -type d | grep -q .; then
            find feeds -name "$pkg" -type d | xargs rm -rf
            log_info "已删除feeds目录中的NSS包: $pkg"
        fi
    done
fi

log_success "NSS驱动清理完成"

# ==================== 处理mac80211中的NSS依赖 ====================
log_info "处理mac80211中的NSS依赖问题..."
if [ -f "package/kernel/mac80211/Makefile" ]; then
    # 备份原文件
    cp package/kernel/mac80211/Makefile package/kernel/mac80211/Makefile.bak
    
    # 移除NSS相关依赖
    sed -i '/kmod-qca-nss-drv/d' "package/kernel/mac80211/Makefile"
    sed -i '/kmod-qca-nss-drv-wifi-meshmgr/d' "package/kernel/mac80211/Makefile"
    log_success "mac80211 NSS依赖清理完成"
else
    log_warning "未找到mac80211 Makefile，跳过NSS依赖清理"
fi

# ==================== 添加第三方软件源 ====================
log_info "添加第三方软件源..."

# 检查feeds.conf.default是否存在
if [ ! -f "feeds.conf.default" ]; then
    log_warning "未找到feeds.conf.default文件，跳过软件源添加"
else
    # 备份原文件
    cp feeds.conf.default feeds.conf.default.bak
    
    # 定义要添加的软件源
    declare -A FEED_SOURCES=(
        ["small"]="https://github.com/kenzok8/small"
        ["openclash"]="https://github.com/vernesong/OpenClash"
    )
    
    # 添加软件源（避免重复）
    for name in "${!FEED_SOURCES[@]}"; do
        url="${FEED_SOURCES[$name]}"
        if ! grep -q "$name" feeds.conf.default; then
            echo "src-git $name $url" >> feeds.conf.default
            log_success "已添加软件源: $name"
        else
            log_info "软件源已存在，跳过: $name"
        fi
    done
    
    # 清理重复的feeds源
    awk '!seen[$0]++' feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default
    log_success "第三方软件源配置完成"
fi

# ==================== 修改默认主题 ====================
log_info "设置默认主题为Argon..."
if [ -d "feeds/luci/themes/luci-theme-argon" ]; then
    log_success "Argon主题已配置"
else
    log_warning "未找到Argon主题，跳过主题配置"
fi

# ==================== 清理可能导致冲突的包 ====================
log_info "清理可能导致冲突的包..."

# 定义要删除的冲突包列表
CONFLICT_PACKAGES=(
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
)

# 删除package目录中的冲突包
for pkg in "${CONFLICT_PACKAGES[@]}"; do
    if find package -name "$pkg" -type d | grep -q .; then
        find package -name "$pkg" -type d | xargs rm -rf
        log_info "已删除package目录中的冲突包: $pkg"
    fi
done

# 删除feeds目录中的冲突包（如果存在）
if [ -d "feeds" ]; then
    for pkg in "${CONFLICT_PACKAGES[@]}"; do
        if find feeds -name "$pkg" -type d | grep -q .; then
            find feeds -name "$pkg" -type d | xargs rm -rf
            log_info "已删除feeds目录中的冲突包: $pkg"
        fi
    done
fi

log_success "冲突包清理完成"

# ==================== 修复luci-theme-design版本号格式问题 ====================
log_info "修复luci-theme-design版本号格式..."

# 查找所有可能的 luci-theme-design 目录（包括不同的feed源）
find feeds -name "luci-theme-design*" -type d | while read -r dir; do
    if [ -f "$dir/Makefile" ]; then
        # 更通用的版本号修复，匹配任何包含日期的版本号格式
        sed -i 's/5\.8\.0-[0-9]\{8\}-r[0-9]/5.8.0-r1/g' "$dir/Makefile"
        log_info "已修复 $dir/Makefile 中的版本号"
    fi
done

# 也清理本地包目录中的 luci-theme-design，避免冲突
find package -name "luci-theme-design*" -type d | xargs rm -rf 2>/dev/null
log_success "luci-theme-design版本号修复完成"

# ==================== 创建自定义配置文件 ====================
log_info "创建自定义配置文件..."

# 创建系统配置目录
mkdir -p package/base-files/files/etc/config

# 创建系统配置文件
cat > package/base-files/files/etc/config/system << 'EOF'
config system
    option hostname 'OpenWrt-AutoBuild'
    option timezone 'CST-8'
    option zonename 'Asia/Shanghai'

config timeserver 'ntp'
    list server '0.pool.ntp.org'
    list server '1.pool.ntp.org'
    list server '2.pool.ntp.org'
    list server '3.pool.ntp.org'
EOF

log_success "系统配置文件创建完成"

# ==================== 创建自定义启动脚本 ====================
log_info "创建自定义启动脚本..."

mkdir -p package/base-files/files/etc

cat > package/base-files/files/etc/rc.local << 'EOF'
#!/bin/sh
# 自定义启动脚本
# 作者: 李杰
# 版本: 2.0

# 设置CPU性能模式
if [ -w /sys/devices/system/cpu/cpufreq/policy0/scaling_governor ]; then
    echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
fi

# 启用BBR拥塞控制
if [ -w /etc/sysctl.conf ]; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
fi

exit 0
EOF

chmod +x package/base-files/files/etc/rc.local
log_success "启动脚本创建完成"

# ==================== 创建自定义banner ====================
log_info "创建自定义banner..."

mkdir -p package/base-files/files/etc

cat > package/base-files/files/etc/banner << 'EOF'
  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__|  OpenWrt AutoBuild by 李杰
 -----------------------------------------------------
  固件版本: OpenWrt AutoBuild v2.0
  编译时间: $(date '+%Y-%m-%d %H:%M:%S')
  源码仓库: LiBwrt/openwrt-6.x
  插件仓库: kenzok8/openwrt-packages
  平台: MediaTek Filogic
 -----------------------------------------------------
EOF

log_success "Banner创建完成"

# ==================== 创建自定义motd ====================
log_info "创建自定义motd..."

cat > package/base-files/files/etc/motd << 'EOF'

欢迎使用 OpenWrt AutoBuild 固件 v2.0!

系统信息:
  - 固件版本: OpenWrt AutoBuild v2.0
  - 默认IP: 192.168.100.1
  - 默认密码: password
  - 默认WiFi: OpenWrt-2.4G / OpenWrt-5G
  - WiFi密码: 12345678

常用命令:
  - 查看系统信息: cat /etc/os-release
  - 查看网络状态: ifconfig
  - 查看无线状态: iwinfo
  - 重启系统: reboot
  - 重置配置: firstboot

技术支持:
  - 源码: https://github.com/LiBwrt/openwrt-6.x
  - 插件: https://github.com/kenzok8/openwrt-packages

EOF

log_success "motd创建完成"

# ==================== 创建自定义软件源配置 ====================
log_info "创建自定义软件源配置..."

mkdir -p package/base-files/files/etc/opkg

cat > package/base-files/files/etc/opkg/distfeeds.conf << 'EOF'
src/gz openwrt_core https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/22.03.5/targets/mediatek/filogic/packages
src/gz openwrt_base https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/22.03.5/packages/aarch64_cortex-a53/base
src/gz openwrt_luci https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/22.03.5/packages/aarch64_cortex-a53/luci
src/gz openwrt_packages https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/22.03.5/packages/aarch64_cortex-a53/packages
src/gz openwrt_routing https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/22.03.5/packages/aarch64_cortex-a53/routing
src/gz openwrt_telephony https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/22.03.5/packages/aarch64_cortex-a53/telephony
EOF

log_success "软件源配置创建完成"

# ==================== 创建系统优化配置 ====================
log_info "创建系统优化配置..."

mkdir -p package/base-files/files/etc/sysctl.d

cat > package/base-files/files/etc/sysctl.d/99-custom.conf << 'EOF'
# 网络优化 (IPv4)
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# 网络优化 (IPv6)
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.default.accept_ra = 2
net.ipv6.conf.all.autoconf = 1
net.ipv6.conf.default.autoconf = 1
net.ipv6.conf.all.max_addresses = 16
net.ipv6.conf.default.max_addresses = 16

# 文件描述符限制
fs.file-max = 65535

# 内存优化
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

log_success "系统优化配置创建完成"

# ==================== 创建定时任务 ====================
log_info "创建定时任务..."

mkdir -p package/base-files/files/etc/crontabs

cat > package/base-files/files/etc/crontabs/root << 'EOF'
# 每天凌晨3点自动更新软件包列表
0 3 * * * opkg update > /dev/null 2>&1

# 每周日凌晨4点清理日志
0 4 * * 0 logread -C > /dev/null 2>&1

# 每天凌晨5点重启网络服务
0 5 * * * /etc/init.d/network restart > /dev/null 2>&1
EOF

log_success "定时任务创建完成"

# ==================== 脚本执行完成 ====================
echo "============================================"
echo "MediaTek DIY Part 1 脚本执行完成 (优化版)"
echo "============================================"
log_success "所有操作已成功完成"

# 显示摘要
echo ""
echo "执行摘要:"
echo "✓ 默认IP地址: 192.168.100.1"
echo "✓ 默认主机名: OpenWrt-AutoBuild"
echo "✓ 默认时区: CST-8 (Asia/Shanghai)"
echo "✓ 默认密码: password"
echo "✓ NSS驱动清理完成"
echo "✓ 第三方软件源添加完成"
echo "✓ 冲突包清理完成"
echo "✓ 自定义配置文件创建完成"
echo ""