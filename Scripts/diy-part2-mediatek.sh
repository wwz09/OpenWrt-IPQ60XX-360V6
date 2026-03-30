#!/bin/bash
# OpenWrt DIY脚本 Part 2 (MediaTek平台专用)
# 作者: 李杰
# 功能: 在更新feeds之后执行的自定义操作
# 执行时机: feeds更新和安装完成后

echo "============================================"
echo "开始执行 MediaTek DIY Part 2 脚本"
echo "当前目录: $(pwd)"
echo "============================================"

# ==================== 修改默认主题设置 ====================
echo "修改默认主题..."
# 修改默认主题为Argon
if [ -f "feeds/luci/modules/luci-base/root/etc/config/luci" ]; then
    sed -i 's/Bootstrap/Argon/g' feeds/luci/modules/luci-base/root/etc/config/luci
    echo "✓ 默认主题修改为Argon"
fi

# ==================== 修改默认语言为中文 ====================
echo "设置默认语言为中文..."
if [ -f "feeds/luci/modules/luci-base/root/etc/config/luci" ]; then
    sed -i 's/en/zh_cn/g' feeds/luci/modules/luci-base/root/etc/config/luci
    echo "✓ 默认语言设置为中文"
fi

# ==================== 修改默认时区 ====================
echo "修改默认时区..."
if [ -f "package/base-files/files/etc/config/system" ]; then
    sed -i 's/UTC/CST-8/g' package/base-files/files/etc/config/system
    sed -i 's/"UTC"/"CST-8"/g' package/base-files/files/etc/config/system
    echo "✓ 时区修改为CST-8"
fi

# ==================== 修改默认主机名 ====================
echo "修改默认主机名..."
if [ -f "package/base-files/files/etc/config/system" ]; then
    sed -i 's/OpenWrt/OpenWrt-AutoBuild/g' package/base-files/files/etc/config/system
    echo "✓ 主机名修改为OpenWrt-AutoBuild"
fi

# ==================== 修改默认WiFi设置 ====================
echo "配置默认WiFi..."
# 创建默认WiFi配置
mkdir -p package/base-files/files/etc/config
cat > package/base-files/files/etc/config/wireless << 'EOF'
config wifi-device 'radio0'
    option type 'mac80211'
    option path 'platform/soc/18000000.wifi'
    option channel 'auto'
    option band '2g'
    option htmode 'HE40'
    option country 'CN'
    option disabled '0'

config wifi-iface 'default_radio0'
    option device 'radio0'
    option network 'lan'
    option mode 'ap'
    option ssid 'OpenWrt-2.4G'
    option encryption 'psk2'
    option key '12345678'

config wifi-device 'radio1'
    option type 'mac80211'
    option path 'platform/soc/18000000.wifi+1'
    option channel 'auto'
    option band '5g'
    option htmode 'HE80'
    option country 'CN'
    option disabled '0'

config wifi-iface 'default_radio1'
    option device 'radio1'
    option network 'lan'
    option mode 'ap'
    option ssid 'OpenWrt-5G'
    option encryption 'psk2'
    option key '12345678'
EOF
echo "✓ WiFi配置完成"

# ==================== 修改网络配置 ====================
echo "修改网络配置..."
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

config interface 'wan'
    option device 'wan'
    option proto 'dhcp'
    option ipv6 'auto'

config interface 'wan6'
    option device 'wan'
    option proto 'dhcpv6'

config device
    option name 'br-lan'
    option type 'bridge'
    list ports 'lan1'
    list ports 'lan2'
    list ports 'lan3'
    list ports 'lan4'
EOF
echo "✓ 网络配置修改完成，已添加IPv6支持"

# ==================== 添加自定义启动脚本 ====================
echo "添加自定义启动脚本..."
mkdir -p package/base-files/files/etc
cat > package/base-files/files/etc/rc.local << 'EOF'
# 自定义启动脚本
# 作者: 李杰

# 设置CPU性能模式
echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor 2>/dev/null

# 启用BBR拥塞控制
echo net.core.default_qdisc=fq > /etc/sysctl.conf
echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf
sysctl -p

exit 0
EOF
chmod +x package/base-files/files/etc/rc.local
echo "✓ 启动脚本添加完成"

# ==================== 修改banner信息 ====================
echo "修改banner信息..."
mkdir -p package/base-files/files/etc
cat > package/base-files/files/etc/banner << 'EOF'
  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__|  OpenWrt AutoBuild by 李杰
 -----------------------------------------------------
  固件版本: OpenWrt AutoBuild
  编译时间: $(date '+%Y-%m-%d %H:%M:%S')
  源码仓库: LiBwrt/openwrt-6.x
  插件仓库: kenzok8/openwrt-packages
  平台: MediaTek
 -----------------------------------------------------
EOF
echo "✓ Banner修改完成"

# ==================== 添加motd信息 ====================
echo "添加motd信息..."
mkdir -p package/base-files/files/etc
cat > package/base-files/files/etc/motd << 'EOF'

欢迎使用 OpenWrt AutoBuild 固件!

系统信息:
  - 固件版本: OpenWrt AutoBuild
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
echo "✓ motd添加完成"

# ==================== 修改opkg软件源 ====================
echo "配置opkg软件源..."
mkdir -p package/base-files/files/etc/opkg
cat > package/base-files/files/etc/opkg/distfeeds.conf << 'EOF'
src/gz openwrt_core https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/22.03.5/targets/mediatek/filogic/packages
src/gz openwrt_base https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/22.03.5/packages/aarch64_cortex-a53/base
src/gz openwrt_luci https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/22.03.5/packages/aarch64_cortex-a53/luci
src/gz openwrt_packages https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/22.03.5/packages/aarch64_cortex-a53/packages
src/gz openwrt_routing https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/22.03.5/packages/aarch64_cortex-a53/routing
src/gz openwrt_telephony https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/22.03.5/packages/aarch64_cortex-a53/telephony
EOF
echo "✓ opkg软件源配置完成"

# ==================== 添加定时任务 ====================
echo "添加定时任务..."
mkdir -p package/base-files/files/etc/crontabs
cat > package/base-files/files/etc/crontabs/root << 'EOF'
# 每天凌晨3点自动更新软件包列表
0 3 * * * opkg update

# 每周日凌晨4点清理日志
0 4 * * 0 logread -C

# 每天凌晨5点重启网络服务
0 5 * * * /etc/init.d/network restart
EOF
echo "✓ 定时任务添加完成"

# ==================== 优化系统参数 ====================
echo "优化系统参数..."
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
echo "✓ 系统参数优化完成，已添加IPv6支持"

# ==================== 添加自定义防火墙规则 ====================
echo "添加自定义防火墙规则..."
mkdir -p package/base-files/files/etc
cat > package/base-files/files/etc/firewall.user << 'EOF'
# 自定义防火墙规则
# 作者: 李杰

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
echo "✓ 防火墙规则添加完成，已添加IPv6支持"

# ==================== 修复hostapd编译错误 ====================
echo "修复hostapd编译错误..."
# 修复he_mu_edca成员缺失问题 - 这是hostapd编译失败的根本原因
# 错误信息：'struct hostapd_config' has no member named 'he_mu_edca'
if [ -d "package/network/services/hostapd" ]; then
    # 查找并修复hostapd源码中的he_mu_edca问题
    find package/network/services/hostapd -name "*.c" -type f | while read file; do
        if grep -q "he_mu_edca" "$file" 2>/dev/null; then
            # 备份原文件
            cp "$file" "$file.bak"
            # 添加条件编译检查，确保CONFIG_IEEE80211AX已定义
            sed -i 's/hapd->iface->conf->he_mu_edca/#ifdef CONFIG_IEEE80211AX\n\t\thapd->iface->conf->he_mu_edca/g' "$file"
            sed -i 's/he_qos_info &= 0xfff0;/he_qos_info \&= 0xfff0;\n#else\n\t\t\/\/ CONFIG_IEEE80211AX not defined, skip he_mu_edca\n#endif/g' "$file"
            echo "✓ 修复文件: $file"
        fi
    done
fi

# 在配置中启用IEEE80211AX支持
if [ -f ".config" ]; then
    echo "启用IEEE80211AX支持..."
    echo "CONFIG_PACKAGE_kmod-cfg80211=y" >> .config
    echo "CONFIG_PACKAGE_hostapd-common=y" >> .config
    echo "CONFIG_PACKAGE_wpad-basic-openssl=y" >> .config
    echo "CONFIG_IEEE80211AX_SUPPORT=y" >> .config
    echo "✓ hostapd配置更新完成"
fi

echo "✓ hostapd编译错误修复完成"

# ==================== 处理依赖缺失问题 ====================
echo "处理依赖缺失问题..."

# 清理可能导致冲突的包
echo "清理冲突包..."
find package -name "luci-app-oaf" -type d | xargs rm -rf 2>/dev/null
find package -name "luci-app-control-timewol" -type d | xargs rm -rf 2>/dev/null
find package -name "luci-app-cpufreq" -type d | xargs rm -rf 2>/dev/null
echo "✓ 冲突包清理完成"

# 优化feeds配置，避免重复
echo "优化feeds配置..."
if [ -f "feeds.conf.default" ]; then
    # 移除重复的feeds
    awk '!seen[$0]++' feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default
    echo "✓ feeds配置优化完成"
fi

echo "✓ 依赖处理完成"

echo "============================================"
echo "MediaTek DIY Part 2 脚本执行完成"
echo "============================================"
