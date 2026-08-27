#!/bin/bash
# Instalador da tradução PT-BR de KINGDOM HEARTS HD 2.8 — Steam Deck e Linux.
#
#   ./instalar_deck.sh                 procura o jogo sozinho
#   ./instalar_deck.sh /caminho/jogo   aponta a pasta na mão
#   ./instalar_deck.sh --tirar         volta ao original
#
# O SteamOS não traz o xdelta3, e o sistema é somente-leitura, então instalar
# um pacote ali é chato. Se ele não estiver presente, o script explica o
# caminho manual: aplicar o patch num PC com Windows e copiar os arquivos
# prontos para o Deck — que é o método que o LEIA-ME chama de manual.

set -u
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHDIR="$BASE/patch"

verde()   { printf '\033[1;32m%s\033[0m\n' "$1"; }
amarelo() { printf '\033[1;33m%s\033[0m\n' "$1"; }
vermelho(){ printf '\033[1;31m%s\033[0m\n' "$1"; }

achar_jogo() {
    local nome="KINGDOM HEARTS HD 2.8 Final Chapter Prologue"
    local candidatos=(
        "$HOME/.local/share/Steam/steamapps/common/$nome"
        "$HOME/.steam/steam/steamapps/common/$nome"
        "/run/media/mmcblk0p1/steamapps/common/$nome"
        "/run/media/deck/"*"/steamapps/common/$nome"
    )
    for p in "${candidatos[@]}"; do
        [ -f "$p/Image/dt/kh3d_first.pkg" ] && { echo "$p"; return 0; }
    done
    return 1
}

TIRAR=0
JOGO=""
for arg in "$@"; do
    case "$arg" in
        --tirar|--desinstalar) TIRAR=1 ;;
        *) JOGO="$arg" ;;
    esac
done
[ -z "$JOGO" ] && JOGO="$(achar_jogo || true)"

echo
verde "  KINGDOM HEARTS HD 2.8 Final Chapter Prologue — tradução PT-BR"
echo

if [ -z "$JOGO" ] || [ ! -f "$JOGO/Image/dt/kh3d_first.pkg" ]; then
    vermelho "  Não achei a pasta do jogo."
    echo    "  Rode assim, com a pasta entre aspas:"
    echo    "    ./instalar_deck.sh \"/caminho/para/KINGDOM HEARTS HD 2.8 Final Chapter Prologue\""
    exit 1
fi
echo "  Jogo: $JOGO"
echo

PAKS="$JOGO/KINGDOM HEARTS 0.2 Birth by Sleep/Content/Paks"

if [ "$TIRAR" = "1" ]; then
    achou=0
    for par in "Image:SettingMenu" "Image:Launcher28" "Image/dt:kh3d_first"; do
        sub="${par%%:*}"; nome="${par##*:}"
        for ext in pkg hed; do
            bak="$JOGO/$sub/$nome.$ext.original"
            if [ -f "$bak" ]; then
                mv -f "$bak" "$JOGO/$sub/$nome.$ext"
                amarelo "  devolvido: $nome.$ext"; achou=1
            fi
        done
    done
    if [ -f "$PAKS/TresGame-WindowsNoEditor_1_P.pak" ]; then
        rm -f "$PAKS/TresGame-WindowsNoEditor_1_P.pak"
        amarelo "  removido: TresGame-WindowsNoEditor_1_P.pak"; achou=1
    fi
    echo
    [ "$achou" = "1" ] && verde "  Pronto, o jogo voltou ao original." \
                       || verde "  Nada a desfazer: o jogo já está original."
    exit 0
fi

if ! command -v xdelta3 >/dev/null 2>&1; then
    vermelho "  O xdelta3 não está instalado, e sem ele não dá para aplicar o patch aqui."
    echo
    echo    "  Duas saídas:"
    echo    "   1) instale o xdelta3 e rode este script de novo;"
    echo    "   2) use o método manual: rode o instalar.bat num PC com Windows,"
    echo    "      copie de lá os arquivos abaixo e ponha nos mesmos lugares aqui."
    echo    "        Image/SettingMenu.pkg   Image/SettingMenu.hed"
    echo    "        Image/Launcher28.pkg    Image/Launcher28.hed"
    echo    "        Image/dt/kh3d_first.pkg Image/dt/kh3d_first.hed"
    echo    "        KINGDOM HEARTS 0.2 Birth by Sleep/Content/Paks/TresGame-WindowsNoEditor_1_P.pak"
    exit 1
fi

amarelo "  Guardando os originais..."
for par in "Image:SettingMenu" "Image:Launcher28" "Image/dt:kh3d_first"; do
    sub="${par%%:*}"; nome="${par##*:}"
    for ext in pkg hed; do
        arq="$JOGO/$sub/$nome.$ext"
        # só cria o backup se ainda não existir: rodar duas vezes não pode
        # transformar o arquivo já traduzido em "original"
        [ -f "$arq.original" ] || cp "$arq" "$arq.original"
    done
done
echo "  Backups em <arquivo>.original, ao lado de cada um."
echo

for par in "Image:SettingMenu" "Image:Launcher28" "Image/dt:kh3d_first"; do
    sub="${par%%:*}"; nome="${par##*:}"
    amarelo "  $nome.pkg ..."
    if ! xdelta3 -d -f -s "$JOGO/$sub/$nome.pkg.original" \
                 "$PATCHDIR/$nome.pkg.xdelta" "$JOGO/$sub/$nome.pkg.novo"; then
        vermelho "  falhou em $nome"; exit 1
    fi
    mv -f "$JOGO/$sub/$nome.pkg.novo" "$JOGO/$sub/$nome.pkg"
    cp -f "$PATCHDIR/$nome.hed" "$JOGO/$sub/$nome.hed"
done
amarelo "  KINGDOM HEARTS 0.2 ..."
cp -f "$PATCHDIR/TresGame-WindowsNoEditor_1_P.pak" "$PAKS/"

echo
verde "  Pronto! O jogo está em português."
echo "  Para voltar ao original: ./instalar_deck.sh --tirar"
echo
