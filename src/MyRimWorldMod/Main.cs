using Verse;

// *Uncomment for Harmony*
// using HarmonyLib;

namespace MyRimWorldMod
{
    public class Mod : Verse.Mod
    {
        /// <summary>
        /// A mandatory constructor which resolves the reference to our settings.
        /// </summary>
        /// <param name="content"></param>
        public Mod(ModContentPack content) : base(content)
        {
            Log.Message("Mod MyRimWorldMod Loaded!");
            Log.Warning("Warning Message!");

#if DEBUG
            Log.Message("Debug Message!");
            
#endif

        }
    }
}














