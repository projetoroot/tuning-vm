#!/bin/bash

PROFILE="$1"

if [ -z "$PROFILE" ]; then
    echo "Uso: $0 {baseline|web|db|network}"
    exit 2
fi

echo "Validação de sysctl - Perfil de VM"
echo "Perfil selecionado: $PROFILE"
echo "Host: $(hostname)"
echo "Data: $(date)"
echo

FAIL=0

check() {
    local key="$1"
    local expected="$2"

    current=$(sysctl -n "$key" 2>/dev/null)

    if [ "$current" = "$expected" ]; then
        printf "[ OK ] %-45s = %s\n" "$key" "$current"
    else
        printf "[FAIL] %-45s esperado: %s | atual: %s\n" "$key" "$expected" "${current:-N/A}"
        FAIL=1
    fi
}

############################
# Baseline comum a todas as VMs
############################

baseline_checks() {
    echo "== VM Baseline =="
    check vm.swappiness 10
    check kernel.dmesg_restrict 1
    check kernel.kptr_restrict 2
    check fs.suid_dumpable 0
    check fs.protected_hardlinks 1
    check fs.protected_symlinks 1
    check fs.protected_fifos 1
    check fs.protected_regular 1
    echo
}

############################
# Perfil Web / API
############################

web_checks() {
    echo "== VM Web / API =="
    check net.core.somaxconn 8192
    check net.ipv4.tcp_max_syn_backlog 8192
    check net.ipv4.tcp_tw_reuse 1
    check net.ipv4.tcp_fin_timeout 15
    check net.ipv4.tcp_slow_start_after_idle 0
    echo
}

############################
# Perfil Banco de Dados
############################

db_checks() {
    echo "== VM Banco de Dados =="
    check vm.swappiness 1
    check vm.overcommit_memory 1
    echo
}

############################
# Perfil Firewall / Proxy
############################

network_checks() {
    echo "== VM Firewall / Proxy =="
    check net.core.netdev_max_backlog 10000
    check net.ipv4.tcp_max_syn_backlog 16384
    check net.ipv4.tcp_fin_timeout 10
    echo
}

############################
# Execução por perfil
############################

case "$PROFILE" in
    baseline)
        baseline_checks
        ;;
    web)
        baseline_checks
        web_checks
        ;;
    db)
        baseline_checks
        db_checks
        ;;
    network)
        baseline_checks
        network_checks
        ;;
    *)
        echo "Perfil inválido: $PROFILE"
        echo "Perfis válidos: baseline | web | db | network"
        exit 2
        ;;
esac

############################
# Resultado final
############################

if [ $FAIL -eq 0 ]; then
    echo "Resultado final: PERFIL '$PROFILE' APLICADO CORRETAMENTE"
    exit 0
else
    echo "Resultado final: EXISTEM PARÂMETROS FORA DO PADRÃO PARA O PERFIL '$PROFILE'"
    exit 1
fi
