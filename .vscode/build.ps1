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
$script:assemblyDistPath = "$PSScriptRoot\dist"
$script:rootPath = "$PSScriptRoot\.."
$script:modDistPath = "$script:rootPath\dist"
$script:srcPath = "$script:rootPath\src"
$script:thirdPartyPath = "$script:rootPath\ThirdParty"
$script:mod_structurePath = "$script:rootPath\mod-structure"

# Check for RimWorld installations and set Folder
function FindRimWorldInstallation {

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
            $script:RimWorldInstallationPath = $path
            return
        }
    }

    Write-Host " -> RimWorld not found"

}
FindRimWorldInstallation

# FUNCTIONS
function RemoveItem($path) {
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

# can be called by tasks.json from vscode
function Clean {
    RemoveItem $script:assemblyDistPath
    RemoveItem $script:modDistPath
    RemoveItem "$script:thirdPartyPath\*"
    RemoveItem "$script:rootPath\.vscode\obj"
}


function CopyDependencies {
    if (Test-Path "$script:thirdPartyPath\*.dll") {
        return
    }

    if ([string]::IsNullOrEmpty($script:RimWorldInstallationPath)) {
        Write-Host -ForegroundColor Yellow `
            "Rimworld installation not found; see Readme for how to set up pre-requisites manually."
        return
    }

    $depsPath = "$script:RimWorldInstallationPath\RimWorldWin64_Data\Managed"
    Write-Host "Copying dependencies from installation directory"
    if (!(Test-Path $script:thirdPartyPath)) { mkdir $script:thirdPartyPath | Out-Null }
    Copy-Item -Force "$depsPath\Unity*.dll" "$script:thirdPartyPath\"
    Copy-Item -Force "$depsPath\Assembly-CSharp.dll" "$script:thirdPartyPath\"
}

function Build {
    dotnet build "$PSScriptRoot\mod.csproj"
}

function PreBuild {
    Write-Host "PreBuild"
    RemoveItem $script:assemblyDistPath
    CopyDependencies
}

function CopyFilesToRimworld {
    if ([string]::IsNullOrEmpty($script:RimWorldInstallationPath)) {
        Write-Host -ForegroundColor Yellow `
            "No RimWorld installation found, build will not be copied"

        return
    }

    $modsPath = "$script:RimWorldInstallationPath\Mods"
    $thisModPath = "$modsPath\$script:targetName"
    RemoveItem $thisModPath

    Write-Host "Copying mod to $thismodPath"
    Copy-Item -Recurse -Force -Exclude *.zip "$script:modDistPath\*" $modsPath
}

function CreateModZipFile {
    Write-Host "Creating distro package"
    $distZip = "$script:modDistPath\$script:targetName-$script:version.zip"
    RemoveItem $distZip
    $sevenZip = "$PSScriptRoot\7z.exe"
    & $sevenZip a -mx=9 "$distZip" "$script:modDistPath\*"
    if ($LASTEXITCODE -ne 0) {
        throw "7zip command failed"
    }

    Write-Host "Created $distZip"
}

function PostBuild {
    Write-Host "PostBuild"

    if ([string]::IsNullOrEmpty($script:RimWorldInstallationPath)) {
        Write-Host -ForegroundColor Red `
            "Rimworld installation not found; not setting game version."
        return
    }

    # Set RimWorld version
    $versionParts = $script:version -split '\.'
    $shortVersion = "$($versionParts[0]).$($versionParts[1])"

    # Remove old files
    $defaultAssemblyPath = "$script:mod_structurePath\Assemblies"
    RemoveItem("$defaultAssemblyPath")
    $shortVersionAssemblyPath = "$script:mod_structurePath\$shortVersion\Assemblies"
    RemoveItem("$shortVersionAssemblyPath")

    # Copy assembly to mod-structure
    mkdir $defaultAssemblyPath | Out-Null
    Copy-Item "$script:assemblyDistPath\$script:targetName.dll" $defaultAssemblyPath
    mkdir $shortVersionAssemblyPath | Out-Null
    Copy-Item "$script:assemblyDistPath\$script:targetName.dll" $shortVersionAssemblyPath

    # Copy mod-structure to ModDestPath
    Copy-Item -Recurse -Force "$script:mod_structurePath\*" "$script:modDistPath\$script:targetName"

    if ($VSConfiguration -eq "Debug") {
        $AboutFilePath = "$script:modDistPath\$script:targetName\About\About.xml"

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
    if ([string]::IsNullOrEmpty($script:RimWorldInstallationPath)) {
        Write-Host -ForegroundColor Red `
            "Rimworld installation not found; not starting Game."
        return
    }
    Write-Host "Start RimWorld"
    Start-Process "$script:RimWorldInstallationPath\RimWorldWin64.exe" 
}



& $Command


