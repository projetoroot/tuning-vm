#!/bin/bash
###############################################################################
# Instala tuning-vm (perfil selecionável )
# Autor: Diego Costa (@diegocostaroot) / Projeto Root (youtube.com/projetoroot)
# Versão: 1.3
# Veja o link: https://wiki.projetoroot.com.br
# 2026
###############################################################################

set -euo pipefail

# URLs base
BASE_URL="https://raw.githubusercontent.com/projetoroot/tuning-vm/refs/heads/main"

URL_LIMITS="$BASE_URL/99-vm-limits.conf"
URL_BASELINE="$BASE_URL/99-vm-baseline.conf"
URL_WEB="$BASE_URL/99-vm-web.conf"
URL_DB="$BASE_URL/99-vm-db.conf"
URL_NET="$BASE_URL/99-vm-network.conf"
URL_CHECK="$BASE_URL/sysctl-vm-check.sh"

# Destinos
DEST_SYSCTL_DIR="/etc/sysctl.d"
DEST_CHECK="/usr/local/bin/sysctl-vm-check.sh"
SYSTEMD_CONF="/etc/systemd/system.conf"

# =========================
# Funções
# =========================

download_file() {
    local url="$1"
    local dest="$2"

    echo "Baixando: $url"
    if ! wget -q -O "$dest" "$url"; then
        echo "Erro ao baixar: $url"
        return 1
    fi
}

apply_sysctl() {
    echo "Aplicando configurações..."
    sysctl --system
}

run_check() {
    echo "Executando validação..."
    chmod +x "$DEST_CHECK"
    "$DEST_CHECK"
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Execute como root."
        exit 1
    fi
}

append_systemd_limits() {
    echo "Ajustando limites globais no systemd..."

    touch "$SYSTEMD_CONF"

    if ! grep -q "^DefaultLimitNOFILE=" "$SYSTEMD_CONF"; then
        echo "DefaultLimitNOFILE=104857" >> "$SYSTEMD_CONF"
        echo "Adicionado DefaultLimitNOFILE"
    else
        echo "DefaultLimitNOFILE já existe, mantendo valor atual"
    fi

    if ! grep -q "^DefaultLimitNPROC=" "$SYSTEMD_CONF"; then
        echo "DefaultLimitNPROC=32768" >> "$SYSTEMD_CONF"
        echo "Adicionado DefaultLimitNPROC"
    else
        echo "DefaultLimitNPROC já existe, mantendo valor atual"
    fi

    echo "Recarregando daemon do systemd..."
    systemctl daemon-reexec
}

install_profile() {

    local profile="$1"

    echo ""
    echo "Instalando Limits (obrigatório)..."
    download_file "$URL_LIMITS" "$DEST_SYSCTL_DIR/99-vm-limits.conf"
    chmod 644 "$DEST_SYSCTL_DIR/99-vm-limits.conf"

    echo "Instalando Baseline (obrigatório)..."
    download_file "$URL_BASELINE" "$DEST_SYSCTL_DIR/99-vm-baseline.conf"
    chmod 644 "$DEST_SYSCTL_DIR/99-vm-baseline.conf"

    case "$profile" in
        1)
            echo "Perfil Base Line selecionado."
            ;;
        2)
            echo "Instalando perfil Web / API..."
            download_file "$URL_WEB" "$DEST_SYSCTL_DIR/99-vm-web.conf"
            chmod 644 "$DEST_SYSCTL_DIR/99-vm-web.conf"
            ;;
        3)
            echo "Instalando perfil Banco de Dados..."
            download_file "$URL_DB" "$DEST_SYSCTL_DIR/99-vm-db.conf"
            chmod 644 "$DEST_SYSCTL_DIR/99-vm-db.conf"
            ;;
        4)
            echo "Instalando perfil Firewall / Proxy..."
            download_file "$URL_NET" "$DEST_SYSCTL_DIR/99-vm-network.conf"
            chmod 644 "$DEST_SYSCTL_DIR/99-vm-network.conf"
            ;;
        *)
            echo "Perfil inválido."
            return 1
            ;;
    esac

    echo "Baixando script de validação..."
    download_file "$URL_CHECK" "$DEST_CHECK"

    append_systemd_limits
    apply_sysctl
    run_check

    echo ""
    echo "Instalação concluída com sucesso."
    echo ""
}

# =========================
# Execução
# =========================

require_root

while true; do

    echo "========================================"
    echo "Selecione o perfil da VM:"
    echo "1) Base Line (Obrigatório)"
    echo "2) Web / API"
    echo "3) Banco de Dados"
    echo "4) Firewall / Proxy"
    echo "99) Sair"
    echo "========================================"

    read -rp "Digite a opção desejada: " PROFILE

    case "$PROFILE" in
        1|2|3|4)
            install_profile "$PROFILE"
            ;;
        99)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida."
            ;;
    esac

done
