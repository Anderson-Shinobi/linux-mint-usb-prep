# Uso

## Identificando o pendrive

Conecte o pendrive e use:

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT,MODEL,TRAN,RM
```

Procure um dispositivo com `TYPE` igual a `disk`, transporte USB quando disponivel em `TRAN`, e `RM` igual a `1`.

## Disco vs particao

Informe sempre o disco inteiro, nao uma particao.

Exemplo correto:

```text
/dev/sdb
```

Exemplo errado:

```text
/dev/sdb1
```

Particoes possuem um numero no final, como `/dev/sdb1`. Em dispositivos `mmcblk`, o disco pode ser `/dev/mmcblk0` e a particao `/dev/mmcblk0p1`.

## Dispositivos mmcblk

Cartoes SD e alguns leitores aparecem como `mmcblk`. O nome do disco costuma ser:

```text
/dev/mmcblk0
```

A primeira particao costuma ser:

```text
/dev/mmcblk0p1
```

O script aceita o disco `/dev/mmcblk0` quando ele for removivel e bloqueia a particao `/dev/mmcblk0p1`.

## Riscos do dd

O `dd` grava bytes diretamente no dispositivo informado. Se o destino estiver errado, ele pode sobrescrever um disco do sistema ou outro disco com dados importantes.

Use `dd` apenas se voce tiver certeza absoluta do dispositivo de destino.

## Recomendacao para iniciantes

Usuarios iniciantes devem preferir uma ferramenta grafica para gravar a ISO, como Mint USB Image Writer, Balena Etcher ou Ventoy. Elas reduzem o risco de escolher o dispositivo errado e tornam o fluxo de criacao da midia bootavel mais claro.
