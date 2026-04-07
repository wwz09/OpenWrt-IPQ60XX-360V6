#!/bin/bash

# 自定义脚本 - 第二部分
# 作者：李杰

# 配置调整
echo "配置调整..."

# 示例：修改默认 IP
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# 示例：修改默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 示例：添加自定义启动项
cat >> package/base-files/files/etc/rc.local << EOF
# 自定义启动项
# 示例：启动 AdGuardHome
# /etc/init.d/AdGuardHome start
EOF
