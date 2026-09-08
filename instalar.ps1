# Instalador da tradução PT-BR de KINGDOM HEARTS HD 2.8 Final Chapter Prologue
#
# Faz backup de cada arquivo original antes de tocar nele (`.original` ao lado),
# e só instala depois de conferir que o jogo está na versão esperada.
#
#   .\instalar.ps1              procura o jogo sozinho
#   .\instalar.ps1 -Jogo "..."  aponta a pasta na mão

param([string]$Jogo = "")

$ErrorActionPreference = "Stop"
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
$Patch = Join-Path $Base "patch"
$Xdelta = Join-Path $Patch "xdelta3.exe"
$Aplicador = Join-Path $Patch "aplicar_patch.py"

function Achar-Python {
    # reserva para quando o xdelta3.exe faltar ou o antivirus barrar
    foreach ($c in @("python", "python3", "py")) {
        $exe = (Get-Command $c -ErrorAction SilentlyContinue)
        if (-not $exe) { continue }
        $v = & $c -c "import sys; print(sys.version_info[0])" 2>$null
        if ($v -eq "3") { return $c }
    }
    return $null
}

function Aplicar-Patch($origem, $delta, $saida) {
    if (Test-Path $Xdelta) {
        & $Xdelta -d -f -s $origem $delta $saida
        return ($LASTEXITCODE -eq 0)
    }
    $py = Achar-Python
    if (-not $py) { return $false }
    & $py $Aplicador $origem $delta $saida | Out-Null
    return ($LASTEXITCODE -eq 0)
}

# nome -> (subpasta dentro do jogo, tamanho do original, tamanho depois)
$Alvos = @(
    @{ Nome = "SettingMenu"; Sub = "Image";    Antes = 972990192;  Depois = 972991392  },
    @{ Nome = "Launcher28";  Sub = "Image";    Antes = 1819443888; Depois = 1819445232 },
    @{ Nome = "kh3d_first";  Sub = "Image\dt"; Antes = 2982000752; Depois = 2981977088 },
    @{ Nome = "kh3d_fourth"; Sub = "Image\dt"; Antes = 2386041040; Depois = 2386042064 }
)

function Escrever($texto, $cor = "Gray") { Write-Host $texto -ForegroundColor $cor }

function Achar-Jogo {
    # a Steam guarda as bibliotecas num .vdf; o jogo pode estar em qualquer disco
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
Escrever "  KINGDOM HEARTS HD 2.8 Final Chapter Prologue - traducao PT-BR" "Cyan"
Escrever "  ------------------------------------------------------------" "DarkCyan"
Escrever ""

if (-not $Jogo) { $Jogo = Achar-Jogo }
if (-not $Jogo -or -not (Test-Path (Join-Path $Jogo "Image\dt\kh3d_first.pkg"))) {
    Escrever "  Nao achei a pasta do jogo." "Red"
    Escrever "  Rode assim, com a pasta entre aspas:" "Yellow"
    Escrever '    .\instalar.ps1 -Jogo "D:\SteamLibrary\steamapps\common\KINGDOM HEARTS HD 2.8 Final Chapter Prologue"'
    exit 1
}
Escrever "  Jogo: $Jogo"
Escrever ""

# --- confere antes de escrever qualquer coisa -------------------------------
$jaInstalado = $true
foreach ($a in $Alvos) {
    $pkg = Join-Path $Jogo "$($a.Sub)\$($a.Nome).pkg"
    $tam = (Get-Item $pkg).Length
    if ($tam -eq $a.Antes) { $jaInstalado = $false }
    elseif ($tam -ne $a.Depois) {
        Escrever "  $($a.Nome).pkg tem um tamanho que eu nao reconheco ($tam bytes)." "Red"
        Escrever "  Ou o jogo foi atualizado, ou ja' tem outra modificacao instalada." "Yellow"
        Escrever "  Verifique os arquivos pela Steam e tente de novo." "Yellow"
        exit 1
    }
}
if ($jaInstalado) {
    Escrever "  A traducao ja' esta' instalada. Nada a fazer." "Green"
    exit 0
}

# --- backup, sempre antes ---------------------------------------------------
Escrever "  Guardando os originais..." "Yellow"
foreach ($a in $Alvos) {
    foreach ($ext in @(".pkg", ".hed")) {
        $arq = Join-Path $Jogo "$($a.Sub)\$($a.Nome)$ext"
        $bak = "$arq.original"
        # so' cria o backup se ainda nao existir: rodar duas vezes nao pode
        # transformar o arquivo ja' traduzido em "original"
        if (-not (Test-Path $bak)) { Copy-Item $arq $bak }
    }
}
Escrever "  Backups em <arquivo>.original, ao lado de cada um." "DarkGray"
Escrever ""

# --- aplica -----------------------------------------------------------------
foreach ($a in $Alvos) {
    $pkg = Join-Path $Jogo "$($a.Sub)\$($a.Nome).pkg"
    $bak = "$pkg.original"
    $delta = Join-Path $Patch "$($a.Nome).pkg.xdelta"
    $tmp = "$pkg.novo"
    Escrever "  $($a.Nome).pkg ..." "Yellow"
    if (-not (Aplicar-Patch $bak $delta $tmp)) {
        Escrever "  Falhou em $($a.Nome)." "Red"
        if (-not (Test-Path $Xdelta)) {
            Escrever "  O xdelta3.exe nao esta' na pasta patch e nao achei Python 3." "Yellow"
            Escrever "  Baixe o pacote de novo, ou instale o Python (python.org)." "Yellow"
        }
        if (Test-Path $tmp) { Remove-Item $tmp -Force }
        exit 1
    }
    Move-Item $tmp $pkg -Force
    Copy-Item (Join-Path $Patch "$($a.Nome).hed") (Join-Path $Jogo "$($a.Sub)\$($a.Nome).hed") -Force
}

$paks = Join-Path $Jogo "KINGDOM HEARTS 0.2 Birth by Sleep\Content\Paks"
Copy-Item (Join-Path $Patch "TresGame-WindowsNoEditor_1_P.pak") $paks -Force
Escrever "  KINGDOM HEARTS 0.2 ..." "Yellow"

Escrever ""
Escrever "  Pronto! O jogo esta' em portugues." "Green"
Escrever "  Para voltar ao original, rode desinstalar.bat." "DarkGray"
Escrever ""
