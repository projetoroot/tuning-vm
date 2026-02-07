# 🖥️ Proxmox VM Tuning and Hardening Profiles

**Autor:** Diego Costa (@diegocostaroot)  
**Canal no youtube:** Projeto Root ([youtube.com/projetoroot](https://www.youtube.com/projetoroot))  
**Wiki:** ([wiki.projetoroot.com.br](https://wiki.projetoroot.com.br))  
**Versão:** 1.0 | **Ano:** 2026  

Perfis de tuning e hardening baseados em sysctl para VMs, com separação clara entre otimizações do Host e ajustes seguros dentro das VMs.

---

## 📌 Objetivo

Este conjunto de ajustes busca melhorar desempenho entre **10% e 40%**, dependendo do hardware e carga aplicada.

Os ajustes ajudam a:

- Reduzir gargalos de rede e I/O  
- Melhorar latência de resposta  
- Evitar upgrade desnecessário de infraestrutura  
- Padronizar tuning em ambientes virtualizados  

> ⚠️ Após aplicar ajustes sysctl, recomenda-se reiniciar o sistema.

---

## 🧠 Modelo de responsabilidade

O princípio adotado é a separação clara entre Host e VM.

| Camada | Responsável | Tipo de Ajuste |
|---|---|---|
| 🖥 Host | Infraestrutura física | 🔴 Tuning agressivo rede, CPU e I/O |
| 📦 VM | Serviço hospedado | 🟡 Hardening + tuning leve |
| 🚫 VM | Bloqueado | ❌ Repetir tuning global do Host |

---

## 🔧 Compatibilidade

| Sistema | Versões Testadas | Observações |
|---|---|---|
| 🐧 Debian | 11, 12, 13 | Total compatibilidade com sysctl |
| 🐧 Ubuntu Server | 20.04 ou superior | Funciona em cloud e bare metal |
| 🧩 Outras distros | Linux moderno | Requer sysctl e /etc/sysctl.d |

> ⚠️ Sistemas sem sysctl ou sem `/etc/sysctl.d` não são compatíveis.

---

## 🎛️ Perfis Disponíveis para VM

| Opção | Perfil | Arquivo Criado | Efeito Principal |
|---|---|---|---|
| 1️⃣ | **VM Baseline** | `99-vm-baseline.conf` | 🛡 Hardening básico kernel e filesystem |
| 2️⃣ | **VM Web / API** | `99-vm-web.conf` | 🌐 Melhor handling de conexões TCP |
| 3️⃣ | **VM Banco de Dados** | `99-vm-db.conf` | 🧠 Otimização memória e swap |
| 4️⃣ | **VM Firewall / Proxy** | `99-vm-network.conf` | 📡 Ajuste de filas e backlog de rede |

---

## 📂 Arquivos Sysctl

| Perfil | Caminho |
|---|---|
| 🟦 Baseline | [99-vm-baseline.conf](./99-vm-baseline.conf) |
| 🟩 Web | [99-vm-web.conf](./99-vm-web.conf) |
| 🟥 Database | [99-vm-db.conf](./99-vm-db.conf) |
| 🟧 Network | [99-vm-network.conf](./99-vm-network.conf) |

---

## 🔢 Padrão Prefixo 99

Arquivos sysctl são carregados em ordem alfabética:

```
/usr/lib/sysctl.d/
/run/sysctl.d/
/etc/sysctl.d/
/etc/sysctl.conf
```

Exemplo:

```
10-default.conf
50-network.conf
99-custom.conf
```

O prefixo 99 garante:

- Aplicação por último  
- Sobrescrita de configs da distro  
- Comportamento previsível  
- Facilidade de auditoria  

---

## 💻 Aplicação Manual

### Aplicar perfil
```bash
cp 99-vm-baseline.conf /etc/sysctl.d/
sysctl --system
```

### Validar parâmetros aplicados
```bash
sysctl -a | grep net
```

---

## 🧪 Checklist Pós Aplicação

| Item | Status Esperado |
|---|---|
| Arquivo copiado | ✅ |
| sysctl aplicado | ✅ |
| Sem conflito com Host | ✅ |
| Reboot realizado | ✅ |

---

## 📁 Estrutura Recomendada do Repositório

```
│ ├ 99-vm-baseline.conf
│ ├ 99-vm-web.conf
│ ├ 99-vm-db.conf
│ └ 99-vm-limits.conf
│ └ 99-vm-network.conf
│ └ sysctl-vm-check.sh
│ └ install.sh
```

---

## 📚 Boas práticas

✔ Nunca aplicar tuning agressivo dentro da VM  
✔ Priorizar tuning pesado apenas no Host  
✔ Testar em VM antes de aplicar em produção  
✔ Manter backup antes de alterações  

---

⚠️ **Instalação / Install**

Script de instalação 

Installation script 

As instruções devem ser executadas como root, pois usuários comuns não têm acesso aos arquivos.

Instructions be performed as 'root', as normal users do not have access to the files.

wget https://raw.githubusercontent.com/projetoroot/tuning-vm/refs/heads/main/install.sh

bash install.sh
