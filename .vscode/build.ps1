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


# Set folder paths
$script:path_vscode = "$PSScriptRoot"
$script:path_projectRoot = Resolve-Path "$script:path_vscode\.."
$script:path_assemblyOutput = "$script:path_vscode\bin"
$script:path_modOutput = "$script:path_projectroot\output"
$script:path_src = "$script:path_projectroot\src"
$script:path_localDependencies = "$script:path_projectroot\localDependencies"
$script:path_mod_structure = "$script:path_projectroot\mod-structure"

# Set file paths
$script:file_helperscriptPS1 = "$script:path_vscode\helperscript.ps1"
$script:file_RimWorldPathTXT = "$script:path_vscode\RimWorldPath.txt"
$script:file_thirdPartyDependenciesTXT = "$script:path_vscode\ThirdPartyDependencies.txt"
$script:file_modcsproj = "$script:path_vscode\RimWorld_Mod.csproj"

# Predefine Variable
$script:path_RimWorldInstallation = ""

# import functions from helperscript
. "$script:file_helperscriptPS1"

# Load the XML content of the .csproj file
[xml]$csproj = Get-Content $script:file_modcsproj

# Extract AssemblyName and VersionPrefix from the PropertyGroup
$script:targetName = $csproj.Project.PropertyGroup[0].AssemblyName
$script:version = $csproj.Project.PropertyGroup[0].VersionPrefix


# FUNCTIONS

# can be called by tasks.json from vscode
function Clean {
    RemoveItem $script:path_assemblyOutput
    RemoveItem $script:path_modOutput
    RemoveItem "$script:path_localDependencies\*"
    RemoveItem "$script:path_projectroot\.vscode\obj"
    RemoveItem "$script:path_projectroot\.vscode\debugFiles"
}

# can be called by tasks.json from vscode
function Compile {
    Write-Host -ForegroundColor Blue "`r`n#### Compiling ####"
    If (!(Test-Path $script:path_src\*)) {
        Write-Host " -> No files in $script:path_src `r`n -> Skipping compiling"
    }
    if (!(Test-Path $script:path_localDependencies\*)) {
        Write-Host -ForegroundColor Red " -> No local dependencies `r`n -> Run Task 'CopyDependencies'"
    }
    RemoveItem $script:path_assemblyOutput
    dotnet build $script:file_modcsproj --output "$script:path_assemblyOutput" --configuration "$VSConfiguration"
}

# can be called by tasks.json from vscode
function CopyDependencies {
    Write-Host -ForegroundColor Blue "`r`n#### Checking Dependencies ####"

    if ([string]::IsNullOrEmpty($script:path_RimWorldInstallation)) {
        $script:path_RimWorldInstallation = GetRimWorldInstallationPath -RimWorldPathTXT $script:file_RimWorldPathTXT
    }

    # import RimWorld dependencies
    $depsPath = "$script:path_RimWorldInstallation\RimWorldWin64_Data\Managed"
    Write-Host "Copying RimWorld dependencies from installation directory"
    if (!(Test-Path $script:path_localDependencies)) { mkdir $script:path_localDependencies | Out-Null }

    $files = Get-ChildItem -Path "$depsPath\Unity*.dll" -File
    $files += Get-ChildItem -Path "$depsPath\Assembly-CSharp.dll"
    $onlySkip = $true
    $skip = $false

    foreach ($file in $files) {
        $path_fileDest = Join-Path -Path $script:path_localDependencies -ChildPath $file.Name
        if (!(Test-Path -Path $path_fileDest)) {
            # Copy the file if it doesn't exist
            Copy-Item -Path $file.FullName -Destination $path_fileDest
            Write-Host " -> Copied: $($file.Name)"
            $onlySkip = $false
        }
        else {
            # Skip the file if it exists
            Write-Verbose " -> Skipped (already exists): $($file.Name)"
            $skip = $true
        }
    }
    If ($skip -and !($onlySkip)) {
        Write-Host " -> Some files skipped (already exist)"
    }
    elseif ($skip -and $onlySkip) {
        Write-Host " -> All files skipped (already exist)"
    }

    # import third party dependencies
    Write-Host "Import ThirdPartyDependencies"
    $depsPaths = Get-Content -Path $script:file_thirdPartyDependenciesTXT
    if ([string]::IsNullOrEmpty($depsPaths)) {
        Write-Host " -> No ThirdParty Dependencies"
        return
    }

    foreach ($depPath in $depsPaths) {
        # Write-Host " -  Resolve $depPath"
        $depPath = Invoke-Expression -Command $depPath
        # Write-Host " -  Checking $depPath"
        if (Test-Path $depPath) {
            $filename = Split-Path $depPath -Leaf
            if (!(Test-path "$script:path_localDependencies\$filename")) {
                Write-Host " -> Copying $depPath"
                Copy-Item -Force $depPath "$script:path_localDependencies\"
            }
            else {
                Write-Host " -> Skipped (already exists): $filename"
            }

        }
        else {
            Write-Host -ForegroundColor Yellow " -> File does not exist: $depPath"
        }
    }
}

# subcomponents from PostBuild
function CopyAssemblyFile {
    Write-Host "Copy new assembly to mod-structur"

    if (!(Test-Path "$script:path_assemblyOutput\*")) {
        Write-Host " -> No files in $script:path_assemblyOutput `r`n -> Skipping copying files"
        return
    }
    # default assembly - remove old files + copy new ones
    $defaultAssemblyPath = "$script:path_mod_structure\Assemblies"
    Write-Host " -> Copying to $defaultAssemblyPath"
    RemoveItem("$defaultAssemblyPath") -silent
    mkdir $defaultAssemblyPath | Out-Null
    Copy-Item "$script:path_assemblyOutput\*" $defaultAssemblyPath  

    # RimWorld version assembly - remove old files + copy new ones
    if ([string]::IsNullOrEmpty($script:path_RimWorldInstallation)) {
        $script:path_RimWorldInstallation = GetRimWorldInstallationPath -RimWorldPathTXT $script:file_RimWorldPathTXT
    }
    $RimWorldVersion = GetRimWorldVersion -RimWorldInstallationPath $script:path_RimWorldInstallation
    if (![string]::IsNullOrEmpty($RimWorldVersion)) {
        $shortVersionAssemblyPath = "$script:path_mod_structure\$RimWorldVersion\Assemblies"
        Write-Host " -> Coping to $shortVersionAssemblyPath"
        RemoveItem("$shortVersionAssemblyPath") -silent
        mkdir $shortVersionAssemblyPath | Out-Null
        Copy-Item "$script:path_assemblyOutput\*" $shortVersionAssemblyPath
    }
}

# subcomponents from PostBuild
function CopyFilesToRimworld {
    Write-Host "`r`nCopy files to RimWorld mod folder"
    if ([string]::IsNullOrEmpty($script:path_RimWorldInstallation)) {
        $script:path_RimWorldInstallation = GetRimWorldInstallationPath -RimWorldPathTXT $script:file_RimWorldPathTXT
    }

    $modsPath = "$script:path_RimWorldInstallation\Mods"
    $thisModPath = "$modsPath\$script:targetName"
    RemoveItem $thisModPath -silent

    Write-Host " -> $thismodPath"
    Copy-Item -Recurse -Force "$script:path_modOutput\$script:targetName" $modsPath
}

# subcomponents from PostBuild
function CreateModZipFile {
    Write-Host "`r`nCreating distro package" 

    if ($VSConfiguration -eq "Debug") {
        $distZip = "$script:path_modOutput\$script:targetName-$script:version-DEBUG.zip"
    }
    else {
        $distZip = "$script:path_modOutput\$script:targetName-$script:version.zip"
    }

    Compress-Archive -Path "$script:path_modOutput\$script:targetName" -DestinationPath "$distZip" -Force
    Write-Host " -> $distZip"
}

# subcomponents from PostBuild
function CreateModFolder {

    # Copy mod-structure to path_modOutput
    Write-Host "`r`nCreating mod folder"
    Write-Host " -> $script:path_modOutput\$script:targetName"

    RemoveItem("$script:path_modOutput") -silent
    mkdir "$script:path_modOutput\$script:targetName" | Out-Null
    Copy-Item -Recurse -Force "$script:path_mod_structure\*" "$script:path_modOutput\$script:targetName\"

    if ($VSConfiguration -eq "Debug") {
        $AboutFilePath = "$script:path_modOutput\$script:targetName\About\About.xml"

        # Get the current timestamp in the desired format
        $timestamp = Get-Date -Format "HH:mm - dd.MM.yyyy"

        # Read the file content
        [xml]$AboutFile = Get-Content -Path $AboutFilePath

        # Modify the <description> element by adding current timestamp at the beginning
        $AboutFile.ModMetaData.description = "Buildtime: $timestamp `r`n" + $AboutFile.ModMetaData.description

        # Save the modified XML back to the file
        $AboutFile.Save($AboutFilePath)

        Write-Host " -> About file updated with buildtime."
    }
}

# can be called by tasks.json from vscode
function PostBuild {
    Write-Host -ForegroundColor Blue "`r`n#### PostBuild ####"

    CopyAssemblyFile
    CreateModFolder
    CreateModZipFile
    CopyFilesToRimworld
}

# can be called by tasks.json from vscode
function StartRimWorld {
    if ([string]::IsNullOrEmpty($script:path_RimWorldInstallation)) {
        $script:path_RimWorldInstallation = GetRimWorldInstallationPath -RimWorldPathTXT $script:file_RimWorldPathTXT
    }
    Write-Host "Start RimWorld"
    Start-Process "$script:path_RimWorldInstallation\RimWorldWin64.exe" 
}

# can be called by tasks.json from vscode
function Build {
    CopyDependencies
    Compile
    PostBuild
    Write-Host -ForegroundColor Green "`r`nBUILD SUCCESSFUL`r`n"
}



& $Command


