+++
date = '2026-04-04T10:27:11-03:00'
draft = false
title = 'Script Backup Saves De Baldurs Gate 3'
tags = ["bg3", "baldurs gate 3", "script", "bash"]
+++

Estava precisando fazer backup dos meus saves do baldurs gate 3 porque uns amigos meus querem jogar o modo honra sem se preocupar com a questão de perder o save para sempre :/, então vamos lá.

O caminho para o save do baldur's gate 3 nativo no linux é:

```
~/.local/share/Larian Studios/Baldur's Gate 3/PlayerProfiles/Public
```

O caminho para quem estiver jogando no proton é:

```
/games/SteamLibrary/steamapps/compatdata/1086940/pfx/drive_c/users/steamuser/AppData/Local/Larian Studios/Baldur's Gate 3/PlayerProfiles/Public
```

No meu caso, eu tenho uma partição "**/games**" onde eu instalo os meus jogos, mas se estivesse instalado no **home**, o caminho deve ser algo como:

```
~/.steam/steam/steamapps/compatdata/1086940/pfx/drive_c/users/steamuser/AppData/Local/Larian Studios/Baldur's Gate 3/PlayerProfiles/Public
```

Segue o script simples para criar um .tar.gz dos arquivos do save, aproveitei e fiz um restore. É possível rodar sem especificar o destino do backup, pasta default é ~/Documents/

```bash
#!/usr/bin/env bash
# backup_bg3.sh — Backup e restore dos saves do Baldur's Gate 3
#
# USO:
#   Backup:   ./backup_bg3.sh -m backup [-d /caminho/destino]
#   Restore:  ./backup_bg3.sh -m restore [-f /caminho/arquivo.tar.gz] [-d /caminho/destino]
#
# FLAGS:
#   -m <modo>     Modo de operação: backup | restore  (obrigatório)
#   -d <dir>      Pasta base para salvar/buscar backups (padrão: ~/Documents)
#   -f <arquivo>  Arquivo .tar.gz específico para restore (padrão: mais recente em -d)
#   -h            Mostra ajuda

set -euo pipefail

# Constantes
SAVES_DIR="/home/emerson/.local/share/Larian Studios/Baldur's Gate 3/PlayerProfiles/Public"
DEFAULT_DEST="$HOME/Documents"

# Defaults
MODE=""
DEST_DIR="$DEFAULT_DEST"
RESTORE_FILE=""

# Helpers
usage() {
    cat <<EOF
USO:
  $0 -m backup  [-d /caminho/destino]
  $0 -m restore [-f /caminho/arquivo.tar.gz] [-d /caminho/destino]

FLAGS:
  -m <modo>     Modo de operação: backup | restore  (obrigatório)
  -d <dir>      Pasta base para salvar/buscar backups (padrão: ~/Documents)
  -f <arquivo>  Arquivo .tar.gz específico para restore (padrão: mais recente em -d)
  -h            Exibe esta ajuda
EOF
    exit 0
}

erro() {
    echo "Erro: $*" >&2
    exit 1
}

# Parse flags
while getopts ":m:d:f:h" opt; do
    case $opt in
        m) MODE="$OPTARG" ;;
        d) DEST_DIR="$OPTARG" ;;
        f) RESTORE_FILE="$OPTARG" ;;
        h) usage ;;
        :) erro "A flag -$OPTARG requer um argumento." ;;
        \?) erro "Flag desconhecida: -$OPTARG. Use -h para ajuda." ;;
    esac
done

[[ -z "$MODE" ]] && erro "Flag -m <modo> é obrigatória. Use: backup | restore"
[[ "$MODE" != "backup" && "$MODE" != "restore" ]] && erro "Modo inválido '$MODE'. Use: backup | restore"

# Modo BACKUP
do_backup() {
    [[ ! -d "$SAVES_DIR" ]] && erro "Pasta de saves não encontrada: $SAVES_DIR"

    mkdir -p "$DEST_DIR"

    local timestamp filename output
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    filename="bg3_saves_${timestamp}.tar.gz"
    output="$DEST_DIR/$filename"

    echo "Iniciando backup..."
    echo "  Origem : $SAVES_DIR"
    echo "  Destino: $output"

    tar -czf "$output" \
        --warning=no-file-changed \
        -C "$(dirname "$SAVES_DIR")" \
        "$(basename "$SAVES_DIR")"

    local size
    size=$(du -sh "$output" | cut -f1)
    echo "Backup concluído! ($size)"
    echo "  Arquivo: $output"
}

# Modo RESTORE
do_restore() {
    # Se não foi passado -f, busca o .tar.gz mais recente em DEST_DIR
    if [[ -z "$RESTORE_FILE" ]]; then
        echo "Nenhum arquivo especificado. Buscando o mais recente em: $DEST_DIR"
        RESTORE_FILE=$(find "$DEST_DIR" -maxdepth 1 -name "bg3_saves_*.tar.gz" \
                        -printf "%T@ %p\n" 2>/dev/null \
                        | sort -n | tail -1 | cut -d' ' -f2-)
        [[ -z "$RESTORE_FILE" ]] && erro "Nenhum arquivo bg3_saves_*.tar.gz encontrado em: $DEST_DIR"
        echo "  Encontrado: $RESTORE_FILE"
    fi

    [[ ! -f "$RESTORE_FILE" ]] && erro "Arquivo não encontrado: $RESTORE_FILE"

    # Garante que o destino dos saves existe
    mkdir -p "$SAVES_DIR"

    echo ""
    echo "Iniciando restore..."
    echo "  Arquivo : $RESTORE_FILE"
    echo "  Destino : $SAVES_DIR"
    echo ""
    echo "Arquivos no destino que não estão no backup serão mantidos."

    # --overwrite: substitui arquivos que existem no tar
    # Sem --recursive-unlink: arquivos extras no destino são preservados
    tar -xzf "$RESTORE_FILE" \
        --warning=no-file-changed \
        -C "$(dirname "$SAVES_DIR")" \
        --overwrite

    echo "Restore concluído!"
    echo "  Saves restaurados em: $SAVES_DIR"
}

# Execução
case "$MODE" in
    backup)  do_backup ;;
    restore) do_restore ;;
esac
```