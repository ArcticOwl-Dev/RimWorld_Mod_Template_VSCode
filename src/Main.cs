using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;

using UnityEngine;
using Verse;
using Verse.AI;
using Verse.AI.Group;
using Verse.Sound;
using Verse.Noise;
using Verse.Grammar;
using RimWorld;
using RimWorld.Planet;

// *Uncomment for Harmony*
// using System.Reflection;
// using HarmonyLib;

namespace Template
{
    public class Mod : Verse.Mod
    {
        /// <summary>
        /// A mandatory constructor which resolves the reference to our settings.
        /// </summary>
        /// <param name="content"></param>
        public Mod(ModContentPack content) : base(content)
        {
            Log.Message("Mod Loaded!");
            Log.Warning("!");

#if DEBUG
            Log.Message("Debug Message!");
            
#endif

        }
    }
}