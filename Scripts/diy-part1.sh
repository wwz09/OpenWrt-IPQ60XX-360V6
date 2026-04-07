#!/bin/bash

# 自定义脚本 - 第一部分
# 作者：李杰

# 克隆额外的包
echo "克隆额外的包..."

# 示例：克隆 luci-app-openclash
git clone https://github.com/vernesong/OpenClash.git package/luci-app-openclash

# 示例：克隆 luci-app-adguardhome
git clone https://github.com/AdguardTeam/AdGuardHome.git package/AdGuardHome
git clone https://github.com/rufengsuixing/luci-app-adguardhome.git package/luci-app-adguardhome
