randomtorio_starting_items = {}
--send a list with the names of the items you start with. To this variable.
--and ONLY the names of the items you start with. For example {"iron-plate","copper-plate"}
--DO NOT insert items you get too little of. The base game does not get a list because 8 iron plates are too few to do anything with. And everything can be mined if you start with 0.

randomtorio_techs = {}
--if you have (like seablock) a few techs that get researched based on accomplishments
--you give the item and the tech it unlocks. If (like seablock) you have a tech unlock depending on the techs avaible, put them all in. I filter the not existing techs out of it.

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