#!/bin/bash
###############################################################################
# Instala tuning-vm (perfil selecionável)
# Autor: Diego Costa (@diegocostaroot) / Projeto Root (youtube.com/projetoroot)
# Versão: 1.0
# Veja o link: https://wiki.projetoroot.com.br
# 2026
###############################################################################

set -uo pipefail

# =========================================
# CONFIG
# =========================================

BASE_URL="https://raw.githubusercontent.com/projetoroot/tuning-vm/refs/heads/main"

URL_LIMITS="$BASE_URL/99-vm-limits.conf"
URL_BASELINE="$BASE_URL/99-vm-baseline.conf"
URL_WEB="$BASE_URL/99-vm-web.conf"
URL_DB="$BASE_URL/99-vm-db.conf"
URL_NET="$BASE_URL/99-vm-network.conf"
URL_CHECK="$BASE_URL/sysctl-vm-check.sh"

DEST_SYSCTL_DIR="/etc/sysctl.d"
DEST_CHECK="/usr/local/bin/sysctl-vm-check.sh"
SYSTEMD_CONF="/etc/systemd/system.conf"

PROFILE_FILE="/etc/sysctl-vm-profile-active"

# =========================================
# BASE FUNCTIONS
# =========================================

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Execute como root"
        exit 1
    fi
}

download_file() {
    local url="$1"
    local dest="$2"

    echo "Baixando $url"
    wget -q -O "$dest" "$url"
}

apply_sysctl() {
    echo "Aplicando sysctl"
    sysctl --system
}

append_systemd_limits() {

    touch "$SYSTEMD_CONF"

    grep -q "^DefaultLimitNOFILE=" "$SYSTEMD_CONF" || echo "DefaultLimitNOFILE=104857" >> "$SYSTEMD_CONF"
    grep -q "^DefaultLimitNPROC=" "$SYSTEMD_CONF" || echo "DefaultLimitNPROC=32768" >> "$SYSTEMD_CONF"

    systemctl daemon-reexec
}

# =========================================
# PROFILE CONTROL
# =========================================

get_active_profile() {
    [[ -f "$PROFILE_FILE" ]] && cat "$PROFILE_FILE" || echo "none"
}

save_profile() {
    echo "$1" > "$PROFILE_FILE"
}

profile_exists() {
    local current
    current=$(get_active_profile)
    [[ "$current" == "$1" ]]
}

ask_overwrite() {
    read -rp "Perfil já aplicado. Sobrescrever? (s/n): " RESP
    [[ "$RESP" =~ ^[sS]$ ]]
}

# =========================================
# CHECK
# =========================================

run_check() {
    local profile="$1"

    if [[ -x "$DEST_CHECK" ]]; then
        echo
        echo "Executando check para perfil $profile"
        "$DEST_CHECK" "$profile"
    else
        echo "Check não encontrado"
    fi
}

run_check_on_exit() {

    local active
    active=$(get_active_profile)

    echo
    echo "Perfil ativo ao sair: $active"

    if [[ "$active" != "none" ]]; then
        run_check "$active"
    fi
}

trap run_check_on_exit EXIT

clean_vm_sysctl() {
    echo "Limpando perfis VM antigos..."
    rm -f /etc/sysctl.d/99-vm-*.conf 2>/dev/null || true
}

# =========================================
# INSTALL PROFILE
# =========================================

install_profile() {

    local profile="$1"
    clean_vm_sysctl


    if profile_exists "$profile"; then
        echo "Perfil $profile já está ativo"
        if ! ask_overwrite; then
            return
        fi
    fi

    echo
    echo "Instalando limits"
    download_file "$URL_LIMITS" "$DEST_SYSCTL_DIR/99-vm-limits.conf"
    chmod 644 "$DEST_SYSCTL_DIR/99-vm-limits.conf"

    echo "Instalando baseline"
    download_file "$URL_BASELINE" "$DEST_SYSCTL_DIR/99-vm-baseline.conf"
    chmod 644 "$DEST_SYSCTL_DIR/99-vm-baseline.conf"

    case "$profile" in
        baseline)
            echo "Perfil baseline selecionado"
            ;;
        web)
            echo "Instalando perfil web"
            download_file "$URL_WEB" "$DEST_SYSCTL_DIR/99-vm-web.conf"
            chmod 644 "$DEST_SYSCTL_DIR/99-vm-web.conf"
            ;;
        db)
            echo "Instalando perfil db"
            download_file "$URL_DB" "$DEST_SYSCTL_DIR/99-vm-db.conf"
            chmod 644 "$DEST_SYSCTL_DIR/99-vm-db.conf"
            ;;
        network)
            echo "Instalando perfil network"
            download_file "$URL_NET" "$DEST_SYSCTL_DIR/99-vm-network.conf"
            chmod 644 "$DEST_SYSCTL_DIR/99-vm-network.conf"
            ;;
        *)
            echo "Perfil inválido"
            return 1
            ;;
    esac

    echo "Baixando script de check"
    download_file "$URL_CHECK" "$DEST_CHECK"
    chmod +x "$DEST_CHECK"

    append_systemd_limits
    apply_sysctl

    save_profile "$profile"

    echo
    echo "Perfil aplicado com sucesso"
    run_check "$profile"
}

# =========================================
# MAIN
# =========================================

require_root

while true; do

    ACTIVE=$(get_active_profile)

    echo
    echo "========================================"
    echo "Perfil ativo: $ACTIVE"
    echo "========================================"
    echo "1) Base Line"
    echo "2) Web / API"
    echo "3) Banco de Dados"
    echo "4) Firewall / Proxy"
    echo "99) Sair"
    echo "========================================"

    read -rp "Opção: " OPT

    case "$OPT" in
        1) install_profile baseline ;;
        2) install_profile web ;;
        3) install_profile db ;;
        4) install_profile network ;;
        99) exit 0 ;;
        *) echo "Opção inválida" ;;
    esac

done
