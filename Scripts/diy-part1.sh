#!/bin/bash

# 自定义脚本 - 第一部分
# 作者：李杰

# 克隆额外的包
echo "克隆额外的包..."

# 示例：克隆 luci-app-openclash
if [ ! -d "package/luci-app-openclash" ]; then
    git clone https://github.com/vernesong/OpenClash.git package/luci-app-openclash
else
    echo "luci-app-openclash 已存在，跳过克隆"
fi

# 示例：克隆 luci-app-adguardhome
if [ ! -d "package/AdGuardHome" ]; then
    git clone https://github.com/AdguardTeam/AdGuardHome.git package/AdGuardHome
else
    echo "AdGuardHome 已存在，跳过克隆"
fi

if [ ! -d "package/luci-app-adguardhome" ]; then
    git clone https://github.com/rufengsuixing/luci-app-adguardhome.git package/luci-app-adguardhome
else
    echo "luci-app-adguardhome 已存在，跳过克隆"
fi
