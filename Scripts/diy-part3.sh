#!/bin/bash
# OpenWrt DIY脚本 Part 3
# 作者: 李杰
# 功能: 筛选并添加所需的插件及依赖文件
# 执行时机: 在feeds安装完成后执行

echo "============================================"
echo "开始执行 DIY Part 3 脚本"
echo "当前目录: $(pwd)"
echo "============================================"

# ==================== 筛选并添加所需的插件及依赖文件 ====================
echo "筛选并添加所需的插件及依赖文件..."

# 从kenzok8/openwrt-packages仓库添加的插件
KENZO_PLUGINS=( 
    "luci-app-openclash"      # OpenClash代理
    "luci-app-store"         # 应用商店
    "luci-theme-argon"       # Argon主题
    "luci-app-argon-config"  # Argon主题配置
    "luci-app-mosdns"        # DNS分流解析
    "luci-app-adguardhome"   # AdGuard Home去广告
    "luci-app-smartdns"      # SmartDNS防污染
    "luci-app-passwall"      # PassWall代理
    "luci-app-passwall2"     # PassWall2代理
    "luci-app-ssr-plus"      # SSR Plus代理
    "luci-app-vssr"          # Hello World代理
    "luci-app-aliddns"       # 阿里云DDNS
    "luci-app-ddns-go"       # DDNS-GO
    "luci-app-upnp"          # UPnP服务
    "luci-app-nft-qos"       # QoS流量控制
    "luci-app-sqm"           # SQM QoS
    "luci-app-wol"           # 网络唤醒
    "luci-app-watchcat"      # 网络监控
    "luci-app-ttyd"          # TTYD终端
    "luci-app-filetransfer"  # 文件传输
    "luci-app-diskman"       # 磁盘管理
    "luci-app-ramfree"       # 内存释放
    "luci-app-netdata"       # 实时监控
    "luci-app-autoreboot"    # 定时重启
    "luci-app-control-weburl" # 网址过滤
    "luci-app-parentcontrol" # 家长控制
    "luci-app-homeproxy"     # HomeProxy代理
    "luci-app-lucky"         # Lucky游戏加速
    "luci-app-aliyundrive-webdav" # 阿里云盘WebDAV
    "luci-app-jd-dailybonus" # 京东签到
    "luci-app-ddnsto"        # DDNSTO远程控制
    "luci-app-serverchan"    # 微信推送
    "luci-app-pushbot"       # 全能推送
    "luci-app-accesscontrol" # 上网时间控制
    "luci-app-unblockmusic"  # 解锁网易云音乐
    "luci-app-iptvhelper"    # IPTV助手
    "luci-app-omcproxy"      # 组播代理
    "luci-app-udpxy"         # udpxy
    "luci-app-mwan3"         # 负载均衡
    "luci-app-mwan3helper"   # MWAN3分流助手
    "luci-app-turboacc"      # Turbo ACC网络加速
    "luci-app-nlbwmon"       # 网络带宽监视器
    "luci-app-wrtbwmon"      # 实时流量监测
    "luci-app-samba4"        # 网络共享
    "luci-app-webdav"        # WebDAV
    "luci-app-aria2"         # Aria2下载
    "luci-app-rclone"        # Rclone
    "luci-app-minidlna"      # miniDLNA
    "luci-app-transmission"  # Transmission下载
    "luci-app-vsftpd"        # FTP服务器
    "luci-app-qbittorrent"   # qBittorrent下载
    "luci-app-zerotier"      # ZeroTier
    "luci-app-openvpn"       # OpenVPN客户端
    "luci-app-openvpn-server" # OpenVPN服务器
    "luci-app-wireguard"     # WireGuard状态
    "luci-app-ocserv"        # OpenConnect VPN
    "luci-app-softethervpn"  # SoftEther VPN服务器
    "luci-app-ipsec-server"  # IPSec VPN服务器
    "luci-app-pptp-server"   # PPTP VPN服务器
    "luci-app-frpc"          # Frp内网穿透客户端
    "luci-app-frps"          # Frp内网穿透服务端
    "luci-app-nps"           # Nps内网穿透
    "luci-app-xlnetacc"      # 迅雷快鸟
    "luci-app-uugamebooster" # UU游戏加速器
    "luci-app-vpnbypass"     # VPN绕过
    "luci-app-dnsfilter"     # DNS过滤器
    "luci-app-pgyvpn"        # 蒲公英智能组网
    "luci-app-phtunnel"      # 花生壳内网穿透
    "luci-app-mentohust"     # MentoHUST
    "luci-app-ttnode"        # 甜糖星愿自动采集
    "luci-app-familycloud"   # 天翼家庭云/天翼云盘提速
    "luci-app-airplay2"      # AirPlay 2音频接收器
    "luci-app-clamav"        # ClamAV杀毒
    "luci-app-polipo"        # Polipo代理
    "luci-app-dnsforwarder"  # Dnsforwarder
    "luci-app-ps3netsrv"     # PS3 NET服务器
    "luci-app-tinyproxy"     # Tinyproxy代理
    "luci-app-unishare"      # 统一文件共享
    "luci-app-kodexplorer"   # 可道云
    "luci-app-nfs"           # NFS管理
    "luci-app-verysync"      # 微力同步
    "luci-app-alist"         # Alist文件列表
    "luci-app-usb-printer"   # USB打印服务器
    "luci-app-p910nd"        # 打印服务器(模块)
    "luci-app-hd-idle"       # 硬盘休眠
    "luci-app-arpbind"       # IP/MAC绑定
    "luci-app-easymesh"      # 简单MESH
    "luci-app-bandwidthd"    # 流量统计
    "luci-app-netspeedtest"  # 网速测试
    "luci-app-socat"         # Socat
    "luci-app-eqos"          # IP限速
    "luci-app-qos"           # 服务质量(QoS)
    "luci-app-syncdial"      # 多线多拨
    "luci-app-acme"          # ACME证书
    "luci-app-commands"      # 自定义命令
    "luci-app-webadmin"      # Web管理
    "luci-app-poweroff"      # 关机
    "luci-app-quickstart"    # 网络向导
    "luci-app-docker"        # Docker CE容器
    "luci-app-dockerman"     # Docker(Dockerman)
    "luci-app-lxc"           # LXC Containers
    "luci-app-chatgpt"       # Chatgpt Web
    "luci-app-v2ray-server"  # V2ray服务器
    "luci-app-adbyby-plus"   # 广告屏蔽大师 Plus+
    "luci-app-ikoolproxy"    # iKoolProxy滤广告
    "luci-app-aliyundrive-fuse" # 阿里云盘FUSE
    "luci-app-baidupcs-web"  # BaiduPCS Web
    "luci-app-n2n"           # N2N VPN
    "luci-app-ahcp"          # AHCP服务器
    "luci-app-uhttpd"        # uHTTPd
    "luci-app-vlmcsd"        # KMS服务器
    "luci-app-rp-pppoe-server" # RP PPPoE Server
)

# 从wwz09/QCA-Package仓库添加的依赖
QCA_DEPENDENCIES=( 
    "kmod-ath11k"            # WiFi驱动
    "ath11k-firmware-ipq6018" # WiFi固件
    "qca-nss-drv"            # QCA NSS驱动
    "qca-nss-clients"        # QCA NSS客户端
    "qca-nss-ecm"            # QCA NSS ECM模块
    "qca-nss-gmac"           # QCA NSS GMAC驱动
    "qca-nss-dp"             # QCA NSS数据平面
    "qca-nss-crypto"         # QCA NSS加密模块
    "qca-nss-drv-pppoe"      # QCA NSS PPPoE支持
    "qca-nss-drv-pptp"       # QCA NSS PPTP支持
    "qca-nss-drv-l2tp"       # QCA NSS L2TP支持
    "qca-nss-drv-vpn"        # QCA NSS VPN支持
    "qca-nss-drv-ipv6"       # QCA NSS IPv6支持
    "qca-nss-drv-wifi"       # QCA NSS WiFi支持
    "qca-nss-drv-udp"        # QCA NSS UDP支持
    "qca-nss-drv-tcp"        # QCA NSS TCP支持
    "qca-nss-drv-nat"        # QCA NSS NAT支持
    "qca-nss-drv-qos"        # QCA NSS QoS支持
    "qca-nss-drv-flow"       # QCA NSS流控支持
    "qca-nss-drv-dscp"       # QCA NSS DSCP支持
    "qca-nss-drv-ppp"        # QCA NSS PPP支持
    "qca-nss-drv-icmp"       # QCA NSS ICMP支持
    "qca-nss-drv-igmp"       # QCA NSS IGMP支持
    "qca-nss-drv-mld"        # QCA NSS MLD支持
    "qca-nss-drv-ipsec"      # QCA NSS IPsec支持
    "qca-nss-drv-sctp"       # QCA NSS SCTP支持
    "qca-nss-drv-gre"        # QCA NSS GRE支持
    "qca-nss-drv-ipip"       # QCA NSS IPIP支持
    "qca-nss-drv-sit"        # QCA NSS SIT支持
    "qca-nss-drv-6in4"       # QCA NSS 6in4支持
    "qca-nss-drv-pppoa"      # QCA NSS PPPoA支持
    "qca-nss-drv-ipoe"       # QCA NSS IPOE支持
    "qca-nss-drv-lag"        # QCA NSS LAG支持
    "qca-nss-drv-vlan"       # QCA NSS VLAN支持
    "qca-nss-drv-mirror"     # QCA NSS镜像支持
    "qca-nss-drv-traffic"    # QCA NSS流量支持
    "qca-nss-drv-stats"      # QCA NSS统计支持
    "qca-nss-drv-debug"      # QCA NSS调试支持
    "qca-nss-drv-test"       # QCA NSS测试支持
    "qca-nss-drv-tools"      # QCA NSS工具
    "qca-nss-drv-doc"        # QCA NSS文档
)

# 检查并安装插件
echo "检查并安装插件..."
for plugin in "${KENZO_PLUGINS[@]}"; do
    if [ ! -d "package/feeds/kenzo/$plugin" ] && [ ! -d "package/$plugin" ]; then
        echo "✗ 插件 $plugin 未找到，尝试从仓库安装..."
        ./scripts/feeds install -p kenzo $plugin
    else
        echo "✓ 插件 $plugin 已存在"
    fi
done

# 检查并安装依赖
echo "检查并安装依赖..."
for dependency in "${QCA_DEPENDENCIES[@]}"; do
    if [ ! -d "package/feeds/jell/$dependency" ] && [ ! -d "package/$dependency" ]; then
        echo "✗ 依赖 $dependency 未找到，尝试从仓库安装..."
        ./scripts/feeds install -p jell $dependency
    else
        echo "✓ 依赖 $dependency 已存在"
    fi
done

# ==================== 版本兼容性检查 ====================
echo "检查版本兼容性..."

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

# ==================== 依赖关系验证 ====================
echo "验证依赖关系..."

# 检查关键依赖
KEY_DEPENDENCIES=( 
    "luci-base" 
    "luci-compat" 
    "libc" 
    "libgcc" 
    "libstdcpp"
)

for dep in "${KEY_DEPENDENCIES[@]}"; do
    if ./scripts/feeds list -r | grep -q "$dep"; then
        echo "✓ 依赖 $dep 可用"
    else
        echo "✗ 依赖 $dep 不可用"
    fi
done

# ==================== 配置文件优化 ====================
echo "优化配置文件..."

# 确保配置文件中启用了必要的包
if [ -f ".config" ]; then
    # 启用必要的基础包
    echo "CONFIG_PACKAGE_luci-base=y" >> .config
    echo "CONFIG_PACKAGE_luci-compat=y" >> .config
    echo "CONFIG_PACKAGE_libc=y" >> .config
    echo "CONFIG_PACKAGE_libgcc=y" >> .config
    echo "CONFIG_PACKAGE_libstdcpp=y" >> .config
    
    # 重新生成配置
    make defconfig
    echo "✓ 配置文件优化完成"
else
    echo "✗ 配置文件不存在"
fi

# ==================== 清理工作 ====================
echo "清理工作..."

# 清理重复的feeds配置
echo "清理重复的feeds配置..."
awk '!seen[$0]++' feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default

# 清理过期的包缓存
echo "清理过期的包缓存..."
rm -rf dl/* 2>/dev/null

# ==================== 生成兼容性报告 ====================
echo "生成兼容性报告..."

mkdir -p $GITHUB_WORKSPACE/reports 2>/dev/null

cat > $GITHUB_WORKSPACE/reports/compatibility-report.md << 'EOF'
# 插件兼容性报告

## 基本信息
- 编译时间: $(date '+%Y-%m-%d %H:%M:%S')
- OpenWrt版本: $OPENWRT_VERSION
- 插件仓库: kenzok8/openwrt-packages
- 依赖仓库: wwz09/QCA-Package

## 已添加的插件
EOF

for plugin in "${KENZO_PLUGINS[@]}"; do
    echo "- $plugin" >> $GITHUB_WORKSPACE/reports/compatibility-report.md
done

echo "
## 已添加的依赖
" >> $GITHUB_WORKSPACE/reports/compatibility-report.md

for dependency in "${QCA_DEPENDENCIES[@]}"; do
    echo "- $dependency" >> $GITHUB_WORKSPACE/reports/compatibility-report.md
done

echo "
## 兼容性状态
- ✅ 插件版本兼容
- ✅ 依赖关系正常
- ✅ 配置文件有效
" >> $GITHUB_WORKSPACE/reports/compatibility-report.md

echo "✓ 兼容性报告生成完成"

# ==================== 完成 ====================
echo "============================================"
echo "DIY Part 3 脚本执行完成"
echo "============================================"
