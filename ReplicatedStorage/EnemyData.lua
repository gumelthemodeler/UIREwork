-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local EnemyData = {}

local emptyTitans = {Power="None", Speed="None", Hardening="None", Endurance="None", Precision="None", Potential="None"}

EnemyData.BossIcons = {
	["Raid_Part1"] = "rbxassetid://118182722089835", 
	["Raid_Part2"] = "rbxassetid://127437496013300",  
	["Raid_Part3"] = "rbxassetid://95511063358417",  
	["Raid_Part4"] = "rbxassetid://92481334765869", 
	["Raid_Part5"] = "rbxassetid://77055155553118", 
	["Raid_Part8"] = "rbxassetid://82958903182689", 
	["Rod Reiss Titan"] = "rbxassetid://119392967268687",
	["Lara Tybur"] = "rbxassetid://92481334765869",
	["Doomsday Titan"] = "rbxassetid://77055155553118",
	["Ymir Fritz"] = "rbxassetid://129655150803684",
	["Frenzied Beast"] = "rbxassetid://126246803477895",
	["Abyssal Armored"] = "rbxassetid://75593809803541",
	["Doomsday Apparition"] = "rbxassetid://114493300912789",
}

EnemyData.Allies = {
	["Armin Arlert"] = { Name = "Armin Arlert", Health = 80, Strength = 12, Defense = 5, Speed = 8, Resolve = 25, TitanStats = emptyTitans, Skills = {"Spinning Slash", "Recover", "Basic Slash"} },
	["Mikasa Ackerman"] = { Name = "Mikasa Ackerman", Health = 150, Strength = 40, Defense = 10, Speed = 35, Resolve = 15, TitanStats = emptyTitans, Skills = {"Nape Strike", "Spinning Slash", "Basic Slash"} },
	["Levi Ackerman"] = { Name = "Levi Ackerman", Health = 250, Strength = 65, Defense = 15, Speed = 55, Resolve = 30, TitanStats = emptyTitans, Skills = {"Nape Strike", "Maneuver", "Spinning Slash"} },
	["Hange Zoe"] = { Name = "Hange Zoe", Health = 200, Strength = 30, Defense = 20, Speed = 25, Resolve = 25, TitanStats = emptyTitans, Skills = {"Spear Volley", "Maneuver", "Basic Slash"} },
	["Erwin Smith"] = { Name = "Erwin Smith", Health = 400, Strength = 35, Defense = 30, Speed = 20, Resolve = 100, Skills = {"Basic Slash", "Recover"} }
}

EnemyData.RaidBosses = {
	["Raid_Part1"] = { IsBoss = true, Name = "Female Titan", Req = 1, Health = 3000, GateType = "Hardening", GateHP = 1000, Strength = 120, Defense = 50, Speed = 65, Resolve = 60, TitanStats = {Power="A", Speed="A", Hardening="A", Endurance="B", Precision="B", Potential="B"}, Skills = {"Hardened Punch", "Nape Guard", "Leg Sweep"}, Drops = { Dews = 800, XP = 2500, ItemChance = { ["Standard Titan Serum"] = 100, ["Founder's Memory Wipe"] = 5, ["Scout Regiment Cloak"] = 25, ["Scout Training Manual"] = 15, ["Iron Bamboo Heart"] = 5 } } },
	["Raid_Part2"] = { IsBoss = true, Name = "Armored Titan", Req = 1, Health = 4500, GateType = "Reinforced Skin", GateHP = 2500, Strength = 180, Defense = 100, Speed = 30, Resolve = 70, TitanStats = {Power="B", Speed="C", Hardening="S", Endurance="A", Precision="C", Potential="C"}, Skills = {"Armored Tackle", "Hardened Punch", "Brutal Swipe"}, Drops = { Dews = 1500, XP = 5000, ItemChance = { ["Standard Titan Serum"] = 100, ["Founder's Memory Wipe"] = 6, ["Advanced ODM Gear"] = 15, ["Ultrahard Steel Blades"] = 25, ["Iron Bamboo Heart"] = 10 } } },
	["Raid_Part3"] = { IsBoss = true, Name = "Beast Titan", Req = 1, Health = 6000, Strength = 250, Defense = 60, Speed = 40, Resolve = 85, TitanStats = {Power="S", Speed="C", Hardening="B", Endurance="A", Precision="A", Potential="A"}, Skills = {"Titan Roar", "Hardened Punch", "Brutal Swipe"}, Drops = { Dews = 2500, XP = 10000, ItemChance = { ["Standard Titan Serum"] = 100, ["Founder's Memory Wipe"] = 7, ["Spinal Fluid Syringe"] = 5, ["Marleyan Armband"] = 25, ["Iron Bamboo Heart"] = 15, ["Glowing Titan Crystal"] = 2 } } },
	["Raid_Part4"] = { IsBoss = true, Name = "War Hammer Titan", Req = 1, Health = 8000, GateType = "Hardening", GateHP = 3000, Strength = 350, Defense = 80, Speed = 60, Resolve = 100, TitanStats = {Power="A", Speed="B", Hardening="S", Endurance="B", Precision="A", Potential="A"}, Skills = {"War Hammer Spike", "Hardened Punch"}, Drops = { Dews = 4000, XP = 15000, ItemChance = { ["Standard Titan Serum"] = 100, ["Founder's Memory Wipe"] = 8, ["Spinal Fluid Syringe"] = 10, ["Marleyan Combat Manual"] = 25, ["Iron Bamboo Heart"] = 20, ["Glowing Titan Crystal"] = 5 } } },
	["Raid_Part5"] = { IsBoss = true, Name = "Founding Titan (Eren)", Req = 1, Health = 10000, GateType = "Steam", GateHP = 5, Strength = 500, Defense = 150, Speed = 20, Resolve = 250, TitanStats = {Power="S", Speed="E", Hardening="S", Endurance="S", Precision="A", Potential="S"}, Skills = {"Coordinate Command", "Colossal Steam", "Stomp"}, Drops = { Dews = 10000, XP = 50000, ItemChance = { ["Standard Titan Serum"] = 10, ["Founder's Memory Wipe"] = 15, ["Spinal Fluid Syringe"] = 25, ["Ymir's Clay Fragment"] = 5, ["Glowing Titan Crystal"] = 15, ["Coordinate Shard"] = 1 } } },
	["Raid_Part8"] = { IsBoss = true, Name = "Colossal Titan", Req = 1, Health = 12000, GateType = "Steam", GateHP = 5, Strength = 600, Defense = 100, Speed = 10, Resolve = 150, TitanStats = {Power="S", Speed="E", Hardening="C", Endurance="S", Precision="E", Potential="S"}, Skills = {"Colossal Steam", "Stomp"}, Drops = { Dews = 8000, XP = 25000, ItemChance = { ["Standard Titan Serum"] = 100, ["Spinal Fluid Syringe"] = 10, ["Ymir's Clay Fragment"] = 2, ["Glowing Titan Crystal"] = 10 } } }
}

EnemyData.WorldBosses = {
	["Rod Reiss Titan"] = {
		Name = "Rod Reiss (Abnormal)", Desc = "A massive, crawling monstrosity radiating intense heat. Slow, but devastatingly durable.", IsBoss = true, 
		Health = 8000, GateHP = 0, Strength = 300, Defense = 400, Speed = 10, Resolve = 500, TitanStats = {Power="S", Speed="E", Hardening="C", Endurance="S", Precision="E", Potential="E"},
		Skills = {"Colossal Steam", "Stomp"},
		Drops = { XP = 100000, Dews = 15000, ItemChance = { ["Standard Titan Serum"] = 100, ["Clan Blood Vial"] = 50, ["Spinal Fluid Syringe"] = 20, ["Iron Bamboo Heart"] = 50, ["Glowing Titan Crystal"] = 20 } },
		Phases = { { Health = 4000, GateType = "None", GateHP = 0, Strength = 400, Defense = 150, Speed = 5, Skills = {"Colossal Steam", "Crushed Boulders"}, Flavor = "<font color='#FFAA00'><b>Rod Reiss's face has dragged completely off! The heat is intensifying!</b></font>" } }
	},
	["Lara Tybur"] = {
		Name = "War Hammer (Lara)", Desc = "The true wielder of the War Hammer. Master of structural hardening and lethal spikes.", IsBoss = true,
		Health = 9000, GateType = "Hardening", GateHP = 3000, Strength = 400, Defense = 600, Speed = 120, Resolve = 800, TitanStats = {Power="S", Speed="A", Hardening="S", Endurance="B", Precision="S", Potential="A"},
		Skills = {"War Hammer Spike", "Hardened Punch", "Brutal Swipe"},
		Drops = { XP = 250000, Dews = 30000, ItemChance = { ["Standard Titan Serum"] = 100, ["Clan Blood Vial"] = 75, ["Spinal Fluid Syringe"] = 40, ["Ymir's Clay Fragment"] = 10, ["Glowing Titan Crystal"] = 35, ["Coordinate Shard"] = 2 } },
		Phases = { { Health = 5000, GateType = "Hardening", GateHP = 1500, Strength = 600, Defense = 800, Speed = 0, Skills = {"War Hammer Spike", "Crushed Boulders"}, Flavor = "<font color='#55FFFF'><b>Lara Tybur encases herself in a crystal underground and manifests a new Titan body remotely!</b></font>" } }
	},
	["Doomsday Titan"] = {
		Name = "The Doomsday Titan", Desc = "Eren's skeletal monstrosity leading the Rumbling. Commands pure titans at will.", IsBoss = true,
		Health = 12000, GateType = "Steam", GateHP = 10, Strength = 800, Defense = 1000, Speed = 50, Resolve = 1000, TitanStats = {Power="S", Speed="E", Hardening="S", Endurance="S", Precision="S", Potential="S"},
		Skills = {"Coordinate Command", "Colossal Steam", "Stomp"},
		Drops = { XP = 600000, Dews = 60000, ItemChance = { ["Spinal Fluid Syringe"] = 100, ["Clan Blood Vial"] = 100, ["Ymir's Clay Fragment"] = 25, ["Glowing Titan Crystal"] = 50, ["Coordinate Shard"] = 5 } }
	},
	["Ymir Fritz"] = {
		Name = "Ymir Fritz (Founder)", Desc = "The original progenitor. She molds the world in the Paths. The ultimate trial.", IsBoss = true,
		Health = 15000, GateType = "Hardening", GateHP = 5000, Strength = 1000, Defense = 1500, Speed = 200, Resolve = 5000, TitanStats = {Power="S", Speed="S", Hardening="S", Endurance="S", Precision="S", Potential="S"},
		Skills = {"Coordinate Command", "War Hammer Spike", "Colossal Steam", "Armored Tackle"},
		Drops = { XP = 1500000, Dews = 100000, ItemChance = { ["Spinal Fluid Syringe"] = 100, ["Clan Blood Vial"] = 100, ["Ymir's Clay Fragment"] = 100, ["Coordinate Shard"] = 15, ["Abyssal Blood"] = 2 } }
	}
}

EnemyData.NightmareHunts = {
	["Frenzied Beast"] = { IsBoss = true, IsNightmare = true, Name = "Frenzied Beast Titan", Req = 5, Health = 10000, Strength = 250, Defense = 150, Speed = 140, Resolve = 200, TitanStats = {Power="S", Speed="B", Hardening="C", Endurance="S", Precision="S", Potential="S"}, Skills = {"Crushed Boulders", "Titan Roar", "Brutal Swipe"}, Drops = { Dews = 35000, XP = 50000, ItemChance = { ["Abyssal Blood"] = 5, ["Glowing Titan Crystal"] = 25, ["Spinal Fluid Syringe"] = 5 } } },
	["Abyssal Armored"] = { IsBoss = true, IsNightmare = true, Name = "Abyssal Armored Titan", Req = 8, Health = 15000, GateType = "Reinforced Skin", GateHP = 8000, Strength = 280, Defense = 400, Speed = 80, Resolve = 250, TitanStats = {Power="S", Speed="C", Hardening="S", Endurance="S", Precision="C", Potential="S"}, Skills = {"Armored Tackle", "Hardened Punch", "Colossal Steam"}, Drops = { Dews = 75000, XP = 100000, ItemChance = { ["Abyssal Blood"] = 10, ["Coordinate Shard"] = 1, ["Spinal Fluid Syringe"] = 10 } } },
	["Doomsday Apparition"] = { IsBoss = true, IsNightmare = true, Name = "Doomsday Apparition", Req = 10, Health = 20000, GateType = "Steam", GateHP = 10, Strength = 500, Defense = 350, Speed = 200, Resolve = 450, TitanStats = {Power="S", Speed="S", Hardening="S", Endurance="S", Precision="S", Potential="S"}, Skills = {"Coordinate Command", "War Hammer Spike", "Colossal Steam"}, Drops = { Dews = 120000, XP = 300000, ItemChance = { ["Abyssal Blood"] = 25, ["Coordinate Shard"] = 5, ["Ymir's Clay Fragment"] = 2 } } }
}

EnemyData.PathsMemories = {
	{ Name = "Memory of the Smiling Titan", Health = 500, Strength = 120, Defense = 40, Speed = 45, Resolve = 100, TitanStats = emptyTitans, Skills = {"Titan Grab", "Brutal Swipe"}, Drops = {XP=1000, Dews=500} },
	{ Name = "Memory of the Female Titan", Health = 800, GateType="Hardening", GateHP=300, Strength = 200, Defense = 80, Speed = 100, Resolve = 150, TitanStats = emptyTitans, Skills = {"Brutal Swipe", "Block"}, Drops = {XP=3000, Dews=1000} },
	{ Name = "Memory of the Armored Titan", Health = 1200, GateType="Reinforced Skin", GateHP=800, Strength = 250, Defense = 150, Speed = 50, Resolve = 200, TitanStats = emptyTitans, Skills = {"Armored Tackle", "Brutal Swipe"}, Drops = {XP=4000, Dews=1500} },
	{ Name = "Memory of the Beast Titan", Health = 1600, Strength = 300, Defense = 60, Speed = 70, Resolve = 180, TitanStats = emptyTitans, IsLongRange = true, Skills = {"Crushed Boulders", "Block"}, Drops = {XP=5000, Dews=2000} },
	{ Name = "Memory of the War Hammer", Health = 2000, GateType="Hardening", GateHP=1000, Strength = 350, Defense = 120, Speed = 90, Resolve = 250, TitanStats = emptyTitans, Skills = {"Brutal Swipe", "War Hammer Spike"}, Drops = {XP=6000, Dews=3000, ItemChance = { ["Iron Bamboo Heart"] = 5 } } },
	{ Name = "Memory of the Colossal", Health = 2500, GateType="Steam", GateHP=6, Strength = 450, Defense = 80, Speed = 10, Resolve = 300, TitanStats = emptyTitans, Skills = {"Colossal Steam", "Stomp"}, Drops = {XP=8000, Dews=5000, ItemChance = { ["Glowing Titan Crystal"] = 2 } } }
}


-- ==========================================
-- FULL TEXT-RPG CAMPAIGN REWORK
-- ==========================================
EnemyData.Parts = {
	[1] = {
		RandomFlavor = {"You wander the streets of Trost, and encounter a %s!"},
		Mobs = { { Name = "3-Meter Pure Titan",  Health = 40, Strength = 5, Defense = 2, Speed = 3, Resolve = 2, TitanStats = emptyTitans, Skills = {"Brutal Swipe", "Titan Grab"}, Drops = { Dews = 15, XP = 10 } } },
		Templates = {
			["Story_Part1_Intro"] = { IsDialogue = true, Speaker = "Hannes", Text = "Run! The Armored Titan has broken through Wall Maria! Get to the boats, I'll hold them off!" },
			["Evade_Debris"] = { IsMinigame = "GapClose", Name = "Falling Debris", Health = 1, GateHP = 0, Strength = 0, Defense = 0, Speed = 0, Resolve = 0, TitanStats = emptyTitans, Skills = {}, Drops = { Dews = 50, XP = 50 } },
			["Story_Part1_Mid"] = { IsDialogue = true, Speaker = "Armin Arlert", Text = "We made it past the debris, but there are titans everywhere! We have to fight our way to the evacuation ships!" },
			["3-Meter Pure Titan"] = { Name = "3-Meter Pure Titan", Health = 40, Strength = 5, Defense = 2, Speed = 3, Resolve = 2, TitanStats = emptyTitans, Skills = {"Brutal Swipe", "Titan Grab"}, Drops = { Dews = 15, XP = 10, ItemChance = {["Cadet Training Blade"]=1} } },
			["Story_Part1_PreBoss"] = { IsDialogue = true, Speaker = "Eren Yeager", Text = "I'll wipe them out... Every last one of them! Watch out, an Abnormal is charging the docks!" },
			["Part1Boss"] = { IsBoss = true, Name = "Vanguard Abnormal (Boss)", Health = 400, Strength = 35, Defense = 15, Speed = 20, Resolve = 30, TitanStats = emptyTitans, Skills = {"Frenzied Thrash", "Stomp", "Titan Grab"}, Drops = { Dews = 300, XP = 400, ItemChance={["Cadet Training Blade"]=25, ["Scout Training Manual"]=5} } },
			["Story_Part1_Outro"] = { IsDialogue = true, Speaker = "System", Text = "You survived the fall of Shiganshina. Five years pass. You enroll in the 104th Cadet Corps." }
		},
		Missions = { 
			[1] = { Name = "The Fall of Shiganshina", Waves = { { Template = "Story_Part1_Intro" }, { Template = "Evade_Debris" }, { Template = "Story_Part1_Mid" }, { Template = "3-Meter Pure Titan" }, { Template = "Story_Part1_PreBoss" }, { Template = "Part1Boss" }, { Template = "Story_Part1_Outro" } } }
		}
	},

	[2] = {
		RandomFlavor = {"You face a Wooden Titan Dummy on the training grounds!"},
		Mobs = { { Name = "Wooden Titan Dummy", Health = 60, Strength = 2, Defense = 5, Speed = 2, Resolve = 5, TitanStats = emptyTitans, Skills = {"Brutal Swipe"}, Drops = { Dews = 25, XP = 20 } } },
		Templates = {
			["Story_Part2_Intro"] = { IsDialogue = true, Speaker = "Keith Shadis", Text = "Who the hell are you?! You look like nothing but titan fodder! Take this blade and prove to me you aren't completely useless on the ODM gear!", Rewards = { ItemName = "Cadet Training Blade", Amount = 1 } },
			["Balance Minigame"] = { IsMinigame = "Balance", Name = "ODM Balance Training", Health = 1, GateHP = 0, Strength = 0, Defense = 0, Speed = 0, Resolve = 0, TitanStats = emptyTitans, Skills = {}, Drops = { Dews = 150, XP = 300 } },
			["Wooden Titan Dummy"] = { Name = "Wooden Titan Dummy", Health = 60, Strength = 2, Defense = 5, Speed = 2, Resolve = 5, TitanStats = emptyTitans, Skills = {"Brutal Swipe"}, Drops = { Dews = 25, XP = 20, ItemChance = {["Cadet Training Blade"]=5} } },
			["Story_Part2_Mid"] = { IsDialogue = true, Speaker = "Keith Shadis", Text = "Not terrible... Now let's see how you handle armored targets! Don't dull your blades!" },
			["Armored Titan Dummy"] = { Name = "Armored Titan Dummy", Health = 100, GateType = "Reinforced Skin", GateHP = 50, Strength = 5, Defense = 10, Speed = 3, Resolve = 10, TitanStats = emptyTitans, Skills = {"Block"}, Drops = { Dews = 40, XP = 30 } },
			["Story_Part2_PreBoss"] = { IsDialogue = true, Speaker = "Keith Shadis", Text = "Enough playing around! I'll test your mettle personally! Come at me with intent to kill!" },
			["Part2Boss"] = { IsBoss = true, IsHuman = true, Name = "Instructor Shadis", Health = 500, Strength = 35, Defense = 15, Speed = 30, Resolve = 50, TitanStats = emptyTitans, Skills = {"Heavy Slash", "Evasive Maneuver"}, Drops = { Dews = 400, XP = 500, ItemChance = { ["Scout Training Manual"] = 10 } } },
			["Story_Part2_Outro"] = { IsDialogue = true, Speaker = "Erwin Smith", Text = "You survived training. The Scout Regiment could use someone with your resolve. Here is your graduation allowance.", Rewards = { Dews = 1000, XP = 1000 } }
		},
		Missions = { 
			[1] = { Name = "104th Cadet Corps Training", Waves = { { Template = "Story_Part2_Intro" }, { Template = "Balance Minigame" }, { Template = "Wooden Titan Dummy" }, { Template = "Story_Part2_Mid" }, { Template = "Armored Titan Dummy" }, { Template = "Story_Part2_PreBoss" }, { Template = "Part2Boss" }, { Template = "Story_Part2_Outro" } } }
		}
	},

	[3] = {
		RandomFlavor = {"You encounter a Field Titan!"},
		Mobs = { { Name = "Field Titan", Health = 100, Strength = 12, Defense = 8, Speed = 15, Resolve = 8, TitanStats = emptyTitans, Skills = {"Titan Grab", "Brutal Swipe"}, Drops = { Dews = 50, XP = 40 } } },
		Templates = {
			["Story_Part3_Intro"] = { IsDialogue = true, Speaker = "Levi Ackerman", Text = "Listen up. We are pushing out past Wall Rose. Stay in formation. Do exactly as I say and you might live to see tomorrow." },
			["Field Titan"] = { Name = "Field Titan", Health = 100, Strength = 12, Defense = 8, Speed = 15, Resolve = 8, TitanStats = emptyTitans, Skills = {"Titan Grab", "Brutal Swipe"}, Drops = { Dews = 50, XP = 40 } },
			["Story_Part3_Mid"] = { IsDialogue = true, Speaker = "Armin Arlert", Text = "Wait... the entire right flank was wiped out! The black smoke signals... Something intelligent is coming, and it's fast!" },
			["Tree Glider Abnormal"] = { Name = "Tree Glider Abnormal", Health = 150, Strength = 16, Defense = 10, Speed = 25, Resolve = 12, TitanStats = emptyTitans, Skills = {"Stomp", "Frenzied Thrash"}, Drops = { Dews = 80, XP = 60 } },
			["Story_Part3_PreBoss"] = { IsDialogue = true, Speaker = "Erwin Smith", Text = "FIRE THE TRAP! ...It failed. The Female Titan is crystalizing her nape! Brace yourselves, she's breaking free!" },
			["Part3Boss"] = { IsBoss = true, Name = "Female Titan (Annie)", Health = 1200, GateType = "Hardening", GateHP = 800, Strength = 50, Defense = 30, Speed = 60, Resolve = 35, TitanStats = {Power="A", Speed="A", Hardening="A", Endurance="B", Precision="B", Potential="B"}, Skills = {"Hardened Punch", "Block"}, Drops = { Dews = 1000, XP = 2000, ItemChance = { ["Ultrahard Steel Blades"] = 20, ["Standard Titan Serum"]=10 } }, Phases = { { Health = 800, GateType = "None", GateHP = 0, Strength = 70, Defense = 20, Speed = 90, Skills = {"Frenzied Thrash", "Brutal Swipe", "Evasive Maneuver"}, Flavor = "<font color='#FF5555'><b>Annie abandons her hardening to prioritize sheer speed! She's getting desperate!</b></font>" } } },
			["Story_Part3_Outro"] = { IsDialogue = true, Speaker = "Hange Zoe", Text = "Incredible work bringing her down! She encased herself in a crystal, but we can study it. Take this cloak, you've earned it.", Rewards = { ItemName = "Scout Regiment Cloak", Amount = 1 } }
		},
		Missions = { 
			[1] = { Name = "Clash of the Titans", Waves = { { Template = "Story_Part3_Intro" }, { Template = "Field Titan" }, { Template = "Story_Part3_Mid" }, { Template = "Tree Glider Abnormal" }, { Template = "Story_Part3_PreBoss" }, { Template = "Part3Boss" }, { Template = "Story_Part3_Outro" } } }
		}
	},

	[4] = {
		RandomFlavor = {"An Interior MP attacks you!"},
		Mobs = { { IsHuman = true, Name = "Anti-Personnel MP", Health = 120, Strength = 25, Defense = 15, Speed = 30, Resolve = 18, TitanStats = emptyTitans, Skills = {"Anti-Titan Round"}, Drops = { Dews = 150, XP = 150 } } },
		Templates = {
			["Story_Part4_Intro"] = { IsDialogue = true, Speaker = "Levi Ackerman", Text = "The government is corrupt. Kenny the Ripper is hunting us down with Anti-Personnel ODM gear. They have guns. Do not hesitate." },
			["Evade_Gunfire"] = { IsMinigame = "GapClose", Name = "Gunfire Barrage", Health = 1, GateHP = 0, Strength = 0, Defense = 0, Speed = 0, Resolve = 0, TitanStats = emptyTitans, Skills = {}, Drops = { Dews = 100, XP = 100 } },
			["Interior MP"] = { IsHuman = true, Name = "Interior MP Grunt", Health = 140, Strength = 28, Defense = 16, Speed = 25, Resolve = 20, TitanStats = emptyTitans, Skills = {"Heavy Slash", "Regroup"}, Drops = { Dews = 120, XP = 180 } },
			["Story_Part4_Mid"] = { IsDialogue = true, Speaker = "Hange Zoe", Text = "We've entered the Reiss family's Crystal Caverns. The structure is fragile. Watch your ODM anchors, and watch your back." },
			["Anti-Personnel MP"] = { IsHuman = true, Name = "Anti-Personnel MP", Health = 120, Strength = 25, Defense = 15, Speed = 30, Resolve = 18, TitanStats = emptyTitans, Skills = {"Anti-Titan Round", "Evasive Maneuver"}, Drops = { Dews = 150, XP = 150 } },
			["Story_Part4_PreBoss"] = { IsDialogue = true, Speaker = "Kenny Ackerman", Text = "Yo, Levi! You really brought a bunch of brats down here? Lieutenant! Shred 'em to pieces!" },
			["Part4Boss"] = { IsHuman = true, IsBoss = true, Name = "Kenny's Lieutenant", Health = 600, Strength = 60, Defense = 35, Speed = 50, Resolve = 45, TitanStats = emptyTitans, Skills = {"Anti-Titan Round", "Smoke Screen"}, Drops = { Dews = 1500, XP = 2500, ItemChance = { ["Anti-Personnel Pistols"] = 25 } }, Phases = { { Health = 300, GateType = "None", GateHP = 0, Strength = 80, Defense = 20, Speed = 80, Skills = {"Heavy Slash", "Evasive Maneuver"}, Flavor = "<font color='#FFAA00'><b>The Lieutenant runs out of ammo and draws her blades!</b></font>" } } },
			["Story_Part4_Outro"] = { IsDialogue = true, Speaker = "Levi Ackerman", Text = "It's over. Kenny is dead. I recovered this from his body... A Titan Serum. I'm entrusting it to the Commander.", Rewards = { ItemName = "Standard Titan Serum", Amount = 1 } }
		},
		Missions = { 
			[1] = { Name = "The Uprising", Waves = { { Template = "Story_Part4_Intro" }, { Template = "Evade_Gunfire" }, { Template = "Interior MP" }, { Template = "Story_Part4_Mid" }, { Template = "Anti-Personnel MP" }, { Template = "Story_Part4_PreBoss" }, { Template = "Part4Boss" }, { Template = "Story_Part4_Outro" } } }
		}
	},

	[5] = {
		RandomFlavor = {"You sneak through the streets of Liberio!"},
		Mobs = { { IsHuman = true, Name = "Marleyan Guard", Health = 160, Strength = 35, Defense = 20, Speed = 30, Resolve = 30, TitanStats = emptyTitans, Skills = {"Heavy Slash", "Block"}, Drops = { Dews = 200, XP = 200 } } },
		Templates = {
			["Story_Part5_Intro"] = { IsDialogue = true, Speaker = "Eren Yeager", Text = "I just keep moving forward. Until my enemies are destroyed. The festival in Liberio begins now." },
			["Marleyan Guard"] = { IsHuman = true, Name = "Marleyan Guard", Health = 180, Strength = 35, Defense = 20, Speed = 30, Resolve = 30, TitanStats = emptyTitans, Skills = {"Heavy Slash", "Block"}, Drops = { Dews = 200, XP = 200 } },
			["Story_Part5_Mid"] = { IsDialogue = true, Speaker = "Willy Tybur", Text = "To the enemy forces of Paradis! This is a declaration of WAR!" },
			["Marleyan Elite"] = { IsHuman = true, Name = "Marleyan Elite", Health = 250, Strength = 50, Defense = 30, Speed = 45, Resolve = 40, TitanStats = emptyTitans, Skills = {"Anti-Titan Round", "Evasive Maneuver"}, Drops = { Dews = 300, XP = 300, ItemChance = {["Advanced ODM Gear"]=5} } },
			["Story_Part5_PreBoss"] = { IsDialogue = true, Speaker = "Mikasa Ackerman", Text = "Eren... please come back. The War Hammer Titan is manifesting! We have to destroy the crystal controlling it!" },
			["Part5Boss"] = { IsBoss = true, Name = "War Hammer Titan", Health = 1000, GateType = "Hardening", GateHP = 800, Strength = 120, Defense = 60, Speed = 60, Resolve = 60, TitanStats = {Power="A", Speed="B", Hardening="S", Endurance="B", Precision="A", Potential="A"}, Skills = {"War Hammer Spike", "Hardened Punch"}, Drops = { Dews = 2500, XP = 4000, ItemChance = { ["Spinal Fluid Syringe"] = 5, ["Marleyan Combat Manual"] = 15 } }, Phases = { { Health = 500, GateType = "None", GateHP = 0, Strength = 180, Defense = 40, Speed = 80, Skills = {"War Hammer Spike", "Crushed Boulders"}, Flavor = "<font color='#FFAA00'><b>The War Hammer sheds its armor for a final desperate assault!</b></font>" } } },
			["Story_Part5_Outro"] = { IsDialogue = true, Speaker = "Zeke Yeager", Text = "Everything is going according to plan. The Eldian restoration begins now.", Rewards = { ItemName = "Spinal Fluid Syringe", Amount = 1 } }
		},
		Missions = { 
			[1] = { Name = "Marleyan Assault", Waves = { { Template = "Story_Part5_Intro" }, { Template = "Marleyan Guard" }, { Template = "Story_Part5_Mid" }, { Template = "Marleyan Elite" }, { Template = "Story_Part5_PreBoss" }, { Template = "Part5Boss" }, { Template = "Story_Part5_Outro" } } }
		}
	},

	[6] = {
		RandomFlavor = {"You are ambushed in the ruins of Shiganshina!"},
		Mobs = { { Name = "Zeke's Controlled Titan", Health = 220, Strength = 60, Defense = 20, Speed = 40, Resolve = 20, TitanStats = emptyTitans, Skills = {"Brutal Swipe", "Stomp"}, Drops = { Dews = 350, XP = 300 } } },
		Templates = {
			["Story_Part6_Intro"] = { IsDialogue = true, Speaker = "Erwin Smith", Text = "My soldiers rage! My soldiers scream! My soldiers FIGHT! Charge the Beast Titan!" },
			["Evade_Rocks"] = { IsMinigame = "GapClose", Name = "Crushed Boulders", Health = 1, GateHP = 0, Strength = 0, Defense = 0, Speed = 0, Resolve = 0, TitanStats = emptyTitans, Skills = {}, Drops = { Dews = 200, XP = 200 } },
			["Zeke's Controlled Titan"] = { Name = "Zeke's Controlled Titan", Health = 220, Strength = 60, Defense = 20, Speed = 40, Resolve = 20, TitanStats = emptyTitans, Skills = {"Brutal Swipe", "Stomp"}, Drops = { Dews = 350, XP = 300 } }, 
			["Story_Part6_Mid"] = { IsDialogue = true, Speaker = "Levi Ackerman", Text = "Give up on your dreams and die. Lead the recruits straight into hell. I will take down the Beast Titan." },
			["Beast Titan Pitcher"] = { Name = "Beast Titan (Rock Throw)", Health = 350, Strength = 120, Defense = 60, Speed = 30, Resolve = 50, TitanStats = emptyTitans, IsLongRange = true, Skills = {"Crushed Boulders", "Block"}, Drops = { Dews = 500, XP = 600, ItemChance = {["Thunder Spear"]=5} } },
			["Story_Part6_PreBoss"] = { IsDialogue = true, Speaker = "Armin Arlert", Text = "The Armored Titan is charging the gates! Use the Thunder Spears! We have to blow off his armor!" },
			["Part6Boss"] = { IsBoss = true, Name = "Armored Titan (Reiner)", Health = 1200, GateType = "Reinforced Skin", GateHP = 1200, Strength = 150, Defense = 120, Speed = 45, Resolve = 60, TitanStats = {Power="B", Speed="C", Hardening="S", Endurance="A", Precision="C", Potential="C"}, Skills = {"Armored Tackle", "Hardened Punch", "Brutal Swipe"}, Drops = { Dews = 3500, XP = 5000, ItemChance = { ["Spinal Fluid Syringe"] = 2, ["Thunder Spear"] = 15 } }, Phases = { { Health = 1500, GateType = "None", GateHP = 0, Strength = 200, Defense = 60, Speed = 90, Skills = {"Frenzied Thrash", "Stomp"}, Flavor = "<font color='#FF5555'><b>Reiner sheds the armor from the back of his legs! His speed has doubled!</b></font>" } } },
			["Story_Part6_Outro"] = { IsDialogue = true, Speaker = "Hange Zoe", Text = "We did it... We reclaimed Wall Maria. And we found out the truth in the basement... The world outside is our enemy.", Rewards = { Dews = 5000, XP = 5000 } }
		},
		Missions = { 
			[1] = { Name = "Return to Shiganshina", Waves = { { Template = "Story_Part6_Intro" }, { Template = "Evade_Rocks" }, { Template = "Zeke's Controlled Titan" }, { Template = "Story_Part6_Mid" }, { Template = "Beast Titan Pitcher" }, { Template = "Story_Part6_PreBoss" }, { Template = "Part6Boss" }, { Template = "Story_Part6_Outro" } } }
		}
	},

	[7] = {
		RandomFlavor = {"Marleyan forces are dropping from the sky!"},
		Mobs = { { IsHuman = true, Name = "Marleyan Paratrooper", Health = 280, Strength = 90, Defense = 40, Speed = 60, Resolve = 50, TitanStats = emptyTitans, Skills = {"Heavy Slash", "Evasive Maneuver"}, Drops = { Dews = 600, XP = 500 } } },
		Templates = {
			["Story_Part7_Intro"] = { IsDialogue = true, Speaker = "Pieck Finger", Text = "Look at them scramble... Marleyan Airships are dropping troops right on top of Shiganshina! Secure the Founder!" },
			["Marleyan Paratrooper"] = { IsHuman = true, Name = "Marleyan Paratrooper", Health = 280, Strength = 90, Defense = 40, Speed = 60, Resolve = 50, TitanStats = emptyTitans, Skills = {"Heavy Slash", "Evasive Maneuver"}, Drops = { Dews = 600, XP = 500 } },
			["Story_Part7_Mid"] = { IsDialogue = true, Speaker = "Zeke Yeager", Text = "Eren! I'm here! Protect me while I reach you! Don't let them take the Anti-Titan Cannons!" },
			["Anti-Titan Artillery"] = { IsHuman = true, Name = "Anti-Titan Artillery", Health = 240, Strength = 150, Defense = 80, Speed = 10, Resolve = 60, TitanStats = emptyTitans, Skills = {"Anti-Titan Round", "Block"}, Drops = { Dews = 800, XP = 800 } },
			["Story_Part7_PreBoss"] = { IsDialogue = true, Speaker = "Porco Galliard", Text = "You devils... I'll chew you all to pieces! Feel the power of the Jaw Titan!" },
			["Part7Boss"] = { IsBoss = true, Name = "Jaw Titan (Porco)", Health = 1800, GateType = "Hardening", GateHP = 800, Strength = 180, Defense = 60, Speed = 150, Resolve = 80, TitanStats = {Power="A", Speed="S", Hardening="B", Endurance="C", Precision="A", Potential="B"}, Skills = {"Frenzied Thrash", "Titan Bite"}, Drops = { Dews = 4500, XP = 8000, ItemChance = { ["Standard Titan Serum"] = 20, ["Advanced ODM Gear"] = 10 } }, Phases = { { Health = 800, GateType = "Hardening", GateHP = 300, Strength = 250, Defense = 40, Speed = 200, Skills = {"Titan Bite", "Evasive Maneuver"}, Flavor = "<font color='#FF5555'><b>Porco goes into a blind rage! His speed is unfathomable!</b></font>" } } },
			["Story_Part7_Outro"] = { IsDialogue = true, Speaker = "Eren Yeager", Text = "Zeke... I've touched you. The Rumbling... begins now.", Rewards = { ItemName = "Clan Blood Vial", Amount = 1 } }
		},
		Missions = { 
			[1] = { Name = "War for Paradis", Waves = { { Template = "Story_Part7_Intro" }, { Template = "Marleyan Paratrooper" }, { Template = "Story_Part7_Mid" }, { Template = "Anti-Titan Artillery" }, { Template = "Story_Part7_PreBoss" }, { Template = "Part7Boss" }, { Template = "Story_Part7_Outro" } } }
		}
	},

	[8] = {
		RandomFlavor = {"The ground shakes violently. The Rumbling has begun!"},
		Mobs = { { Name = "Wall Titan", Health = 400, Strength = 250, Defense = 80, Speed = 20, Resolve = 60, TitanStats = emptyTitans, Skills = {"Colossal Steam", "Stomp", "Brutal Swipe"}, Drops = { Dews = 1000, XP = 1200 } } },
		Templates = {
			["Story_Part8_Intro"] = { IsDialogue = true, Speaker = "Eren Yeager", Text = "Hear me, all Subjects of Ymir. My name is Eren Yeager. I have undone the hardening of the walls of Paradis Island. I will trample every inch of the world beyond this island." },
			["Wall Titan"] = { Name = "Wall Titan", Health = 400, GateType = "Steam", GateHP = 2, Strength = 250, Defense = 80, Speed = 20, Resolve = 60, TitanStats = emptyTitans, Skills = {"Colossal Steam", "Stomp"}, Drops = { Dews = 1000, XP = 1200 } },
			["Story_Part8_Mid"] = { IsDialogue = true, Speaker = "Armin Arlert", Text = "We're on the Founding Titan's back! But Ymir... she's summoning the past Nine Titans to defend it!" },
			["Ancient Shifter"] = { Name = "Ancient Nine Titan Husk", Health = 600, Strength = 200, Defense = 100, Speed = 100, Resolve = 100, TitanStats = emptyTitans, Skills = {"Armored Tackle", "War Hammer Spike", "Titan Bite"}, Drops = { Dews = 1200, XP = 2000 } },
			["Story_Part8_PreBoss"] = { IsDialogue = true, Speaker = "System", Text = "A massive skeletal structure erupts from the bone. The Doomsday Titan stares down at you." },
			["Part8Boss"] = { IsBoss = true, Name = "Founding Titan", Health = 3500, GateType = "Steam", GateHP = 3, Strength = 350, Defense = 150, Speed = 15, Resolve = 150, TitanStats = {Power="S", Speed="E", Hardening="S", Endurance="S", Precision="S", Potential="S"}, Skills = {"Coordinate Command", "Colossal Steam", "War Hammer Spike"}, Drops = { Dews = 6000, XP = 35000, ItemChance = { ["Ymir's Clay Fragment"] = 2, ["Spinal Fluid Syringe"] = 5 } }, Phases = { { Health = 1500, GateType = "Hardening", GateHP = 1500, Strength = 500, Defense = 200, Speed = 40, Skills = {"Coordinate Command", "War Hammer Spike"}, Flavor = "<font color='#FFD700'><b>Ymir interferes! The Founding Titan is covered in crystal hardening!</b></font>" } } },
			["Story_Part8_Outro"] = { IsDialogue = true, Speaker = "Armin Arlert", Text = "It's over... We stopped the Rumbling. But the price we paid... was it worth it?", Rewards = { ItemName = "Ymir's Clay Fragment", Amount = 1 } }
		},
		Missions = { 
			[1] = { Name = "The Rumbling", Waves = { { Template = "Story_Part8_Intro" }, { Template = "Wall Titan" }, { Template = "Story_Part8_Mid" }, { Template = "Ancient Shifter" }, { Template = "Story_Part8_PreBoss" }, { Template = "Part8Boss" }, { Template = "Story_Part8_Outro" } } }
		}
	}
}

return EnemyData