# Linux Mint USB Prep

Versao: 0.1.2

Script Bash para preparar com seguranca um pendrive removivel para instalacao do Linux Mint XFCE. Ele cria uma tabela GPT e uma particao FAT32 com o label `LINUX_MINT`.

## Aviso de seguranca

Este script executa operacoes destrutivas no disco escolhido. Se voce informar o dispositivo errado, os dados desse dispositivo serao apagados permanentemente.

Por seguranca, a versao 0.1.1 bloqueia particoes, discos criticos conhecidos, o disco raiz do sistema e dispositivos nao removiveis.

## Compatibilidade

- Linux Mint
- Ubuntu
- Debian

## Dependencias

- `lsblk`
- `parted`
- `mkfs.vfat`
- `wipefs`
- `umount`
- `sync`
- `findmnt`
- `partprobe`
- `udevadm`

Instale as dependencias com:

```bash
sudo apt update
sudo apt install util-linux parted dosfstools udev
```

## Como executar

```bash
chmod +x prepare_linux_mint_usb.sh
sudo ./prepare_linux_mint_usb.sh
```

## Ajuda e versao

```bash
./prepare_linux_mint_usb.sh --help
./prepare_linux_mint_usb.sh --version
```

## Sobre gravacao da ISO

Este script prepara o pendrive em FAT32, mas nao grava a ISO automaticamente.

Para criar uma midia bootavel, use uma ferramenta propria para gravacao de ISO:

- Mint USB Image Writer
- Balena Etcher
- Ventoy
- `dd`

Ferramentas de gravacao de ISO podem sobrescrever a tabela de particao e a formatacao FAT32 criadas anteriormente pelo script. Isso e esperado em muitos fluxos de criacao de midia bootavel.
