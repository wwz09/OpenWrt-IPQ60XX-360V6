#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

# 加载公共工具
source "$(dirname "$0")/../common/utils.sh"

# 包管理函数

# 更新包
UPDATE_PACKAGE() {
    local PKG_NAME=$1
    local PKG_REPO=$2
    local PKG_BRANCH=$3
    local PKG_SPECIAL=$4
    local PKG_LIST=($PKG_NAME ${@:5})  # 第5个参数及以后为自定义名称列表
    local REPO_NAME=${PKG_REPO#*/}
    
    log_info "Processing package: $PKG_NAME"
    
    # 删除本地可能存在的不同名称的软件包
    for NAME in "${PKG_LIST[@]}"; do
        log_info "Searching for directory: $NAME"
        local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)
        
        # 删除找到的目录
        if [ -n "$FOUND_DIRS" ]; then
            while read -r DIR; do
                rm -rf "$DIR"
                log_success "Deleted directory: $DIR"
            done <<< "$FOUND_DIRS"
        else
            log_info "Directory not found: $NAME"
        fi
    done
    
    # 克隆 GitHub 仓库
    git clone --depth=1 --single-branch --branch "$PKG_BRANCH" "https://github.com/$PKG_REPO.git"
    if [ $? -ne 0 ]; then
        log_error "Failed to clone $PKG_REPO"
        return 1
    fi
    
    # 处理克隆的仓库
    if [[ "$PKG_SPECIAL" == "pkg" ]]; then
        find "./$REPO_NAME/*/" -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ 
        rm -rf "./$REPO_NAME/"
        log_success "Extracted package $PKG_NAME from $REPO_NAME"
    elif [[ "$PKG_SPECIAL" == "name" ]]; then
        mv -f "$REPO_NAME" "$PKG_NAME"
        log_success "Renamed $REPO_NAME to $PKG_NAME"
    fi
    
    log_success "Package $PKG_NAME processed successfully"
}

# 更新软件包版本
UPDATE_VERSION() {
    local PKG_NAME=$1
    local PKG_MARK=${2:-false}
    local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")
    
    if [ -z "$PKG_FILES" ]; then
        log_error "$PKG_NAME not found!"
        return 1
    fi
    
    log_info "Updating $PKG_NAME version..."
    
    for PKG_FILE in $PKG_FILES; do
        local PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)" "$PKG_FILE")
        if [ -z "$PKG_REPO" ]; then
            log_error "Failed to extract repo from $PKG_FILE"
            continue
        fi
        
        local PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")
        if [ -z "$PKG_TAG" ]; then
            log_error "Failed to get latest tag for $PKG_REPO"
            continue
        fi
        
        local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
        local OLD_URL=$(grep -Po "PKG_SOURCE_URL:=\K.*" "$PKG_FILE")
        local OLD_FILE=$(grep -Po "PKG_SOURCE:=\K.*" "$PKG_FILE")
        local OLD_HASH=$(grep -Po "PKG_HASH:=\K.*" "$PKG_FILE")
        
        local PKG_URL=$([[ "$OLD_URL" == *"releases"* ]] && echo "${OLD_URL%/}/$OLD_FILE" || echo "${OLD_URL%/}")
        
        local NEW_VER=$(echo "$PKG_TAG" | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
        local NEW_URL=$(echo "$PKG_URL" | sed "s/\$(PKG_VERSION)/$NEW_VER/g; s/\$(PKG_NAME)/$PKG_NAME/g")
        local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)
        
        log_info "Old version: $OLD_VER $OLD_HASH"
        log_info "New version: $NEW_VER $NEW_HASH"
        
        if [[ "$NEW_VER" =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
            sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
            sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
            log_success "$PKG_FILE version has been updated!"
        else
            log_info "$PKG_FILE version is already the latest!"
        fi
    done
}

# 安装常用包
install_common_packages() {
    log_info "Installing common packages..."
    
    # 主题包
    UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12"
    UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "master"
    UPDATE_PACKAGE "aurora-config" "eamonxg/luci-app-aurora-config" "master"
    UPDATE_PACKAGE "kucat" "sirpdboy/luci-theme-kucat" "master"
    UPDATE_PACKAGE "kucat-config" "sirpdboy/luci-app-kucat-config" "master"
    UPDATE_PACKAGE "argon-config" "sbwml/luci-app-argon-config" "openwrt-25.12"
    
    # 网络工具包
    UPDATE_PACKAGE "homeproxy" "VIKINGYFY/homeproxy" "main"
    UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
    UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
    UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"
    UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
    
    # 系统工具包
    UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"
    UPDATE_PACKAGE "diskman" "sbwml/luci-app-diskman" "master"
    UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"
    UPDATE_PACKAGE "fancontrol" "rockjake/luci-app-fancontrol" "main"
    UPDATE_PACKAGE "gecoosac" "laipeng668/luci-app-gecoosac" "main"
    UPDATE_PACKAGE "netspeedtest" "sirpdboy/netspeedtest" "main" "" "homebox speedtest"
    UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"
    UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "main"
    UPDATE_PACKAGE "qbittorrent" "sbwml/luci-app-qbittorrent" "master" "" "qt6base qt6tools rblibtorrent"
    UPDATE_PACKAGE "qmodem" "FUjr/QModem" "main"
    UPDATE_PACKAGE "quickfile" "sbwml/luci-app-quickfile" "main"
    UPDATE_PACKAGE "viking" "VIKINGYFY/packages" "main" "" "luci-app-timewol luci-app-wolplus"
    UPDATE_PACKAGE "vnt" "lmq8267/luci-app-vnt" "main"
    
    # 基础工具包
    UPDATE_PACKAGE "cpufreq" "openwrt/luci" "openwrt-23.05" "pkg" "luci-app-cpufreq"
    UPDATE_PACKAGE "ttyd" "openwrt/packages" "openwrt-23.05" "pkg" "ttyd luci-app-ttyd"
    UPDATE_PACKAGE "samba4" "openwrt/packages" "openwrt-23.05" "pkg" "samba4 luci-app-samba4"
    UPDATE_PACKAGE "vlmcsd" "openwrt/packages" "openwrt-23.05" "pkg" "vlmcsd luci-app-vlmcsd"
    UPDATE_PACKAGE "parentcontrol" "openwrt/luci" "openwrt-23.05" "pkg" "luci-app-parentcontrol"
    UPDATE_PACKAGE "usb-printer" "openwrt/luci" "openwrt-23.05" "pkg" "luci-app-usb-printer"
    UPDATE_PACKAGE "oaf" "destan19/OpenAppFilter" "master" "pkg" "OpenAppFilter luci-app-oaf"
    UPDATE_PACKAGE "sqm-scripts" "openwrt/packages" "openwrt-23.05" "pkg" "sqm-scripts"
    UPDATE_PACKAGE "luci-app-sqm" "openwrt/luci" "openwrt-23.05" "pkg" "luci-app-sqm"
    UPDATE_PACKAGE "ariang" "openwrt/packages" "openwrt-23.05" "pkg" "ariang"
    UPDATE_PACKAGE "luci-app-ariang" "sbwml/luci-app-ariang" "main"
    UPDATE_PACKAGE "autoreboot" "openwrt/luci" "openwrt-23.05" "pkg" "luci-app-autoreboot"
    UPDATE_PACKAGE "pysocks" "openwrt/packages" "openwrt-23.05" "pkg" "python3-pysocks"
    UPDATE_PACKAGE "unidecode" "openwrt/packages" "openwrt-23.05" "pkg" "python3-unidecode"
    UPDATE_PACKAGE "lucky" "gdy666/luci-app-lucky" "main"
    
    log_success "Common packages installed successfully"
}

# 更新包版本
update_package_versions() {
    log_info "Updating package versions..."
    
    # 更新指定包的版本
    UPDATE_VERSION "sing-box"
    # UPDATE_VERSION "tailscale"
    
    log_success "Package versions updated successfully"
}

# 主函数
main() {
    local action=${1:-"install"}
    
    case "$action" in
        "install")
            install_common_packages
            ;;
        "update")
            update_package_versions
            ;;
        "all")
            install_common_packages
            update_package_versions
            ;;
        *)
            log_error "Unknown action: $action"
            log_info "Usage: $0 [install|update|all]"
            return 1
            ;;
    esac
}

# 管理包函数，被main.sh调用
manage_packages() {
    local WRT_TARGET="$1"
    local WRT_CONFIG="$2"
    
    log_info "Managing packages for target: $WRT_TARGET, config: $WRT_CONFIG"
    
    # 安装常用包
    install_common_packages
    
    # 更新包版本
    update_package_versions
    
    log_success "Package management completed"
}

# 执行主函数
if [ "$0" = "$BASH_SOURCE" ]; then
    main "$@"
fi
