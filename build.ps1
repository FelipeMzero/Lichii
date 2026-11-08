<#
.SYNOPSIS
    Compila o Lichii no Windows com MSVC/Clang e Ninja.

.DESCRIPTION
    Script de automação para carregar o ambiente de desenvolvimento MSVC,
    verificar dependências (glslangValidator, Ninja, Qt6), configurar o CMake
    e compilar o projeto com paralelismo otimizado para a CPU.

.PARAMETER Target
    Alvo do CMake a ser compilado (padrão: "yuzu", que gera "lichii.exe").

.PARAMETER BuildType
    Tipo de build: Release, RelWithDebInfo ou Debug (padrão: "Release").

.PARAMETER BuildDir
    Diretório de compilação (padrão: "build").

.PARAMETER Jobs
    Número de jobs paralelos para a compilação (padrão: número de processadores lógicos, ex: 12 no Ryzen 3600).

.PARAMETER Tests
    Habilita compilação de testes de unidade (-DYUZU_TESTS=ON).

.PARAMETER Clean
    Limpa o diretório de compilação antes de reconfigurar.
#>
[CmdletBinding()]
param(
    [string]$Target = "yuzu",
    [ValidateSet("Release", "RelWithDebInfo", "Debug")]
    [string]$BuildType = "Release",
    [string]$BuildDir = "build",
    [int]$Jobs = [Environment]::ProcessorCount,
    [switch]$Tests,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Lichii - Workflow de Compilação Local" -ForegroundColor Cyan
Write-Host " Branch: $(git -C "$RepoRoot" rev-parse --abbrev-ref HEAD)" -ForegroundColor Cyan
Write-Host " Target: $Target | BuildType: $BuildType" -ForegroundColor Cyan
Write-Host " Jobs: $Jobs threads" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Carregar ambiente MSVC
Write-Host "[1/4] Carregando ambiente Visual Studio C++..." -ForegroundColor Yellow
$loadMsvcScript = Join-Path $RepoRoot "tools\windows\load-msvc-env.ps1"
if (!(Test-Path $loadMsvcScript)) {
    throw "Script $loadMsvcScript não encontrado!"
}
. $loadMsvcScript

# 2. Garantir glslangValidator no PATH
Write-Host "[2/4] Verificando dependências de ferramentas (glslangValidator)..." -ForegroundColor Yellow
$glslangBin = Join-Path $RepoRoot ".tools\glslang\bin"
if (!(Get-Command "glslangValidator" -ErrorAction SilentlyContinue)) {
    if (Test-Path (Join-Path $glslangBin "glslangValidator.exe")) {
        Write-Host "-> Adicionando glslangValidator local ao PATH ($glslangBin)" -ForegroundColor Green
        $env:PATH = "$glslangBin;$env:PATH"
    } else {
        Write-Host "-> Baixando glslang release para $glslangBin..." -ForegroundColor Cyan
        $toolsDir = Join-Path $RepoRoot ".tools\glslang"
        if (!(Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null }
        gh release download 16.6.0 -R KhronosGroup/glslang -p "glslang-16.6.0-windows-x86_64-release.zip" --dir $toolsDir
        Expand-Archive -Path "$toolsDir\glslang-16.6.0-windows-x86_64-release.zip" -DestinationPath "$toolsDir" -Force
        Copy-Item "$glslangBin\glslang.exe" "$glslangBin\glslangValidator.exe" -Force
        $env:PATH = "$glslangBin;$env:PATH"
    }
}

# 3. Limpeza se solicitada
$FullBuildDir = Join-Path $RepoRoot $BuildDir
if ($Clean -and (Test-Path $FullBuildDir)) {
    Write-Host "-> Limpando $FullBuildDir..." -ForegroundColor Magenta
    Remove-Item -Recurse -Force $FullBuildDir
}

# 4. Configuração do CMake
Write-Host "[3/4] Configurando CMake com Ninja e Qt6 empacotado..." -ForegroundColor Yellow
$CMakeArgs = @(
    "-S", $RepoRoot,
    "-B", $FullBuildDir,
    "-G", "Ninja",
    "-DCMAKE_BUILD_TYPE=$BuildType",
    "-DYUZU_USE_BUNDLED_QT=ON",
    "-DENABLE_QT=ON",
    "-DYUZU_CMD=ON"
)

if ($Tests) {
    $CMakeArgs += "-DYUZU_TESTS=ON"
    $CMakeArgs += "-DBUILD_TESTING=ON"
} else {
    $CMakeArgs += "-DYUZU_TESTS=OFF"
}

cmake @CMakeArgs
if ($LASTEXITCODE -ne 0) {
    throw "Falha na configuração do CMake (Exit Code: $LASTEXITCODE)"
}

# 5. Compilação
Write-Host "[4/4] Compilando alvo '$Target' com $Jobs threads..." -ForegroundColor Yellow
cmake --build $FullBuildDir --target $Target --parallel $Jobs
if ($LASTEXITCODE -ne 0) {
    throw "Falha na compilação com Ninja (Exit Code: $LASTEXITCODE)"
}

$OutputExe = Join-Path $FullBuildDir "bin\lichii.exe"
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Compilação concluída com SUCESSO!" -ForegroundColor Green
if (Test-Path $OutputExe) {
    Write-Host " Executável gerado: $OutputExe" -ForegroundColor Green
}
Write-Host "========================================" -ForegroundColor Green
