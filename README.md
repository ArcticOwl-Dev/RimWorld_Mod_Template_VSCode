# RimWorld Mod Template

This template is created for RimWorld modders who use [Visual Studio Code](https://code.visualstudio.com/) instead of Visual Studio IDE.

- **Lightweight**. Visual Studio Code only takes up to 200 MB of storage space and is lightning fast.

- **Automated**. Integrated build, PowerShell scripts to perform common tasks

- **Debug RimWorld**. Includes script to enable debugging RimWorld and your mod

## Setup

1. Download and install

   - [Visual Studio Code](https://code.visualstudio.com/)
   - [.NET Core SDK](https://dotnet.microsoft.com/download/dotnet-core) 8.0 or 9.0 (only needed for dotnet buildtool)
   - [.Net Framework 4.7.2 Developer Pack](https://dotnet.microsoft.com/download/dotnet-framework/net472). RimWorld framework

2. Clone, pull, or download this template

3. Install VS Code Extensions

   - [C# extension](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csharp) - Basic C# support

   optional extensions

   - [Task Explorer](https://marketplace.visualstudio.com/items?itemName=spmeesseman.vscode-taskexplorer) - Easy UI for running tasks:
   - [ilspy-vscode](https://marketplace.visualstudio.com/items?itemName=icsharpcode.ilspy-vscode) - Decompile RimWorld .dlls
   - [C# Dev Kit](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csdevkit) - Solution Explorer
   - [IntelliCode for C# Dev Kit](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.vscodeintellicode-csharp) - Auto completion

## First Steps

Errors and missing dependencies are solved on first build

1. Change .vscode\RimWorld_Mod.csproj [RootNamespace], [AssemblyName] and [VersionPrefix]
2. Change mod-structure\About\About.xml
3. Build Mod `CTRL + SHIFT + B` or run task `build` in [Task Explorer](https://marketplace.visualstudio.com/items?itemName=spmeesseman.vscode-taskexplorer)
4. Start RimWorld

#### Troubleshooting

- **ThirdPartyDependencies**: Ensure paths to third-party DLLs in `ThirdPartyDependencies.ps1` are correctly specified and enclosed in quotes.
- **Environment variables**: Verify that the environment variable for RimWorld, `RimWorldInstallationPath`, is correctly configured. If the path is not set, the script will prompt you to set one. If the game is installed in the standard Steam folder on C:, the environment variable is set automatically.

## Additional notes

### Folder structure

- `.vscode` - Folder for build scripts and mod settings
  - `RimWorld_Mod.csproj` - File for setting basic mod settings: **mod name** and **mod version**
  - `ThirdPartyDependencies.ps1` - add path to third party .dll files if your mod needs some (like Harmony). Surround path with quotes [ **"** ]
  - `RimWorld_Mod.sln` - Solution File -> no edit needed
  - `extension.json` - recommends extensions in VS Code if they're not installed
  - `task.json` - configure tasks which can be run in VS Code
  - `*.ps1` - PowerShell scripts to automate tasks
- `localDependencies` - RimWorld Dependencies (\*.dll) are automatically imported, third-party dependencies can be imported by including the path in the file ThirdPartyDependencies.ps1
- `mod-structure` - Basic mod folder. Edit About, Defs, Textures, ...
- `output` - After the build process, the mod is placed in this folder, plus a `.zip` version of the mod
- `src` - Folder for all code that should be compiled. (.cs files)

### Tasks & Scripts

main tasks for automation

- `build` - standard task for building your mod
  includes tasks: copyDependencies + compile + postbuild
- `build [dev]` - same as `build`, but with some extra features
  - generate .pdb files for debugging
  - compile code within the statements `#if DEBUG` and `#endif`
  - add a build timestamp in the about.xml file
- `clean` - removes temp files that are created by the build process
- `start dnSPY` - launches dnSPY with the current dll file
- `start RimWorld` - task that starts RimWorld directly from VS Code
- `start RimWorld -quicktest` - starts RimWorld and loads dev quicktest map

Tasks beginning with `_` are part of the build task but can be run separately if needed.

### Decompile Assembly

With [ilspy-vscode](https://marketplace.visualstudio.com/items?itemName=icsharpcode.ilspy-vscode) extension it's possible to decompile the Assemblies directly in VS Code.  
Right-click on `Assembly-CSharp.dll` in `localDependencies` and select `Decompile selected assembly`  
Now you can see the ilspy window with the decompiled assembly which includes the important RimWorld functions.

Or click while holding `CTRL` on imported RimWorld function to see them decompiled.  
Example: `CTRL` + `CLICK` on `Log` in `Main.cs` -> `Log.cs` from `Assembly-CSharp.dll` opens

### Debug

Using [RimWorld Doorstop](https://github.com/pardeike/Rimworld-Doorstop) to enable Debugging

1. just run the task `install RimWorld debug`
2. download and run [dnSpy](https://github.com/dnSpyEx/dnSpy)
3. open Assembly-CSharp.dll (usually in `"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\RimWorldWin64_Data\Managed\Assembly-CSharp.dll"`)
4. open your mod assembly.dll in (usually in `"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\YOURMOD\VERSION\Assemblies\YOURMOD.dll"`)
5. open Debug Menu in dnSpy `F5` and select Unity (Connect)
6. Add the IP Address `127.0.0.1` and the Port `55555` and start debugger. (IP can be skipped)

The Debugger is running in the background. With `F9` you can set breakpoints.

> When you set a breakpoint in the file `Assembly-CSharp.dll` -> `RimWorld` -> `Pawn_DraftController`
> -> `public bool Drafted` -> `set` -> `if(value == this.draftedInt)` Line: 24
> The game stops at your breakpoint when you draft a pawn in the game.

Run the task `remove RimWorld debug` to remove the files in your RimWorld installation
