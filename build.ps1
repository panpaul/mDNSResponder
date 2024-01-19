# env
$arch = "ARM64", "x64"

# setup
$vs_path = Get-CimInstance -Namespace 'root/cimv2/vs' -ClassName 'MSFT_VSInstance' |
           Sort-Object -Property InstallationVersion -Descending |
           Select-Object -First 1 |
           Select-Object -ExpandProperty InstallLocation

if ($null -ne $vs_path) {
    $msbuild = Join-Path $vs_path 'MSBuild\Current\Bin\MSBuild.exe'
    if (!(Test-Path $msbuild)) {
        Write-Error "Launch-VsDevShell.ps1 not found"
        Exit 1
    }
} else {
    Write-Error "No suitable Visual Studio installation found"
    Exit 1
}


# build
foreach ($a in $arch) {
    & $msbuild mDNSResponder.sln -m -t:DLL "-p:Configuration=Release;Platform=$a;PostBuildEventUseInBuild=false"
    & $msbuild mDNSResponder.sln -m -t:mDNSResponder "-p:Configuration=Release;Platform=$a;PostBuildEventUseInBuild=false"
}

# copy sdk
foreach ($a in $arch) {
    New-Item -ItemType Directory -Force -Path "dist\$a\sdk\Bin"
    New-Item -ItemType Directory -Force -Path "dist\$a\sdk\Include"
    New-Item -ItemType Directory -Force -Path "dist\$a\sdk\Lib"

    Copy-Item -Force ".\mDNSShared\dns_sd.h" "dist\$a\sdk\Include"
    Copy-Item -Force ".\mDNSWindows\DLL\$a\Release\dnssd.lib" "dist\$a\sdk\Lib"
    Copy-Item -Force ".\mDNSWindows\DLL\$a\Release\dnssd.dll" "dist\$a\sdk\Bin"
    Copy-Item -Force ".\mDNSWindows\DLL\$a\Release\dnssd.dll.pdb" "dist\$a\sdk\Bin"
}

# copy service
foreach ($a in $arch) {
    New-Item -ItemType Directory -Force -Path "dist\$a\service"

    Copy-Item -Force ".\mDNSWindows\SystemService\$a\Release\mDNSResponder.exe" "dist\$a\service"
    Copy-Item -Force ".\mDNSWindows\SystemService\$a\Release\mDNSResponder.pdb" "dist\$a\service"
}
