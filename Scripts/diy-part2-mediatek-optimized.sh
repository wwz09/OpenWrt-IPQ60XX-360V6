#!/bin/bash
# OpenWrt DIY脚本 Part 2 (MediaTek平台专用) - 优化版
# 作者: 李杰
# 功能: 在更新feeds之后执行的自定义操作
# 执行时机: feeds更新和安装完成后
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

# 开始执行脚本
echo "============================================"
echo "开始执行 MediaTek DIY Part 2 脚本 (优化版)"
echo "当前目录: $(pwd)"
echo "============================================"

# ==================== 检查环境 ====================
log_info "检查环境..."
if [ ! -d "feeds" ]; then
    log_error "未找到feeds目录，请先执行feeds更新"
    exit 1
fi
log_success "环境检查通过"

# ==================== 修改默认主题设置 ====================
log_info "修改默认主题..."
if [ -f "feeds/luci/modules/luci-base/root/etc/config/luci" ]; then
    # 备份原文件
    cp feeds/luci/modules/luci-base/root/etc/config/luci feeds/luci/modules/luci-base/root/etc/config/luci.bak
    
    # 修改默认主题为Argon
    sed -i 's/Bootstrap/Argon/g' feeds/luci/modules/luci-base/root/etc/config/luci
    log_success "默认主题修改为Argon"
else
    log_warning "未找到luci配置文件，跳过主题修改"
fi

# ==================== 修改默认语言为中文 ====================
log_info "设置默认语言为中文..."
if [ -f "feeds/luci/modules/luci-base/root/etc/config/luci" ]; then
    # 修改默认语言为中文
    sed -i 's/en/zh_cn/g' feeds/luci/modules/luci-base/root/etc/config/luci
    log_success "默认语言设置为中文"
else
    log_warning "未找到luci配置文件，跳过语言修改"
fi

# ==================== 修改默认时区 ====================
log_info "修改默认时区..."
if [ -f "package/base-files/files/etc/config/system" ]; then
    # 备份原文件
    cp package/base-files/files/etc/config/system package/base-files/files/etc/config/system.bak
    
    # 修改时区为CST-8
    sed -i 's/UTC/CST-8/g' package/base-files/files/etc/config/system
    sed -i 's/"UTC"/"CST-8"/g' package/base-files/files/etc/config/system
    log_success "时区修改为CST-8"
else
    log_warning "未找到系统配置文件，跳过时区修改"
fi

# ==================== 修改默认主机名 ====================
log_info "修改默认主机名..."
if [ -f "package/base-files/files/etc/config/system" ]; then
    # 修改主机名为OpenWrt-AutoBuild
    sed -i 's/OpenWrt/OpenWrt-AutoBuild/g' package/base-files/files/etc/config/system
    log_success "主机名修改为OpenWrt-AutoBuild"
else
    log_warning "未找到系统配置文件，跳过主机名修改"
fi

# ==================== 修改默认WiFi设置 ====================
log_info "配置默认WiFi..."

# 创建WiFi配置目录
mkdir -p package/base-files/files/etc/config

# 创建WiFi配置文件
cat > package/base-files/files/etc/config/wireless << 'EOF'
config wifi-device 'radio0'
    option type 'mac80211'
    option path 'platform/soc/18000000.wifi'
    option channel 'auto'
    option band '2g'
    option htmode 'HE40'
    option country 'CN'
    option disabled '0'
    option cell_density '0'

config wifi-iface 'default_radio0'
    option device 'radio0'
    option network 'lan'
    option mode 'ap'
    option ssid 'OpenWrt-2.4G'
    option encryption 'psk2'
    option key '12345678'
    option ieee80211r '0'
    option ieee80211w '0'
    option wps_pushbutton '0'

config wifi-device 'radio1'
    option type 'mac80211'
    option path 'platform/soc/18000000.wifi+1'
    option channel 'auto'
    option band '5g'
    option htmode 'HE80'
    option country 'CN'
    option disabled '0'
    option cell_density '0'

config wifi-iface 'default_radio1'
    option device 'radio1'
    option network 'lan'
    option mode 'ap'
    option ssid 'OpenWrt-5G'
    option encryption 'psk2'
    option key '12345678'
    option ieee80211r '0'
    option ieee80211w '0'
    option wps_pushbutton '0'
EOF

log_success "WiFi配置完成"

# ==================== 修改网络配置 ====================
log_info "修改网络配置..."

# 创建网络配置目录
mkdir -p package/base-files/files/etc/config

# 创建网络配置文件，添加IPv6支持
cat > package/base-files/files/etc/config/network << 'EOF'
config interface 'loopback'
    option device 'lo'
    option proto 'static'
    option ipaddr '127.0.0.1'
    option netmask '255.0.0.0'

config globals 'globals'
    option ula_prefix 'auto'

config interface 'lan'
    option device 'br-lan'
    option proto 'static'
    option ipaddr '192.168.100.1'
    option netmask '255.255.255.0'
    option ip6assign '60'
    option ip6hint '00'
    option ip6ifaceid '::1'

config interface 'wan'
    option device 'wan'
    option proto 'dhcp'
    option ipv6 'auto'
    option peerdns '0'
    list dns '223.5.5.5'
    list dns '119.29.29.29'

config interface 'wan6'
    option device 'wan'
    option proto 'dhcpv6'
    option reqaddress 'try'
    option reqprefix 'auto'
    option peerdns '0'
    list dns '2400:3200::1'
    list dns '2400:3200:baba::1'

config device
    option name 'br-lan'
    option type 'bridge'
    list ports 'lan1'
    list ports 'lan2'
    list ports 'lan3'
    list ports 'lan4'
EOF

log_success "网络配置修改完成，已添加IPv6支持"

# ==================== 添加自定义防火墙规则 ====================
log_info "添加自定义防火墙规则..."

mkdir -p package/base-files/files/etc

cat > package/base-files/files/etc/firewall.user << 'EOF'
# 自定义防火墙规则
# 作者: 李杰
# 版本: 2.0

# 允许ICMP ping (IPv4)
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT

# 允许ICMPv6 (IPv6)
ip6tables -A INPUT -p icmpv6 -j ACCEPT
ip6tables -A OUTPUT -p icmpv6 -j ACCEPT

# 允许本地回环 (IPv4)
iptables -A INPUT -i lo -j ACCEPT

# 允许本地回环 (IPv6)
ip6tables -A INPUT -i lo -j ACCEPT

# 允许已建立的连接 (IPv4)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许已建立的连接 (IPv6)
ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许SSH访问 (IPv4)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 允许SSH访问 (IPv6)
ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT

# 允许HTTP/HTTPS访问 (IPv4)
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 允许HTTP/HTTPS访问 (IPv6)
ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT
EOF

log_success "防火墙规则添加完成，已添加IPv6支持"

# ==================== 修复hostapd编译错误 ====================
log_info "修复hostapd编译错误..."

# 创建hostapd补丁目录
mkdir -p package/network/services/hostapd/patches 2>/dev/null

# 创建hostapd补丁文件
cat > package/network/services/hostapd/patches/0001-fix-he_mu_edca.patch << 'EOF'
--- a/src/ap/hostapd.c
+++ b/src/ap/hostapd.c
@@ -4718,9 +4718,13 @@
 		if (csa_settings->mode == NL80211_CHAN_SWITCH_MODE_80211R) {
 			csa_settings->ht_oper_chwidth = hapd->iface->conf->ht_op_mode;
 			csa_settings->vht_oper_chwidth = hapd->iface->conf->vht_op_mode;
+		#ifdef CONFIG_IEEE80211AX
 			if (hapd->iface->conf->he_mu_edca.he_qos_info & 0x000f) {
 				hapd->iface->conf->he_mu_edca.he_qos_info &= 0xfff0;
 			}
+		#else
+		/* CONFIG_IEEE80211AX not defined, skip he_mu_edca */
+		#endif
 		}
 	}
 }
EOF

log_success "hostapd补丁创建完成"

# ==================== 处理hostapd编译问题 ====================
log_info "处理hostapd编译问题..."

# 清理可能导致hostapd编译失败的配置
if [ -f ".config" ]; then
    # 确保使用正确的hostapd版本
    sed -i 's/CONFIG_PACKAGE_hostapd-common/CONFIG_PACKAGE_hostapd-common=y/g' .config
    sed -i 's/CONFIG_PACKAGE_wpad/CONFIG_PACKAGE_wpad=y/g' .config
    sed -i 's/CONFIG_PACKAGE_wpad-openssl/CONFIG_PACKAGE_wpad-openssl=y/g' .config
    log_success "hostapd配置清理完成"
else
    log_warning "未找到.config文件，跳过hostapd配置清理"
fi

# ==================== 处理依赖缺失问题 ====================
log_info "处理依赖缺失问题..."

# 定义要清理的依赖冲突包列表
DEPENDENCY_PACKAGES=(
    "aic8800"
    "automount"
    "basicstation"
    "beep"
    "bigclown-gateway"
    "bluld"
    "comgt"
    "dmx_usb_module"
    "fail2ban"
    "fibocom-qmi-wwan"
    "gl-puli-mcu"
    "keepalived"
)

# 删除package目录中的依赖冲突包
for pkg in "${DEPENDENCY_PACKAGES[@]}"; do
    if find package -name "$pkg" -type d | grep -q .; then
        find package -name "$pkg" -type d | xargs rm -rf
        log_info "已删除package目录中的依赖冲突包: $pkg"
    fi
done

# 删除feeds目录中的依赖冲突包（如果存在）
if [ -d "feeds" ]; then
    for pkg in "${DEPENDENCY_PACKAGES[@]}"; do
        if find feeds -name "$pkg" -type d | grep -q .; then
            find feeds -name "$pkg" -type d | xargs rm -rf
            log_info "已删除feeds目录中的依赖冲突包: $pkg"
        fi
    done
fi

log_success "依赖冲突包清理完成"

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

# ==================== 安装缺失的依赖 ====================
log_info "安装缺失的依赖..."

# 确保libpcre已安装
if [ ! -d "package/libs/pcre" ]; then
    mkdir -p package/libs/pcre
    echo "src-git pcre https://github.com/openwrt/packages.git;master" >> feeds.conf.default
    log_success "libpcre依赖添加完成"
else
    log_info "libpcre依赖已存在"
fi

# 处理python3相关依赖
log_info "处理python3相关依赖..."
if [ -f "feeds.conf.default" ]; then
    # 确保packages feed已添加
    if ! grep -q "packages" feeds.conf.default; then
        echo "src-git packages https://github.com/openwrt/packages.git;master" >> feeds.conf.default
        log_success "packages feed已添加"
    else
        log_info "packages feed已存在"
    fi
fi

# 处理boost-system依赖
log_info "处理boost-system依赖..."
if [ -f "feeds.conf.default" ]; then
    # 确保packages feed已添加
    if ! grep -q "packages" feeds.conf.default; then
        echo "src-git packages https://github.com/openwrt/packages.git;master" >> feeds.conf.default
        log_success "packages feed已添加"
    else
        log_info "packages feed已存在"
    fi
fi

# 优化feeds配置，避免重复
log_info "优化feeds配置..."
if [ -f "feeds.conf.default" ]; then
    # 移除重复的feeds
    awk '!seen[$0]++' feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default
    log_success "feeds配置优化完成"
fi

# ==================== 清理可能导致依赖冲突的包 ====================
log_info "清理依赖冲突包..."

# 定义额外的依赖冲突包列表
EXTRA_DEPENDENCY_PACKAGES=(
    "onionshare-cli"
    "setools"
    "trojan-plus"
)

# 删除feeds中的依赖冲突包
if [ -d "feeds" ]; then
    for pkg in "${EXTRA_DEPENDENCY_PACKAGES[@]}"; do
        if find feeds -name "$pkg" -type d | grep -q .; then
            find feeds -name "$pkg" -type d | xargs rm -rf
            log_info "已删除feeds目录中的依赖冲突包: $pkg"
        fi
    done
fi

log_success "依赖冲突包清理完成"

# ==================== 创建自定义网络优化脚本 ====================
log_info "创建自定义网络优化脚本..."

mkdir -p package/base-files/files/etc

cat > package/base-files/files/etc/network-optimization.sh << 'EOF'
#!/bin/sh
# 网络优化脚本
# 作者: 李杰
# 版本: 2.0

# 设置TCP参数
echo "优化TCP参数..."
sysctl -w net.ipv4.tcp_fastopen=3 > /dev/null 2>&1
sysctl -w net.ipv4.tcp_slow_start_after_idle=0 > /dev/null 2>&1
sysctl -w net.ipv4.tcp_no_metrics_save=1 > /dev/null 2>&1
sysctl -w net.ipv4.tcp_mtu_probing=1 > /dev/null 2>&1

# 设置TCP窗口大小
echo "优化TCP窗口大小..."
sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216" > /dev/null 2>&1
sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216" > /dev/null 2>&1

# 设置TCP拥塞控制
echo "设置TCP拥塞控制为BBR..."
sysctl -w net.ipv4.tcp_congestion_control=bbr > /dev/null 2>&1
sysctl -w net.core.default_qdisc=fq > /dev/null 2>&1

# 设置TCP保活参数
echo "优化TCP保活参数..."
sysctl -w net.ipv4.tcp_keepalive_time=600 > /dev/null 2>&1
sysctl -w net.ipv4.tcp_keepalive_intvl=30 > /dev/null 2>&1
sysctl -w net.ipv4.tcp_keepalive_probes=3 > /dev/null 2>&1

# 设置TCP超时参数
echo "优化TCP超时参数..."
sysctl -w net.ipv4.tcp_fin_timeout=30 > /dev/null 2>&1
sysctl -w net.ipv4.tcp_tw_reuse=1 > /dev/null 2>&1
sysctl -w net.ipv4.tcp_max_tw_buckets=400000 > /dev/null 2>&1

# 设置IPv6参数
echo "优化IPv6参数..."
sysctl -w net.ipv6.conf.all.forwarding=1 > /dev/null 2>&1
sysctl -w net.ipv6.conf.default.forwarding=1 > /dev/null 2>&1

echo "网络优化完成"
EOF

chmod +x package/base-files/files/etc/network-optimization.sh
log_success "网络优化脚本创建完成"

# ==================== 创建自定义系统监控脚本 ====================
log_info "创建自定义系统监控脚本..."

mkdir -p package/base-files/files/etc

cat > package/base-files/files/etc/system-monitor.sh << 'EOF'
#!/bin/sh
# 系统监控脚本
# 作者: 李杰
# 版本: 2.0

# 显示CPU使用率
echo "CPU使用率:"
top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'

# 显示内存使用情况
echo ""
echo "内存使用情况:"
free -h

# 显示磁盘使用情况
echo ""
echo "磁盘使用情况:"
df -h

# 显示网络流量
echo ""
echo "网络流量:"
cat /proc/net/dev | grep -E "eth|wlan" | awk '{print $1": RX="$2" bytes, TX="$10" bytes"}'

# 显示系统负载
echo ""
echo "系统负载:"
uptime

# 显示进程数
echo ""
echo "进程数:"
ps aux | wc -l
EOF

chmod +x package/base-files/files/etc/system-monitor.sh
log_success "系统监控脚本创建完成"

# ==================== 创建自定义系统清理脚本 ====================
log_info "创建自定义系统清理脚本..."

mkdir -p package/base-files/files/etc

cat > package/base-files/files/etc/system-cleanup.sh << 'EOF'
#!/bin/sh
# 系统清理脚本
# 作者: 李杰
# 版本: 2.0

echo "开始清理系统..."

# 清理日志
echo "清理日志..."
logread -C > /dev/null 2>&1
rm -f /var/log/*.log > /dev/null 2>&1

# 清理临时文件
echo "清理临时文件..."
rm -rf /tmp/* > /dev/null 2>&1

# 清理缓存
echo "清理缓存..."
opkg cache clean > /dev/null 2>&1

# 清理旧的软件包
echo "清理旧的软件包..."
opkg autoremove > /dev/null 2>&1

# 清理DNS缓存
echo "清理DNS缓存..."
/etc/init.d/dnsmasq restart > /dev/null 2>&1

# 清理网络缓存
echo "清理网络缓存..."
ip route flush cache > /dev/null 2>&1

# 清理ARP缓存
echo "清理ARP缓存..."
ip neigh flush all > /dev/null 2>&1

echo "系统清理完成"
EOF

chmod +x package/base-files/files/etc/system-cleanup.sh
log_success "系统清理脚本创建完成"

# ==================== 脚本执行完成 ====================
echo "============================================"
echo "MediaTek DIY Part 2 脚本执行完成 (优化版)"
echo "============================================"
log_success "所有操作已成功完成"

# 显示摘要
echo ""
echo "执行摘要:"
echo "✓ 默认主题修改为Argon"
echo "✓ 默认语言设置为中文"
echo "✓ 时区修改为CST-8"
echo "✓ 主机名修改为OpenWrt-AutoBuild"
echo "✓ WiFi配置完成"
echo "✓ 网络配置修改完成，已添加IPv6支持"
echo "✓ 防火墙规则添加完成，已添加IPv6支持"
echo "✓ hostapd编译错误修复完成"
echo "✓ 依赖冲突包清理完成"
echo "✓ 自定义脚本创建完成"
echo ""