randomtorio_starting_items = {}
--send a list with the names of the items you start with. To this variable.
--and ONLY the names of the items you start with. For example {"iron-plate","copper-plate"}
--DO NOT insert items you get too little of. The base game does not get a list because 8 iron plates are too few to do anything with. And everything can better be assumed to get mined which you can do if you start from 0.

randomtorio_techs = {}
--if you have (like seablock) a few techs that get researched based on accomplishments
--you give the item and the tech it unlocks. If (like seablock) you have a tech unlock depending on the techs avaible, put them all in. I filter the not existing techs out of it.

randomtorio_crafting_category_unlocks = {["rocket-silo"] = {"rocket-launching"}}
--for if an item unlocks a category that my code can not pick up on. (this includes rocket siloes)
--Example, if you need robots to start mining trees and fish you can insert ["construction-robot"] = {"tree-mining", "fish-mining"}
--Do note that multiple items (and entities) can unlock the same recipe categories and thus every (modded) construction robot should be noted down as well for this example.

randomtorio_starting_crafting_categories = {}
--these are all the crafting categories you can access at the start.
--I have several special categories for different things. More info on that below.

randomtorio_power_generation = {}
--These are ways you can make power and all the entities you need for it. This is so you can tell machines to need power and it gets identified if it is possible to get it.
--down below more info on it.

randomtorio_heat_generation = {}
--These are ways you can make heat and all the entities you need for it. This is so you can tell machines to need power and it gets identified if it is possible to get it.
--down below more info on it.

randomtorio_starting_crafting_categories = {
    ["tree-mining"] = true, --This one is to see if you can mine any and all trees
    ["fish-mining"] = true, --This one is to see if you can mine any and all fishes
    --["rocket-launching"] = true, --this one is to see if you have access to a silo that can launch stuff
    --["offshore-pump-water"] = true, --The same as above. But this is for all offshore pumps you can access at the start of the game. While you can craft it at the start of the game you DO NOT spawn with it, so it is disabled. It is build up like: "offshore-pump-"..fluid
    
    ["burning-chemical"] = true, --This is the basic way in vanilla to burn items. Used in stone furnuses and trains and stuff. But you can not do it by hand and need the luck of being able to make a furnuss. With vanilla you have the luck of starting with one so this will be accessiable.
    --["burning-nuclear"] = true, --This is the one for in nuclear reactors. As you can see the way it builds these up is "burning-"..fuel_category
    
    ["basic-solid"] = true, --These are the ores you can mine by hand by default. So only iron, copper, coal and stone.
    --["basic-solid-fluid"] = true, --These are the ores you need a fuild for to mine. Like uranium. You can not do that by hand so no access to this at the start of the game.
    --["basic-fluid"] = true, --This is the oil and other fluid patches. Once again you can not mine this by hand so no access.
    --Any other recourse category will be automaticly made if it is detected.

    --["water-steam"] = true, --This one is for the boiler and heat exchanger. If you use modded fluids it will become `fluid_in.."-"..fluid_out` but I do not expect anyone needing to use this.

    ["crafting"] = true, --the normal crafting recipes the character can make. Should you (like brave new world) not have a character but some assambling machines this list might become a bit longer since those can often do more things.
    ["smelting"] = true, --You start with a stone furnusses
}

randomtorio_power_generation = {
    --you put in lists all the items needed to make power. Transport of electic power gets checked for as well but is not needed in this list.
    {
        "steam-engine", "steam", --The most basic of power setups, steam goes in and power comes out.
    },
    {
        "solar-panel", --easiest power source. if you can make solar power you can have power, no accus because those only store power.
    },
    {
        "steam-turbine", "steam", --nuclear power. But any steam works
    },
}

randomtorio_heat_generation = {
    {
        "nuclear-reactor", "nuclear-fuel", --The only way in vanilla to make heat.
    },
}

if mods["SeaBlock"] then
    table.insert(randomtorio_starting_items,"stone")
    table.insert(randomtorio_starting_items,"iron-plate")
    table.insert(randomtorio_starting_items,"basic-circuit-board")
    table.insert(randomtorio_starting_items,"stone-pipe")
    table.insert(randomtorio_starting_items,"stone-pipe-to-ground")
    table.insert(randomtorio_starting_items,"stone-brick")
    table.insert(randomtorio_starting_items,"iron-gear-wheel")
    table.insert(randomtorio_starting_items,"iron-stick")
    table.insert(randomtorio_starting_items,"pipe")
    table.insert(randomtorio_starting_items,"pipe-to-ground")
    table.insert(randomtorio_starting_items,"copper-pipe")

    randomtorio_techs["angels-ore3-crushed"] = {"sb-startup1", "landfill"}
    randomtorio_techs["algae-brown"] = {"sb-startup2", "bio-wood-processing", "bio-paper-1"}
    randomtorio_techs["basic-circuit-board"] = {"sb-startup3", "sct-lab-t1"}
    randomtorio_techs["lab"] = {"sct-automation-science-pack", "sb-startup4"}
end