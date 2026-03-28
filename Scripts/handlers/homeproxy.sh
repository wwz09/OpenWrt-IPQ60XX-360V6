#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

# 预置HomeProxy数据
handle_homeproxy() {
    local PKG_PATH="$1"
    
    if [ -d "$PKG_PATH"*"homeproxy"* ]; then
        echo ""

        local HP_RULE="surge"
        local HP_PATH="homeproxy/root/etc/homeproxy"

        rm -rf "$PKG_PATH/$HP_PATH/resources/*"

        git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" "$PKG_PATH/$HP_RULE/"
        cd "$PKG_PATH/$HP_RULE/" && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")

        echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
        awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
        sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
        mv -f ./{china_*,gfw_list}.{ver,txt} ../$HP_PATH/resources/

        cd .. && rm -rf "./$HP_RULE/"

        cd "$PKG_PATH" && echo "homeproxy date has been updated!"
    fi
}
