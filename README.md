# Rimworld Mod Template

This template is created for Rimworld modders who use [Visual Studio Code](https://code.visualstudio.com/) instead of Visual Studio IDE.

- **Lightweight**. Visual Studio Code only takes up to 200 MB of storage space and is lighting fast.

- **Automated**. Integrated build, scripting and management tools to perform common tasks making everyday workflows faster.

- **Customizable**. Almost every feature can be changed, whenever it is editor UI, keybinds or folder structure.

## Setup

1. Download and install [.NET Core SDK](https://dotnet.microsoft.com/download/dotnet-core) and [.Net Framework 4.8 Developer Pack](https://dotnet.microsoft.com/download/dotnet-framework/net48). This step can be skipped if you already have required C# packages from Visual Studio IDE.
2. Install [C# extension](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csharp).
3. Clone, pull or download this template
4. Add Path to the RimWorld installation as a new line in the file `.vscode\RimWorldPath.txt`
   (not needed if RimWorld is installed in the Standard Steam Libary in C: Drive )

## First Steps

1. Change .vscode\mod.csproj [RootNamespace], [AssemblyName] and [VersionPrefix]
2. Change mod-structure\About\About.xml
3. Build Mod `F5` -> RimWorld starts automatic

## Additional notes

- Mod can be placed independed of the RimWorld installation
- The Build Mod is placed in the `output` folder, plus a `.zip` version of the mod
- When using `Build Mod DEV + Start RimWorld` in RUN AND DEBUG Tab `CTRL + SHIFT + D` a timestamp is added to the about.xml file
- RimWorld Dependencies (*.dll) are automatic imported, third party dependencies can be imported including the path in the file `.vscode\ThirdPartyDependencies.txt`
