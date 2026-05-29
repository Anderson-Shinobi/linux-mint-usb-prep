#!/usr/bin/env bash
# =============================================================================
# Nome: Linux Mint USB Prep
# Versão: 0.1.2
# Autor: Anderson Nogueira
# Descrição: Prepara com segurança um pendrive para instalação do Linux Mint XFCE.
# Licença: MIT

## [0.1.2] - 2026-05-29

#- Fixed
#
#- Corrigida a validação de dispositivos removíveis.
#- Melhorada a detecção usando RM=1 ou transporte USB.
#- Adicionado diagnóstico quando um dispositivo é bloqueado.

# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DEVICE=""
PARTITION=""

die() {
    echo -e "${RED}Erro: $*${NC}" >&2
    exit 1
}

trap 'echo -e "${RED}Erro inesperado na linha $LINENO.${NC}" >&2' ERR

print_header() {
    echo -e "${BLUE}=== Linux Mint USB Prep v0.1.1 ===${NC}\n"
}

print_help() {
    cat <<'EOF'
Linux Mint USB Prep

Uso:
  sudo ./prepare_linux_mint_usb.sh
  ./prepare_linux_mint_usb.sh --help
  ./prepare_linux_mint_usb.sh --version

Descricao:
  Prepara um pendrive removivel com tabela GPT e uma particao FAT32.
  Este script nao grava a ISO do Linux Mint automaticamente.

Aviso:
  A operacao apaga permanentemente todos os dados do dispositivo escolhido.
  Informe o disco inteiro, por exemplo /dev/sdb, e nunca uma particao como /dev/sdb1.
EOF
}

print_version() {
    echo "0.1.1"
}

check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        die "Este script precisa ser executado como root ou com sudo. Use: sudo ./prepare_linux_mint_usb.sh"
    fi
}

check_dependencies() {
    local dependencies=(
        lsblk
        parted
        mkfs.vfat
        wipefs
        umount
        sync
        findmnt
        partprobe
        udevadm
    )
    local cmd

    for cmd in "${dependencies[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || die "Comando '$cmd' nao encontrado. Instale as dependencias."
    done
}

list_disks() {
    echo -e "${YELLOW}Discos disponiveis:${NC}"
    lsblk -d -o NAME,SIZE,MODEL,TRAN,RM | awk '$1 !~ /^loop/ {print}'
    echo
}

read_target_device() {
    read -r -p "Informe o dispositivo alvo (ex: /dev/sdb): " DEVICE
    [[ -n "$DEVICE" ]] || die "Nenhum dispositivo informado."
}

validate_block_device() {
    [[ -b "$DEVICE" ]] || die "Dispositivo $DEVICE nao existe ou nao e um bloco."
}

validate_not_partition() {
    local dev_name

    dev_name=$(lsblk -no TYPE "$DEVICE" 2>/dev/null | head -n1)
    [[ "$dev_name" == "disk" ]] || die "Voce informou uma particao ($DEVICE). Informe o disco inteiro, por exemplo /dev/sdb."
}

detect_root_disk() {
    local ROOT_SOURCE
    local ROOT_PARENT

    ROOT_SOURCE=$(findmnt -no SOURCE /)
    ROOT_PARENT=$(lsblk -no PKNAME "$ROOT_SOURCE" | head -n1)

    [[ -n "$ROOT_PARENT" ]] || die "Nao foi possivel detectar o disco raiz do sistema."
    echo "/dev/$ROOT_PARENT"
}

validate_not_system_disk() {
    local root_disk
    local critical_disks=(
        /dev/sda
        /dev/nvme0n1
        /dev/nvme1n1
    )
    local critical

    for critical in "${critical_disks[@]}"; do
        [[ "$DEVICE" != "$critical" ]] || die "$DEVICE e um disco critico do sistema. Operacao bloqueada."
    done

    root_disk=$(detect_root_disk)
    [[ "$DEVICE" != "$root_disk" ]] || die "Voce esta tentando formatar o disco onde o sistema esta instalado ($root_disk)."
}

validate_removable_device() {
    local is_removable
    local transport

    is_removable="$(lsblk -dnro RM "$DEVICE" 2>/dev/null | tr -d '[:space:]')"
    transport="$(lsblk -dnro TRAN "$DEVICE" 2>/dev/null | tr -d '[:space:]')"

    if [[ "$is_removable" == "1" ]]; then
        return 0
    fi

    if [[ "$transport" == "usb" ]]; then
        return 0
    fi

    echo -e "${RED}Erro: Por seguranca, esta versao so permite dispositivos removiveis.${NC}" >&2
    echo "Dispositivo informado: $DEVICE" >&2
    echo "RM detectado: ${is_removable:-desconhecido}" >&2
    echo "TRAN detectado: ${transport:-desconhecido}" >&2
    exit 1
}

show_device_summary() {
    echo -e "\n${YELLOW}=== RESUMO DO DISPOSITIVO ===${NC}"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT,MODEL,TRAN,RM "$DEVICE"
    echo
}

confirm_destruction() {
    local confirmation

    echo -e "${RED}ATENCAO: TODOS OS DADOS DO DISPOSITIVO $DEVICE SERAO APAGADOS PERMANENTEMENTE!${NC}"
    read -r -p "Digite exatamente 'FORMATAR' para confirmar: " confirmation

    [[ "$confirmation" == "FORMATAR" ]] || die "Confirmacao incorreta. Operacao cancelada."
}

unmount_partitions() {
    local part

    echo -e "\n${BLUE}Desmontando particoes...${NC}"
    while IFS= read -r part; do
        echo "Desmontando $part..."
        umount "$part" || umount -l "$part" || true
    done < <(lsblk -lnpo NAME,MOUNTPOINT "$DEVICE" | awk '$2 != "" {print $1}')
}

wipe_signatures() {
    local wipe

    read -r -p "Deseja limpar assinaturas antigas com wipefs? (S/n): " wipe
    if [[ "$wipe" != "n" && "$wipe" != "N" ]]; then
        echo "Limpando assinaturas antigas..."
        wipefs -af "$DEVICE"
    fi
}

get_partition_name() {
    local dev="$1"

    if [[ "$dev" =~ (nvme|mmcblk|loop) ]]; then
        echo "${dev}p1"
    else
        echo "${dev}1"
    fi
}

create_partition_table() {
    echo "Criando nova tabela GPT..."
    parted -s "$DEVICE" mklabel gpt

    echo "Criando particao FAT32..."
    parted -s "$DEVICE" mkpart primary fat32 1MiB 100%

    partprobe "$DEVICE" || true
    udevadm settle || true
    sleep 2

    PARTITION=$(get_partition_name "$DEVICE")
    [[ -b "$PARTITION" ]] || die "Particao $PARTITION nao foi criada corretamente."
}

format_partition() {
    echo "Formatando como FAT32 com label LINUX_MINT..."
    mkfs.vfat -F 32 -n "LINUX_MINT" "$PARTITION"
    sync
}

print_next_steps() {
    echo -e "\n${GREEN}Sucesso! Pendrive preparado com sucesso.${NC}"
    echo "Particao: $PARTITION"
    echo "Label: LINUX_MINT"

    echo -e "\n${YELLOW}Proximos passos:${NC}"
    echo "1. Para criar uma midia bootavel, grave a ISO com uma destas ferramentas:"
    echo "   - Mint USB Image Writer"
    echo "   - Balena Etcher"
    echo "   - Ventoy"
    echo "   - dd manual"
    echo
    echo "2. Exemplo com dd manual:"
    echo "   sudo dd if=caminho/para/linuxmint.iso of=$DEVICE bs=4M status=progress oflag=sync"
    echo
    echo "Ferramentas de gravacao de ISO podem sobrescrever a formatacao FAT32 criada por este script."
}

main() {
    case "${1:-}" in
        --help|-h)
            print_help
            exit 0
            ;;
        --version|-v)
            print_version
            exit 0
            ;;
        "")
            ;;
        *)
            die "Argumento invalido: $1. Use --help para ver as opcoes."
            ;;
    esac

    print_header
    check_root
    check_dependencies
    list_disks
    read_target_device
    validate_block_device
    validate_not_partition
    validate_not_system_disk
    validate_removable_device
    show_device_summary
    confirm_destruction
    unmount_partitions
    wipe_signatures
    create_partition_table
    format_partition
    print_next_steps
}

main "$@"
