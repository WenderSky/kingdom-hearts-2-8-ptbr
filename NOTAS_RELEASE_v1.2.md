# v1.2 — o nome que discordava do irmão

Esta versão não traz texto novo: ela acerta **13 termos** que estavam escritos
de um jeito aqui e de outro na tradução de KINGDOM HEARTS HD 1.5+2.5 ReMIX.

As duas coletâneas contam a mesma história, com os mesmos lugares, e quem joga
as duas nota quando o nome muda de uma para a outra.

## 🏰 Castle Oblivion

O castelo onde Sora perde as memórias aparece nas duas coletâneas. A decisão
do glossário foi deixá-lo **em inglês** — foram 72 ocorrências no 1.5+2.5
contra 7 aqui, e é assim que a série o chama.

| era | ficou |
|---|---|
| visitou o Castelo do Esquecimento | **visitou Castle Oblivion** |
| mandado ao “Castelo do Esquecimento” | **mandado a “Castle Oblivion”** |
| chegou ao Castelo do Esquecimento | **chegou a Castle Oblivion** |
| partiu do Castelo do Esquecimento | **partiu de Castle Oblivion** |
| se transforma no Castelo do Esquecimento | **se transforma em Castle Oblivion** |

Repare que não é só o substantivo: o 1.5+2.5 **não põe artigo** antes do nome
— são 10 ocorrências lá, todas *em Castle Oblivion*, nunca *no Castle
Oblivion*. As contrações voltaram a ser preposição solta.

## 🏰 Castelo Disney

O inglês diz `Disney Castle`. O 1.5+2.5 escreve **Castelo Disney** nas suas 50
ocorrências; aqui estava **Castelo do Disney**, em 7 lugares. Agora batem.

## 📦 O que muda no seu jogo

| arquivo | |
|---|---|
| `kh3d_first` | as crônicas e os relatórios do Dream Drop Distance |
| `kh3d_fourth` | um diálogo do Yen Sid |
| `TresGame..._1_P.pak` | o glossário do KINGDOM HEARTS 0.2 |

`SettingMenu` e `Launcher28` **não mudam** em relação à 1.1.

## 🔧 E o instalador, que não deixava atualizar

Até a 1.1 o instalador decidia **só pelo tamanho do arquivo**: ele sabia
distinguir "de fábrica" de "traduzido", mas não *qual versão* estava
instalada. Olhando um jogo na 1.1, ele dizia **"a tradução já está instalada,
nada a fazer"** — e se recusava a aplicar a versão que ele próprio trazia.

Agora a pergunta que ele faz é outra. Como o patch é sempre reconstruído a
partir do **original de fábrica** (o `.original` que ele mesmo guardou), o que
importa não é o que está instalado, e sim **se há de onde partir**. Com isso,
atualizar de qualquer versão anterior funciona igual a instalar do zero.

## ⬆️ Atualizando

Instale por cima, como sempre. O instalador reconstrói cada `.pkg` a partir do
**original do próprio jogo**, então ele confere a versão de graça: um patch só
aplica sobre o byte exato de que saiu.

Se você já tem a 1.1 instalada, é só rodar por cima: o instalador reconhece e
atualiza no lugar.
