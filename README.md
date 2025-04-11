# Rimworld Mod Template

This template is created for Rimworld modders who use [Visual Studio Code](https://code.visualstudio.com/) instead of Visual Studio IDE.

- **Lightweight**. Visual Studio Code only takes up to 200 MB of storage space and is lighting fast.

- **Automated**. Integrated build, PowerShell scripts to perform common tasks

- **Debug RimWorld**. Includes script to enable debugging RimWorld and your mod

## Setup

1. Download and install
   - [.NET Core SDK](https://dotnet.microsoft.com/download/dotnet-core)
   - [.Net Framework 4.8 Developer Pack](https://dotnet.microsoft.com/download/dotnet-framework/net48).
     Both steps can be skipped if you already have required C# packages from Visual Studio IDE.
2. Install VS Code Extensions
   - Compile C# code: [C# extension](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csharp).
   - Solution Explorer [C# Dev Kit](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csdevkit)
   - Auto completion [InIntelliCode for C# Dev Kit](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.vscodeintellicode-csharp)
   - Easy UI for running tasks: [Task Exploer](https://marketplace.visualstudio.com/items?itemName=spmeesseman.vscode-taskexplorer)
   - Assembly decompile [ilspy-vscode](https://marketplace.visualstudio.com/items?itemName=icsharpcode.ilspy-vscode)
3. Clone, pull or download this template
4. Add Path to the RimWorld installation as a new line in the file `.vscode\RimWorldPath.txt`
   (not needed if RimWorld is installed in the standard Steam Libary in C: drive )

## First Steps

1. Change .vscode\RimWorld_Mod.csproj [RootNamespace], [AssemblyName] and [VersionPrefix]
2. Change mod-structure\About\About.xml
3. Build Mod `CTRL + SHIFT + B` or run task `build` in [Task Exploer](https://marketplace.visualstudio.com/items?itemName=spmeesseman.vscode-taskexplorer)
4. Start RimWorld

## Additional notes

#### Folder structure

- `.vscode` - Folder for build scripts and mod settings
  - `RimWorld_Mod.csproj` - File for setting basic mod settings **mod name** and **mod version**
  - `ThirdPartyDependencies.ps1` - add path to third party .dll files if your mod need some (like Harmony). Surround path with quotes [ **"** ]
  - `RimWorld_Mod.sln` - Solution File -> no edit needed
  - `extension.json` - recomends extensions in vs code if there not installed
  - `task.json` - configure tasks which can be run in vs code
  - `*.ps1` - PowerShell scripts to automate tasks
- `localDependencies` - RimWorld Dependencies (\*.dll) are automatic imported, third party dependencies can be imported by including the path in the file ThirdPartyDependencies.txt
- `mod-structure` - Basic mod folder. Edit About, Defs, Textures, ...
- `output` - After the build process the mod is placed in this folder, plus a `.zip` version of the mod
- `src` - Folder for all code that should be compiled. (.cs files)

#### Tasks & Scripts

6 main tasks for automation

- `build` - standard task for building your mod
  include tasks: copyDependencies + compile + postbuild
- `build [dev]` - same as `build`, but with some extra features
  - generade .pdb files for debugging
  - compile code within the statements `#if DEBUG` and `#endif`
  - add a build time stamp in the about.xml file
- `clean` - removes temp files that are created by the build process
- `start RimWorld` - task that starts RimWorld directly from VS Code
- `start dnSPY` - launches dnSPY with the current dll file

Tasks beginning with `_` are part of the build task but can be run separately if needed.

#### Decompile Assembly

With [ilspy-vscode](https://marketplace.visualstudio.com/items?itemName=icsharpcode.ilspy-vscode) its possible to decombile the Assemblies directly in VS Code.

- Right click on `Assembly.CSharp.dll` in `localDependencies` and select `Decompile selected assembly`
- Now you can see the the ilspy window the decompiled assembly with includes the important RimWorld functions.
- Now it is possible, to click while holding `CTRL` on imported RimWorld function to see them decompiled.
  Example: `CTRL` + `CLICK` on `Log` in `Main.cs` -> `Log.cs` from `Assembly.CSharp.dll` opens

#### Debug

Using [RimWorld Doorstop](https://github.com/pardeike/Rimworld-Doorstop) to enable Debugging

1. just run the task `install RimWorld debug`
2. download and run [dnySpy](https://github.com/dnSpyEx/dnSpy)
3. open Assembly-CSharp.dll (usually in`"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\RimWorldWin64_Data\Managed\Assembly-CSharp.dll"`)
4. open your mod assembly.dll in (ussually in `"C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods\YOURMOD\VERSION\Assemblies\YOURMOD.dll"`)
5. open Debug Menu in dnySpy `F5` and select Unity (Connect)
6. Add the IP Adress `127.0.0.1` and the Port `55555` and start debugger.

The Debugger is running in the background. With `F9` you can set breakpoints.

> When you set a breakpoint in the file `Assembly.CSharp.dll` -> `RimWorld` -> `Pawn_DraftController`
> -> `public bool Drafted` -> `set` -> `if(value == this.draftedInt)` Line: 24
> The game stops at your brakepoint when you draft a pawn in the game.

Run the task `remove RimWorld debug` to remove the files in your RimWorld installation
