param
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Command,

    [Parameter(Mandatory = $false)]
    [string]
    $VSConfiguration = "Release"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Load the XML content of the .csproj file
[xml]$csproj = Get-Content "$PSScriptRoot\mod.csproj"

# Extract AssemblyName and VersionPrefix from the PropertyGroup
$script:targetName = $csproj.Project.PropertyGroup.AssemblyName
$script:version = $csproj.Project.PropertyGroup.VersionPrefix

# Set Folders
$script:AssemblyDistDir = "$PSScriptRoot\dist"
$script:RootDir = "$PSScriptRoot\.."
$script:ModDistDir = "$script:RootDir\dist"
$script:srcDir = "$script:RootDir\src"
$script:thirdPartyDir = "$script:RootDir\ThirdParty"
$script:mod_structureDir = "$script:RootDir\mod-structure"

# Check for RimWorld installations and set Folder
Write-Host "Looking for RimWorld installation..."

$InstallationPaths = Get-Content -Path "$PSScriptRoot\RimWorldPath.txt"
if ([string]::IsNullOrEmpty($InstallationPaths)) {
    Write-Host " -> No Path is read"
}


foreach ($path in $InstallationPaths) {
    # Write-Host " -  Resolve $path"
    $path = Invoke-Expression -Command $path
    # Write-Host " -  Checking $path"
    if (Test-Path $path) {
        Write-Host " -> Found RimWorld Path: $path"
        $script:installDir = $path
        break
    }
}
 
if ([string]::IsNullOrEmpty($script:installDir)) {
    Write-Host " -> RimWorld not found"
}




# FUNCTIONS
function RemoveDir($path) {
    while ($true) {
        if (!(Test-Path $path)) {
            return
        }

        Write-Host "Deleting $path"
        try {
            Remove-Item -Recurse $path
            break
        }
        catch {
            Write-Host "Could not remove $path, will retry"
            Start-Sleep 3
        }
    }
}

function Clean {
    RemoveDir $script:AssemblyDistDir
    RemoveDir $script:ModDistDir
    RemoveDir $script:thirdPartyDir
    mkdir $script:thirdPartyDir
    RemoveDir "$script:RootDir\.vscode\obj"
    RemoveDir "$script:RootDir\RimWorld.Ink"
}


function CopyDependencies {
    if (Test-Path "$script:thirdPartyDir\*.dll") {
        return
    }

    if ([string]::IsNullOrEmpty($script:installDir)) {
        Write-Host -ForegroundColor Yellow `
            "Rimworld installation not found; see Readme for how to set up pre-requisites manually."
        return
    }

    $depsDir = "$script:installDir\RimWorldWin64_Data\Managed"
    Write-Host "Copying dependencies from installation directory"
    if (!(Test-Path $script:thirdPartyDir)) { mkdir $script:thirdPartyDir | Out-Null }
    Copy-Item -Force "$depsDir\Unity*.dll" "$script:thirdPartyDir\"
    Copy-Item -Force "$depsDir\Assembly-CSharp.dll" "$script:thirdPartyDir\"
}

function Build {
    dotnet build
}

function PreBuild {
    Write-Host "PreBuild"
    RemoveDir $script:AssemblyDistDir
    CopyDependencies
}

function CopyFilesToRimworld {
    if ([string]::IsNullOrEmpty($script:installDir)) {
        Write-Host -ForegroundColor Yellow `
            "No RimWorld installation found, build will not be copied"

        return
    }

    $modsDir = "$script:installDir\Mods"
    $modDir = "$modsDir\$script:targetName"
    RemoveDir $modDir

    Write-Host "Copying mod to $modDir"
    Copy-Item -Recurse -Force -Exclude *.zip "$script:ModDistDir\*" $modsDir
}

function CreateModZipFile {
    Write-Host "Creating distro package"
    $distZip = "$script:ModDistDir\$script:targetName-$script:version.zip"
    RemoveDir $distZip
    $sevenZip = "$PSScriptRoot\7z.exe"
    & $sevenZip a -mx=9 "$distZip" "$script:ModDistDir\*"
    if ($LASTEXITCODE -ne 0) {
        throw "7zip command failed"
    }

    Write-Host "Created $distZip"
}

function PostBuild {
    Write-Host "PostBuild"

    if ([string]::IsNullOrEmpty($script:installDir)) {
        Write-Host -ForegroundColor Red `
            "Rimworld installation not found; not setting game version."
        return
    }

    # Set RimWorld version
    $versionParts = $script:version -split '\.'
    $shortVersion = "$($versionParts[0]).$($versionParts[1])"

    # Remove old files
    $defaultAssemblyDir = "$script:mod_structureDir\Assemblies\"
    $shortVersionAssemblyDir = "$script:mod_structureDir\$shortVersion\Assemblies\"
    RemoveDir($defaultAssemblyDir)
    mkdir $defaultAssemblyDir | Out-Null
    RemoveDir($shortVersionAssemblyDir)
    mkdir $shortVersionAssemblyDir | Out-Null

    # Copy assembly to mod-structure
    Copy-Item "$script:AssemblyDistDir\$script:targetName.dll" $defaultAssemblyDir
    Copy-Item "$script:AssemblyDistDir\$script:targetName.dll" $shortVersionAssemblyDir

    # Copy mod-structure to ModDestDir
    Copy-Item -Recurse -Force "$script:mod_structureDir\*" "$script:ModDistDir\$script:targetName"

    if ($VSConfiguration -eq "Debug") {
        $AboutFilePath = "$script:ModDistDir\$script:targetName\About\About.xml"

        # Get the current timestamp in the desired format
        $timestamp = Get-Date -Format "HH:mm - dd.MM.yyyy"

        # Read the file content
        [xml]$AboutFile = Get-Content -Path $AboutFilePath

        # Modify the <description> element by adding current timestamp at the beginning
        $AboutFile.ModMetaData.description = "Buildtime: $timestamp `r`n" + $AboutFile.ModMetaData.description

        # Save the modified XML back to the file
        $AboutFile.Save($AboutFilePath)

        Write-Host "About file updated successfully."
    }

    CreateModZipFile
    CopyFilesToRimworld
}

function StartRimWorld {
    if ([string]::IsNullOrEmpty($script:installDir)) {
        Write-Host -ForegroundColor Red `
            "Rimworld installation not found; not starting Game."
        return
    }
    Write-Host "Start RimWorld"
    Start-Process "$script:installDir\RimWorldWin64.exe" 
}



& $Command


