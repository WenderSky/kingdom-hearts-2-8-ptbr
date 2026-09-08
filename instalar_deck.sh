#!/bin/bash
# Instalador da tradução PT-BR de KINGDOM HEARTS HD 2.8 — Steam Deck e Linux.
#
#   ./instalar_deck.sh                 procura o jogo sozinho
#   ./instalar_deck.sh /caminho/jogo   aponta a pasta na mão
#   ./instalar_deck.sh --tirar         volta ao original
#
# O SteamOS não traz o xdelta3 e tem o sistema somente-leitura, então pedir para
# instalar um pacote é pedir o que a maioria não vai fazer. Por isso o pacote
# leva `patch/aplicar_patch.py`, que aplica o patch em Python puro — e o Deck já
# vem com Python 3. O xdelta3 do sistema é usado quando existe, só porque é
# ainda mais rápido; nenhum dos dois é obrigatório sozinho.

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
    for par in "Image:SettingMenu" "Image:Launcher28" "Image/dt:kh3d_first" "Image/dt:kh3d_fourth"; do
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

# Como aplicar o patch: o xdelta3 do sistema, se houver, senão o Python que
# vem no pacote. O Deck tem Python 3 de fábrica, então na prática sempre há um.
PY=""
if command -v xdelta3 >/dev/null 2>&1; then
    MODO="xdelta3"
else
    for cand in python3 python; do
        if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'import sys;sys.exit(0 if sys.version_info[0]==3 else 1)' 2>/dev/null; then
            PY="$cand"; break
        fi
    done
    if [ -z "$PY" ]; then
        vermelho "  Não achei nem o xdelta3 nem o Python 3 — preciso de um dos dois."
        echo
        echo    "  O Steam Deck vem com Python 3 de fábrica; se você chegou aqui, é um"
        echo    "  caso fora do comum. Saídas:"
        echo    "   1) instale o python3 ou o xdelta3 e rode este script de novo;"
        echo    "   2) rode o instalar.bat num PC com Windows e copie de lá estes"
        echo    "      arquivos, para os mesmos lugares aqui:"
        echo    "        Image/SettingMenu.pkg   Image/SettingMenu.hed"
        echo    "        Image/Launcher28.pkg    Image/Launcher28.hed"
        echo    "        Image/dt/kh3d_first.pkg Image/dt/kh3d_first.hed"
        echo    "        Image/dt/kh3d_fourth.pkg Image/dt/kh3d_fourth.hed"
        echo    "        KINGDOM HEARTS 0.2 Birth by Sleep/Content/Paks/TresGame-WindowsNoEditor_1_P.pak"
        exit 1
    fi
    MODO="python"
fi
echo "  Aplicando o patch com: $MODO"
echo

amarelo "  Guardando os originais..."
for par in "Image:SettingMenu" "Image:Launcher28" "Image/dt:kh3d_first" "Image/dt:kh3d_fourth"; do
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

for par in "Image:SettingMenu" "Image:Launcher28" "Image/dt:kh3d_first" "Image/dt:kh3d_fourth"; do
    sub="${par%%:*}"; nome="${par##*:}"
    amarelo "  $nome.pkg ..."
    if [ "$MODO" = "xdelta3" ]; then
        ok=$(xdelta3 -d -f -s "$JOGO/$sub/$nome.pkg.original" \
                     "$PATCHDIR/$nome.pkg.xdelta" "$JOGO/$sub/$nome.pkg.novo" \
             && echo sim)
    else
        ok=$("$PY" "$PATCHDIR/aplicar_patch.py" "$JOGO/$sub/$nome.pkg.original" \
                   "$PATCHDIR/$nome.pkg.xdelta" "$JOGO/$sub/$nome.pkg.novo" \
             >/dev/null && echo sim)
    fi
    if [ "$ok" != "sim" ]; then
        vermelho "  falhou em $nome"
        rm -f "$JOGO/$sub/$nome.pkg.novo"
        exit 1
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
