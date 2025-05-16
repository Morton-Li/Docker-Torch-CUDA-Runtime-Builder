#!/bin/bash

install_runtime_packages() {
    local packages="openssh-server ca-certificates git curl wget zip unzip p7zip-full screen vim vim-tiny nano"
    echo "[INFO] Installing runtime packages"
    apt-get update && apt-get install -y --no-install-recommends $packages
}

ensure_sshd_config() {
    local key="$1"
    local value="$2"
    local file="/etc/ssh/sshd_config"
    grep -qE "^[[:space:]]*#?[[:space:]]*${key}[[:space:]]" "$file" && sed -i -E "s|^[[:space:]]*#?[[:space:]]*${key}[[:space:]].*|${key} ${value}|" "$file" || echo "${key} ${value}" >> "$file"
}

configure_ssh() {
    # 设置 root 密码（如果指定了 ROOT_PASSWORD）
    if [ -n "$ROOT_PASSWORD" ]; then
        echo "root:$ROOT_PASSWORD" | chpasswd

        # 显式开启密码认证
        ensure_sshd_config "PasswordAuthentication" "yes"
        ensure_sshd_config "PermitRootLogin" "yes"

        echo "[INFO] Root password configured"
    fi

    # 配置 root 的 SSH 公钥认证（如果指定了 ROOT_AUTHORIZED_KEY）
    if [ -n "$ROOT_AUTHORIZED_KEY" ]; then
        mkdir -p /root/.ssh
        echo "$ROOT_AUTHORIZED_KEY" > /root/.ssh/authorized_keys
        chmod 700 /root/.ssh
        chmod 600 /root/.ssh/authorized_keys
        chown -R root:root /root/.ssh

        # 关闭密码登录，仅启用公钥认证（增强安全性）
        ensure_sshd_config "PasswordAuthentication" "no"
        # 显式启用公钥认证
        ensure_sshd_config "PubkeyAuthentication" "yes"
        ensure_sshd_config "AuthorizedKeysFile" ".ssh/authorized_keys"
        ensure_sshd_config "PermitRootLogin" "yes"
        echo "[INFO] Root authorized SSH key installed"
    fi

    # 确保 sshd 运行目录存在（部分系统可能需要）
    mkdir -p /var/run/sshd
}

ensure_nvidia_utils() {
    if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
        echo "[INFO] 'nvidia-smi' is available and working, skipping nvidia-utils installation"
        return
    fi
    
    if [[ -f /proc/driver/nvidia/version ]]; then
        local full_version=$(grep -oP 'Kernel Module\s+\K[0-9.]+' /proc/driver/nvidia/version)
        local major=$(echo "$full_version" | cut -d. -f1)
        local minor=$(echo "$full_version" | cut -d. -f2)
        local patch_prefix="${major}.${minor}"

        echo "[INFO] Detected NVIDIA driver version: $full_version"

        # 查询所有可用版本
        mapfile -t candidate_versions < <(apt-cache madison nvidia-utils-${major} | awk '{print $3}' | grep "^${patch_prefix}" | sort -Vr)
        if [[ ${#candidate_versions[@]} -eq 0 ]]; then
            echo "[WARN] No nvidia-utils-${major} matching ${patch_prefix} found in apt, skipping installation"
            return
        fi

        for version in "${candidate_versions[@]}"; do
            echo "[INFO] Trying to install: nvidia-utils-${major}=${version}"
            if apt-get install -y nvidia-utils-${major}="${version}"; then
                echo "[INFO] Successfully installed nvidia-utils-${major}=${version}"
                return
            else
                echo "[WARN] Failed to install nvidia-utils-${major}=${version}, trying next..."
            fi
        done

        echo "[ERROR] All attempts to install nvidia-utils-${major} with prefix ${patch_prefix} failed"
    else
        echo "[WARN] /proc/driver/nvidia/version not found, skipping NVIDIA utils installation"
    fi
}

main() {
    install_runtime_packages
    configure_ssh
    ensure_nvidia_utils

    # 启动 ssh 服务
    exec /usr/sbin/sshd -D
}

main "$@"