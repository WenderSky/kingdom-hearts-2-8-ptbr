# Devolve KINGDOM HEARTS HD 2.8 ao original, a partir dos backups `.original`
# que o instalador deixou ao lado de cada arquivo.

param([string]$Jogo = "")

$ErrorActionPreference = "Stop"
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path

$Alvos = @(
    @{ Nome = "SettingMenu"; Sub = "Image"    },
    @{ Nome = "Launcher28";  Sub = "Image"    },
    @{ Nome = "kh3d_first";  Sub = "Image\dt" }
)

function Escrever($texto, $cor = "Gray") { Write-Host $texto -ForegroundColor $cor }

function Achar-Jogo {
    $steam = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
    $pastas = @()
    if ($steam) {
        $pastas += $steam
        $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
        if (Test-Path $vdf) {
            Select-String -Path $vdf -Pattern '"path"\s+"(.+?)"' -AllMatches |
                ForEach-Object { $_.Matches } |
                ForEach-Object { $pastas += $_.Groups[1].Value.Replace("\\", "\") }
        }
    }
    $pastas += @("C:\Program Files (x86)\Steam", "D:\SteamLibrary", "E:\SteamLibrary",
                 "F:\SteamLibrary", "G:\SteamLibrary", "H:\SteamLibrary")
    foreach ($p in $pastas) {
        $alvo = Join-Path $p "steamapps\common\KINGDOM HEARTS HD 2.8 Final Chapter Prologue"
        if (Test-Path (Join-Path $alvo "Image\dt\kh3d_first.pkg")) { return $alvo }
    }
    return $null
}

Escrever ""
Escrever "  Desinstalando a traducao PT-BR" "Cyan"
Escrever ""

if (-not $Jogo) { $Jogo = Achar-Jogo }
if (-not $Jogo) { Escrever "  Nao achei a pasta do jogo." "Red"; exit 1 }

$achou = $false
foreach ($a in $Alvos) {
    foreach ($ext in @(".pkg", ".hed")) {
        $arq = Join-Path $Jogo "$($a.Sub)\$($a.Nome)$ext"
        $bak = "$arq.original"
        if (Test-Path $bak) {
            Move-Item $bak $arq -Force
            $achou = $true
            Escrever "  devolvido: $($a.Nome)$ext" "Yellow"
        }
    }
}

$pak = Join-Path $Jogo "KINGDOM HEARTS 0.2 Birth by Sleep\Content\Paks\TresGame-WindowsNoEditor_1_P.pak"
if (Test-Path $pak) {
    # este e' arquivo novo, nao substitui nenhum: some sem deixar buraco
    Remove-Item $pak -Force
    Escrever "  removido: TresGame-WindowsNoEditor_1_P.pak" "Yellow"
    $achou = $true
}

Escrever ""
if ($achou) {
    Escrever "  Pronto, o jogo voltou ao original." "Green"
} else {
    Escrever "  Nao achei backup nenhum: o jogo ja' esta' original." "Green"
    Escrever "  (Se precisar, use 'Verificar arquivos' na Steam.)" "DarkGray"
}
Escrever ""
