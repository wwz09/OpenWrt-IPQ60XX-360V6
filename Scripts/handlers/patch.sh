#!/bin/bash

# 补丁处理脚本
# 用于自动应用Qihoo 360 V6设备的补丁文件

# 日志函数
log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[SUCCESS] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# 检查是否需要应用补丁
check_patch_needed() {
    local config_file="$1"
    local target_device="$2"
    
    if grep -q "CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_qihoo_360v6=y" "$config_file"; then
        log_info "检测到Qihoo 360 V6设备配置，需要应用补丁"
        return 0
    else
        log_info "未检测到Qihoo 360 V6设备配置，跳过补丁应用"
        return 1
    fi
}

# 应用补丁
apply_patch() {
    local patch_file="$1"
    local target_dir="$2"
    local backup_dir="$3"
    
    log_info "准备应用补丁: $patch_file"
    
    # 确保目标目录存在
    if [ ! -d "$target_dir" ]; then
        log_error "目标目录不存在: $target_dir"
        return 1
    fi
    
    # 确保补丁文件存在
    if [ ! -f "$patch_file" ]; then
        log_error "补丁文件不存在: $patch_file"
        return 1
    fi
    
    # 创建备份目录
    mkdir -p "$backup_dir"
    
    # 提取补丁中修改的文件
    local modified_files=$(grep -E "^--- a/" "$patch_file" | cut -d ' ' -f 2 | sed 's/^a\///')
    
    # 备份修改的文件
    for file in $modified_files; do
        local full_path="$target_dir/$file"
        if [ -f "$full_path" ]; then
            local backup_path="$backup_dir/$(basename $file).bak"
            cp "$full_path" "$backup_path"
            if [ $? -eq 0 ]; then
                log_info "已备份文件: $file -> $backup_path"
            else
                log_error "备份文件失败: $file"
                return 1
            fi
        fi
    done
    
    # 应用补丁
    log_info "开始应用补丁..."
    cd "$target_dir" && patch -p1 < "$patch_file"
    
    if [ $? -eq 0 ]; then
        log_success "补丁应用成功"
        return 0
    else
        log_error "补丁应用失败"
        # 回滚到备份
        rollback_patch "$target_dir" "$backup_dir" "$modified_files"
        return 1
    fi
}

# 回滚补丁
rollback_patch() {
    local target_dir="$1"
    local backup_dir="$2"
    local modified_files="$3"
    
    log_info "开始回滚补丁..."
    
    for file in $modified_files; do
        local full_path="$target_dir/$file"
        local backup_path="$backup_dir/$(basename $file).bak"
        
        if [ -f "$backup_path" ]; then
            cp "$backup_path" "$full_path"
            if [ $? -eq 0 ]; then
                log_info "已回滚文件: $file"
            else
                log_error "回滚文件失败: $file"
            fi
        fi
    done
    
    log_info "补丁回滚完成"
}

# 主函数
main() {
    local config_file="$1"
    local target_dir="$2"
    local patch_dir="$3"
    local backup_dir="$4"
    
    # 应用内核缓存行组大小修复补丁（通用补丁，所有设备编译时都需要应用）
    local cacheline_patch="$patch_dir/002-fix-net-device-cacheline-group-size.patch"
    if [ -f "$cacheline_patch" ]; then
        apply_patch "$cacheline_patch" "$target_dir" "$backup_dir"
        if [ $? -ne 0 ]; then
            log_error "内核缓存行组大小补丁应用失败"
            return 1
        fi
    else
        log_error "内核缓存行组大小补丁文件不存在: $cacheline_patch"
        return 1
    fi
    
    # 检查是否需要应用 qihoo_360v6 特定补丁
    if check_patch_needed "$config_file" "qihoo_360v6"; then
        # 应用网络配置补丁
        local network_patch="$patch_dir/001-add-qihoo-360v6-network-config.patch"
        if [ -f "$network_patch" ]; then
            apply_patch "$network_patch" "$target_dir" "$backup_dir"
            if [ $? -ne 0 ]; then
                log_error "网络配置补丁应用失败"
                return 1
            fi
        else
            log_error "网络配置补丁文件不存在: $network_patch"
            return 1
        fi
        
        log_success "所有补丁应用成功"
        return 0
    else
        log_info "不需要应用 qihoo_360v6 特定补丁"
        log_success "内核缓存行组大小补丁应用成功"
        return 0
    fi
}

# 检查参数
if [ $# -ne 4 ]; then
    echo "用法: $0 <配置文件> <目标目录> <补丁目录> <备份目录>"
    exit 1
fi

# 执行主函数
main "$1" "$2" "$3" "$4"
exit $?
