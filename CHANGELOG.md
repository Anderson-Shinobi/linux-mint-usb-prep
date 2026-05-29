# Changelog

## [0.1.1] - 2026-05-29

### Fixed
- Corrigida a detecção do disco raiz usando findmnt.
- Corrigida a geração do nome da partição para dispositivos mmcblk e nvme.
- Adicionada sincronização com partprobe e udevadm após criação da partição.
- Melhorada a desmontagem de partições usando lsblk.
- Bloqueado o uso de dispositivos não removíveis por padrão.
- Melhorado tratamento de erros com função die e trap.

## [0.1.2] - 2026-05-29

### Fixed
- Corrigida a validação de dispositivos removíveis.
- Melhorada a detecção usando RM=1 ou transporte USB.
- Adicionado diagnóstico quando um dispositivo é bloqueado.

### Tested
- Validado em pendrive USB real detectado como /dev/sdb com RM=1 e TRAN=usb.

### Changed
- Refatorado o script em funções menores.
- Melhoradas mensagens de segurança para o usuário.
- Atualizada documentação sobre gravação de ISO e ferramentas externas.
