# -*- coding: utf-8 -*-
"""Aplica um patch `.xdelta` sem precisar do xdelta3 instalado.

O SteamOS não traz o `xdelta3` e tem o sistema somente-leitura, então instalar
um pacote lá é um pedido que a maioria das pessoas não vai cumprir. Como
**decodificar** um patch é muito mais simples que gerar um, dá para fazer isso
aqui em Python puro, que o Deck já tem — e o mesmo arquivo serve de reserva no
Windows, se o `.exe` faltar ou for barrado pelo antivírus.

O formato é o VCDIFF do RFC 3284. Os patches deste projeto são gerados com
`-S none`, ou seja **sem compressão secundária**, o que deixa as três seções de
cada janela em claro e torna o decodificador direto. Eles também trazem
`VCD_ADLER32`, um checksum por janela: cada pedaço reconstruído é conferido
contra ele, então um patch corrompido é recusado em vez de gerar um arquivo
quebrado em silêncio.

Uso:
    python vcdiff.py original patch saida
"""
import sys
import zlib
from pathlib import Path

MAGIC = b"\xd6\xc3\xc4"
VCD_DECOMPRESS, VCD_CODETABLE, VCD_APPHEADER = 1, 2, 4
VCD_SOURCE, VCD_TARGET, VCD_ADLER32 = 1, 2, 4
NOOP, ADD, RUN, COPY = 0, 1, 2, 3
PERTO, IGUAL = 4, 3          # tamanho dos caches de endereço do RFC


def _tabela_padrao():
    """A tabela de códigos do RFC 3284, montada pelo algoritmo da seção 5.4.

    São 256 entradas, cada uma com até duas instruções: 1 + 18 + 144 + 72 + 12
    + 9. Um `tamanho` de 0 quer dizer que o valor vem como varint na seção de
    instruções, em vez de estar embutido no código.
    """
    t = [((NOOP, 0, 0), (NOOP, 0, 0)) for _ in range(256)]
    i = 0
    t[i] = ((RUN, 0, 0), (NOOP, 0, 0)); i += 1
    for tam in range(0, 18):
        t[i] = ((ADD, tam, 0), (NOOP, 0, 0)); i += 1
    for modo in range(9):
        t[i] = ((COPY, 0, modo), (NOOP, 0, 0)); i += 1
        for tam in range(4, 19):
            t[i] = ((COPY, tam, modo), (NOOP, 0, 0)); i += 1
    for modo in range(6):
        for t1 in range(1, 5):
            for t2 in range(4, 7):
                t[i] = ((ADD, t1, 0), (COPY, t2, modo)); i += 1
    for modo in range(6, 9):
        for t1 in range(1, 5):
            t[i] = ((ADD, t1, 0), (COPY, 4, modo)); i += 1
    for modo in range(9):
        t[i] = ((COPY, 4, modo), (ADD, 1, 0)); i += 1
    assert i == 256, i
    return t


TABELA = _tabela_padrao()


class _Fita:
    """Cursor sobre bytes, com o inteiro de tamanho variável do VCDIFF."""

    def __init__(self, dados, p=0):
        self.d, self.p = dados, p

    def u8(self):
        v = self.d[self.p]
        self.p += 1
        return v

    def varint(self):
        """Inteiro big-endian de 7 bits por byte; o bit alto diz que continua."""
        n = 0
        while True:
            b = self.d[self.p]
            self.p += 1
            n = (n << 7) | (b & 0x7F)
            if not b & 0x80:
                return n

    def bytes(self, n):
        v = self.d[self.p:self.p + n]
        self.p += n
        return v


class _Cache:
    """Os caches de endereço do VCDIFF: 4 posições recentes e 768 por resto."""

    def __init__(self):
        self.perto = [0] * PERTO
        self.proximo = 0
        self.igual = [0] * (IGUAL * 256)

    def anotar(self, endereco):
        self.perto[self.proximo] = endereco
        self.proximo = (self.proximo + 1) % PERTO
        self.igual[endereco % (IGUAL * 256)] = endereco

    def ler(self, modo, aqui, fita):
        if modo == 0:                       # endereço absoluto
            e = fita.varint()
        elif modo == 1:                     # para trás, a partir daqui
            e = aqui - fita.varint()
        elif modo - 2 < PERTO:              # perto de um endereço recente
            e = self.perto[modo - 2] + fita.varint()
        else:                               # igual a um endereço já visto
            m = modo - 2 - PERTO
            e = self.igual[m * 256 + fita.u8()]
        self.anotar(e)
        return e


def aplicar(origem, patch, destino, aviso=None):
    """Reconstrói `destino` a partir de `origem` e do `patch`.

    A saída é escrita janela a janela, e só o segmento da origem que a janela
    pede é lido do disco — dá para reconstruir um arquivo de 3 GB sem carregar
    nada disso na memória.
    """
    d = Path(patch).read_bytes()
    if d[:3] != MAGIC or d[3] != 0:
        raise ValueError("não é um patch xdelta/VCDIFF")
    f = _Fita(d, 4)
    indicador = f.u8()
    if indicador & VCD_DECOMPRESS:
        raise ValueError("patch com compressão secundária; gere com -S none")
    if indicador & VCD_CODETABLE:
        raise ValueError("patch com tabela de códigos própria, não suportada")
    if indicador & VCD_APPHEADER:
        f.bytes(f.varint())

    total = 0
    with open(origem, "rb") as fonte, open(destino, "wb") as saida:
        while f.p < len(d):
            win = f.u8()
            seg = pos = 0
            if win & (VCD_SOURCE | VCD_TARGET):
                seg, pos = f.varint(), f.varint()
            f.varint()                       # tamanho do bloco delta, não usado
            alvo_n = f.varint()
            if f.u8():
                raise ValueError("seções comprimidas; gere o patch com -S none")
            n_dados, n_inst, n_ender = f.varint(), f.varint(), f.varint()
            soma = int.from_bytes(f.bytes(4), "big") if win & VCD_ADLER32 else None

            if win & VCD_TARGET:
                raise ValueError("janela que se apoia no alvo, não suportada")
            fonte.seek(pos)
            base = fonte.read(seg) if seg else b""
            if len(base) != seg:
                raise ValueError("o arquivo original é menor do que o patch espera")

            dados = _Fita(f.bytes(n_dados))
            inst = _Fita(f.bytes(n_inst))
            ender = _Fita(f.bytes(n_ender))

            alvo = bytearray(alvo_n)
            i = 0
            cache = _Cache()
            while i < alvo_n:
                for tipo, tam, modo in TABELA[inst.u8()]:
                    if tipo == NOOP:
                        continue
                    n = tam or inst.varint()
                    if tipo == ADD:
                        alvo[i:i + n] = dados.bytes(n)
                        i += n
                    elif tipo == RUN:
                        alvo[i:i + n] = dados.u8().to_bytes(1, "big") * n
                        i += n
                    else:
                        e = cache.ler(modo, seg + i, ender)
                        if e < seg:
                            alvo[i:i + n] = base[e:e + n]
                            i += n
                        else:
                            # cópia dentro da própria janela: pode se sobrepor,
                            # e aí ela se repete — tem de ser byte a byte
                            e -= seg
                            for _ in range(n):
                                alvo[i] = alvo[e]
                                i += 1
                                e += 1
            if soma is not None and zlib.adler32(bytes(alvo)) & 0xFFFFFFFF != soma:
                raise ValueError("o patch não confere (checksum da janela)")
            saida.write(alvo)
            total += alvo_n
            if aviso:
                aviso(total)
    return total


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    if len(sys.argv) != 4:
        print("uso: python vcdiff.py original patch saida")
        raise SystemExit(2)
    n = aplicar(sys.argv[1], sys.argv[2], sys.argv[3])
    print(f"{n} bytes gravados em {sys.argv[3]}")
