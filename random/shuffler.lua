r_util = require("util/randomutil")

s_util = require("util/shuffler_util")

cleanup = require("util/unify_all_recipes")

local unlock_locked_recipes = function(locked_recipes, avaible_crafting, made_items)
    local crafted_items = {}
    for name, recipe in pairs(locked_recipes) do
        if avaible_crafting[recipe.crafting_category] then
            local makeble = true
            if recipe.ingredients then
                for _, ingredient in pairs(recipe.ingredients) do
                    if not made_items[ingredient.name] then
                        makeble = false
                    end
                end
            end
            if makeble then 
                for _, result in pairs(recipe.results) do
                    if not made_items[result.name] then
                        made_items[result.name] = true
                        crafted_items[result.name] = true
                    end
                end
                locked_recipes[name] = nil
            end
        end
    end
    return crafted_items
end

local new_stuff = function(unused_recipes, ingredients_to_pick, avaible_crafting, made_items)
    local is_new = false
    for name, info in pairs(unused_recipes.ingredients) do
        if avaible_crafting[info.crafting_category] then
            local makeble = true
            for _, ingredient in pairs(info.ingredients) do
                if not made_items[ingredient.name] then
                    makeble = false
                    break
                end
            end
            if makeble then
                is_new = true
                ingredients_to_pick[#ingredients_to_pick+1] = info
                unused_recipes.ingredients[name] = nil
            end
        end
    end
    return is_new
end

local nothing_left = function(ingredients_to_pick, avaible_crafting, researched_recipes)
    for _, ingredients in pairs(ingredients_to_pick) do
        if avaible_crafting[ingredients.crafting_category] then
            if researched_recipes[ingredients.crafting_category] then
                if #researched_recipes[ingredients.crafting_category] >= 1 then
                    return false
                end
            end
        end
    end
    return true
end


local required_items_store
local science
local items_to_recipes
local picked_energy_paths
local storage_function_reset = function()
    science = {
        lab = {},
        packs_in_labs = {},
        packs_crafted = {},
        packs_completed = {},
        item = {},
        done_recipes = {},
    }
    for _, list in pairs(s_util.get_starting_recipes()) do
        for _, recipe in pairs(list) do
            science.done_recipes[recipe] = true
        end
    end
    required_items_store = {
        items = {},
        energy = {},
        results = {},
    }
    items_to_recipes = {}
    picked_energy_paths = {}
end

local science_unlock = function(item, energy_types, researched_recipes)
    if not s_util.call_for_science()[item] then return end
    local new_to_research = {}
    local unlock_new = false
    if s_util.call_for_science()[item].lab then
        if not science.lab[item] then
            if data.raw.lab[data.raw.item[item].place_result].energy_source then
                local energy_type
                if data.raw.lab[data.raw.item[item].place_result].energy_source.type then energy_type = data.raw.lab[data.raw.item[item].place_result].energy_source.type end
                if data.raw.lab[data.raw.item[item].place_result].energy_source.type == "burner" then energy_type = data.raw.lab[data.raw.item[item].place_result].energy_source.fuel_category end
                if energy_types[energy_type] then
                    science.lab[item] = true
                    for _, pack in pairs(data.raw.lab[data.raw.item[item].place_result].inputs) do
                        if not science.packs_in_labs[pack] then
                            science.packs_in_labs[pack] = true
                            if science.packs_crafted[pack] then
                                science.packs_completed[pack] = true
                                new_to_research[pack] = true
                            end
                        end
                    end
                end
            else
                science.lab[item] = true
                for _, pack in pairs(data.raw.lab[data.raw.item[item].place_result].inputs) do
                    if not science.packs_in_labs[pack] then
                        science.packs_in_labs[pack] = true
                        if science.packs_crafted[pack] then
                            science.packs_completed[pack] = true
                            new_to_research[pack] = true
                        end
                    end
                end
            end
        end
    end
    if s_util.call_for_science()[item].pack then
        if not science.packs_crafted[item] then
            science.packs_crafted[item] = true
            if science.packs_in_labs[item] then
                science.packs_completed[item] = true
                new_to_research[item] = true
            end
        end
    end
    if s_util.call_for_science()[item].item then
        if not science.item[item] then
            science.item[item] = true
            for _, tech in pairs(randomtorio_techs[item]) do
                if data.raw.technology[tech].effects then
                    for _, effect in pairs(data.raw.technology[tech].effects) do
                        if effect.type == "unlock-recipe" then
                            if not science.done_recipes[effect.recipe] then
                                recipe = data.raw.recipe[effect.recipe]
                                researched_recipes[recipe.category] = researched_recipes[recipe.category] or {}
                                science.done_recipes[recipe.name] = true
                                table.insert(researched_recipes[recipe.category], recipe.name)
                                unlock_new = true
                            end
                        end
                    end
                end
            end
        end
    end
    if table_size(new_to_research) >= 1 then
        log("unlocking techs of:  "..serpent.line(new_to_research))
        for _, tech in pairs(data.raw.technology) do
            local is_new = false
            local researchable = true
            for _, pack in pairs(tech.unit.ingredients) do
                if new_to_research[pack[1]] then
                    is_new = true
                end
                if not science.packs_completed[pack[1]] then
                    researchable = false
                end
            end
            if is_new and researchable then
                --log(tech.name)
                if tech.effects then
                    for _, effect in pairs(tech.effects) do
                        if effect.type == "unlock-recipe" then
                            if not science.done_recipes[effect.recipe] then
                                recipe = data.raw.recipe[effect.recipe]
                                researched_recipes[recipe.category] = researched_recipes[recipe.category] or {}
                                science.done_recipes[recipe.name] = true
                                table.insert(researched_recipes[recipe.category], recipe.name)
                                unlock_new = true
                            end
                        end
                    end
                end
            end
        end
    end
    return unlock_new
end

local get_energy_type = function(item)
    local place_result
    if data.raw.item[item] then
        if data.raw.item[item].place_result then
            for _, places in pairs({"assembling-machine","reactor","furnace","boiler","rocket-silo","boiler","burner-generator","offshore-pump","lab","mining-drill"}) do
                if data.raw[places][data.raw.item[item].place_result] then
                    place_result = data.raw[places][data.raw.item[item].place_result]
                    break
                end
            end
            if place_result then
                local energy_source
                for _, places in pairs({"burner","energy_source"}) do
                    if place_result[places] then
                        energy_source = place_result[places]
                        break
                    end
                end
                if energy_source == nil then return nil end
                if energy_source.type == "burner" then return energy_source.fuel_category end
                if energy_source.type then return energy_source.type end
            end
        end
    end
end


local item_to_crafts
item_to_crafts = function(items, avaible_crafting, unused_recipes, energy_types, made_items)
    local return_list = {
        energy = {},
        results = {},
    }
    local energies_to_make = {}
    for item, _ in pairs(items) do
        if not items_to_recipes[item] then
            items_to_recipes[item] = s_util.item_to_all_its_crafts(item, unused_recipes)[r_util.random(#s_util.item_to_all_its_crafts(item, unused_recipes))]
        end
        if items_to_recipes[item] then
            return_list.results[items_to_recipes[item].category] = return_list.results[items_to_recipes[item].category] or {}
            table.insert(return_list.results[items_to_recipes[item].category], items_to_recipes[item].results)
        end
        if get_energy_type(item) and not energy_types[get_energy_type(item)] then
            energies_to_make[get_energy_type(item)] = true
        end
    end
    local list_to_make_more = {}
    local already_avaiable = r_util.deepcopy(avaible_crafting)
    for category, _ in pairs(return_list.results) do
        if not avaible_crafting[category] then
            list_to_make_more[category] = true
            already_avaiable[category] = true
        end
    end
    local more_items = {}
    for category, _ in pairs(list_to_make_more) do
        if not items_to_recipes[category] then
            items_to_recipes[category] = s_util.get_list_categories_that_get_unlocked_by_items()[category][r_util.random(#s_util.get_list_categories_that_get_unlocked_by_items()[category])]
        end
        more_items[items_to_recipes[category]] = true
    end

    local power_already = r_util.deepcopy(energy_types)
    for energy, _ in pairs(energies_to_make) do
        power_already[energy] = true
        if not picked_energy_paths[energy] then
            local power
            if energy == "electric" then
                power = randomtorio_power_generation[r_util.random(#randomtorio_power_generation)]
                if not s_util.powerpoles(made_items) then
                    table.insert(power, s_util.powerpoles()[r_util.random(#s_util.powerpoles())])
                end
            elseif energy == "heat" then
                power = randomtorio_heat_generation[r_util.random(#randomtorio_heat_generation)]
            else
                power = {s_util.get_fuel_category_to_items()[energy][r_util.random(#s_util.get_fuel_category_to_items()[energy])]}
            end
            picked_energy_paths[energy] = power
        end
        for _, item in pairs(picked_energy_paths[energy]) do
            more_items[item] = true
        end
        return_list.energy[energy] = picked_energy_paths[energy]
    end
    
    if table_size(more_items) >= 1 then
        local crafted_items = r_util.deepcopy(made_items)
        for item, _ in pairs(items) do
            crafted_items[item] = true
        end
        for name, group in pairs(item_to_crafts(more_items, already_avaiable, unused_recipes, power_already, crafted_items)) do
            for category, crafts in pairs(group) do
                for _, craft in pairs(crafts) do
                    return_list[name][category] = return_list[name][category] or {}
                    table.insert(return_list[name][category], craft)
                end
            end
        end
    end
    return return_list
end


local get_required_items = function(energy_types, made_items, avaible_crafting, unused_recipes)
    
    local good_to_go = true
    if table_size(required_items_store.results) >= 1 then
        for item, _ in pairs(required_items_store.items) do
            if made_items[item] then
                if s_util.call_for_science()[item] then
                    if s_util.call_for_science()[item].pack or s_util.call_for_science()[item].item then
                        good_to_go = false
                    end
                end
                required_items_store.items[item] = nil
            end
        end
        for item, goal in pairs(items_to_recipes) do
            if made_items[item] then
                for category, list in pairs(required_items_store.results) do
                    for index, result in pairs(list) do
                        if table.compare(result, goal.results) then
                            --log("this was crafted: "..serpent.line(table.remove(required_items_store.results[category], index)))
                            table.remove(required_items_store.results[category], index)
                            if table_size(required_items_store.results[category]) == 0 then
                                required_items_store.results[category] = nil
                                if table_size(required_items_store.results) == 0 then
                                    good_to_go = false
                                end
                            end
                        end
                    end
                end
            end
        end
        for energy, list in pairs(required_items_store.energy) do
            if energy_types[energy] then
                for _, items in pairs(list) do
                    for category, list in pairs(required_items_store.results) do
                        for index, result in pairs(list) do
                            if table.compare(result, items_to_recipes[items]) then
                                table.remove(required_items_store.results[category], index)
                                if table_size(required_items_store.results[category]) == 0 then
                                    required_items_store.results[category] = nil
                                    if table_size(required_items_store.results) == 0 then
                                        good_to_go = false
                                    end
                                end
                            end
                        end
                    end
                    required_items_store.items[items] = nil
                end
                required_items_store.energy[energy] = nil
            end
        end
        if good_to_go then return required_items_store.results end
        --log("not returned")
    else
        local finished = true
        for _, item in pairs(s_util.call_for_science()) do
            if item.item or item.pack then
                if not made_items[item] then
                    finished = false
                    break
                end
            end
        end
        if finished then return {} end
    end

    local left_over_packs = {}
    for pack, _ in pairs(science.packs_in_labs) do
        if not science.packs_crafted[pack] then
            left_over_packs[pack] = true
        end
    end
    local next_packs = s_util.get_good_packs(science.packs_completed)
    local packs_by_index = {}
    for _, pack in pairs(next_packs) do
        if left_over_packs[pack] then
            table.insert(packs_by_index, pack)
        end
    end

    if table_size(packs_by_index) >= 1 then
        required_items_store.items[packs_by_index[r_util.random(table_size(packs_by_index))]] = true
    else
        for item, _ in pairs(required_items_store.items) do
            if s_util.call_for_science()[item] then
                if s_util.call_for_science()[item].lab then
                    return required_items_store.results
                end
            end
        end
        local lab_list = s_util.get_lab_list()
        local labs_info = {made = {}, unpowered = {labs = {}, types = {}}, upgrades = {}, side_step = {}}
        for _, lab in pairs(lab_list) do
            local energy_type
            if data.raw.lab[lab.name].energy_source.type then energy_type = data.raw.lab[lab.name].energy_source.type end
            if data.raw.lab[lab.name].energy_source.type == "burner" then energy_type = data.raw.lab[lab.name].energy_source.fuel_category end
            if made_items[lab.name] and energy_types[energy_type] then
                labs_info.made[lab.name] = true
            else
                table.insert(labs_info.upgrades, lab.name)
                table.insert(labs_info.side_step, lab.name)
            end
            
            if not energy_types[energy_type] then
                labs_info.unpowered.labs[lab.name] = true
                labs_info.unpowered.types[energy_type] = true
            end
        end

        local power_accounted_for = false
        for energy, _ in pairs(required_items_store.energy) do
            if labs_info.unpowered.types[energy] then
                power_accounted_for = true
            end
        end
        if power_accounted_for then return required_items_store.results end

        for lab, _ in pairs(labs_info.made) do
            if lab_list[lab].upgrades then
                for index, upgrade in pairs(labs_info.upgrades) do
                    if not lab_list[lab].upgrades[upgrade] then
                        table.remove(labs_info.upgrades, index)
                    end
                end
            else
                labs_info.upgrades = {}
            end
            if lab_list[lab].side_step then
                for index, side_step in pairs(labs_info.side_step) do
                    if not lab_list[lab].side_step[side_step] then
                        table.remove(labs_info.side_step, index)
                    end
                end
            else
                labs_info.side_step = {}
            end
        end
        local added_lab
        if table_size(labs_info.upgrades) == 1 then
            added_lab = labs_info.upgrades[1]
        elseif table_size(labs_info.upgrades) >= 1 then
            added_lab = labs_info.upgrades[r_util.random(table_size(labs_info.upgrades))]
        elseif table_size(labs_info.side_step) == 1 then
            added_lab = labs_info.side_step[1]
        elseif table_size(labs_info.side_step) >= 1 then
            added_lab = labs_info.side_step[r_util.random(table_size(labs_info.side_step))]
        end
        if added_lab == nil then return required_items_store.results end

        required_items_store.items[added_lab] = true

        local packs_in_labs = r_util.deepcopy(science.packs_in_labs)
        for _, pack in pairs(data.raw.lab[data.raw.item[added_lab].place_result].inputs) do
            if not packs_in_labs[pack] then
                packs_in_labs[pack] = true
            end
        end
        left_over_packs = {}
        for pack, _ in pairs(packs_in_labs) do
            if not science.packs_crafted[pack] then
                left_over_packs[pack] = true
            end
        end
        next_packs = s_util.get_good_packs(science.packs_completed)
        packs_by_index = {}
        for _, pack in pairs(next_packs) do
            if left_over_packs[pack] then
                table.insert(packs_by_index, pack)
            end
        end

        if table_size(packs_by_index) >= 1 then
            required_items_store.items[packs_by_index[r_util.random(table_size(packs_by_index))]] = true
        end
    end

    items_to_craft_list = item_to_crafts(required_items_store.items, avaible_crafting, unused_recipes, energy_types, made_items)

    for place, list in pairs(items_to_craft_list) do
        for category, objects in pairs(list) do
            for _, object in pairs(objects) do
                required_items_store[place][category] = required_items_store[place][category] or {}
                table.insert(required_items_store[place][category], object)
            end
        end
    end

    return required_items_store.results
end

local get_list_of_items_that_open_possibilities = function(rand_ingredients, unused_recipes, made_items, avaible_crafting, energy_types)
    --find all the items that can be made with this crafting category as this state
    local items_that_could_be_made = {}
    for index, results in pairs(unused_recipes.results[rand_ingredients.crafting_category]) do
        for _, result in pairs(results) do
            items_that_could_be_made[result.name] = items_that_could_be_made[result.name] or {}
            table.insert(items_that_could_be_made[result.name], index)
        end
    end

    --find all items that allow for one or more recipe to be opened
    local items_that_open_possibilities = {}
    for _, info in pairs(unused_recipes.ingredients) do
        if avaible_crafting[info.crafting_category] then
            local missing = nil
            local no = nil
            for _, ingredient in pairs(info.ingredients) do
                if not made_items[ingredient.name] then
                    if missing then
                        no = true
                        break
                    end
                    missing = ingredient.name
                end
            end
            if not no then
                if items_that_could_be_made[missing] then
                    items_that_open_possibilities[missing] = true
                end
            end
        end
    end

    --allow for crafting categories to be forced open as well
    for category, items in pairs(s_util.get_list_categories_that_get_unlocked_by_items()) do
        for _, item in pairs(items) do
            if items_that_could_be_made[item] then
                for _, category in pairs(s_util.get_list_items_that_unlock_categories()[item]) do
                    if not avaible_crafting[category] then
                        if not get_energy_type(item) then
                            items_that_open_possibilities[item] = true
                        elseif energy_types[get_energy_type(item)] then
                            items_that_open_possibilities[item] = true
                        end
                        break
                    end
                end
            end
        end
    end

    local index_that_open_possibilities = {}
    for item, _ in pairs(items_that_open_possibilities) do
        table.insert(index_that_open_possibilities, item)
    end
    return index_that_open_possibilities
end

local force_more_recipes = function(rand_ingredients, unused_recipes, made_items, avaible_crafting, energy_types)
    --find all the items that can be made with this crafting category as this state
    local items_that_could_be_made = {}
    for index, results in pairs(unused_recipes.results[rand_ingredients.crafting_category]) do
        for _, result in pairs(results) do
            items_that_could_be_made[result.name] = items_that_could_be_made[result.name] or {}
            table.insert(items_that_could_be_made[result.name], index)
        end
    end

    local index_that_open_possibilities = get_list_of_items_that_open_possibilities(rand_ingredients, unused_recipes, made_items, avaible_crafting, energy_types)
    if #index_that_open_possibilities == 0 then
        return r_util.random(#unused_recipes.results[rand_ingredients.crafting_category])
    else
        rand_item = index_that_open_possibilities[r_util.random(#index_that_open_possibilities)]
        return items_that_could_be_made[rand_item][r_util.random(#items_that_could_be_made[rand_item])]
    end
end

local unlock_powerless_machines = function(energy_type, energy_types, avaible_crafting, powerless_machines)
    energy_types[energy_type] = true
    local unlock_new = false
    for _, machine in pairs(powerless_machines[energy_type] or {}) do
        for _, category in pairs(s_util.get_list_items_that_unlock_categories()[machine]) do
            if not avaible_crafting[category] then
                avaible_crafting[category] = true
                unlock_new = true
            end
        end
    end
    powerless_machines[energy_type] = nil
    return unlock_new
end


local unlock_power = function(made_items, energy_types, avaible_crafting, powerless_machines, result)
    local unlock_new = false
    if data.raw.item[result] then
        if data.raw.item[result].fuel_category then
            unlock_new = unlock_powerless_machines(data.raw.item[result].fuel_category, energy_types, avaible_crafting, powerless_machines) or unlock_new
        end
    end
    if not energy_types["electric"] then
        if s_util.powerpoles(made_items) then
            for _, list in pairs(randomtorio_power_generation) do
                local buildable = true
                for _, item in pairs(list) do
                    if not made_items[item] then
                        buildable = false
                        break
                    end
                end
                if buildable then
                    log("power came online!!!")
                    unlock_new = unlock_powerless_machines("electric", energy_types, avaible_crafting, powerless_machines) or unlock_new
                end
            end
        end
    end
    if not energy_types["heat"] then
        for _, list in pairs(randomtorio_heat_generation) do
            local buildable = true
            for _, item in pairs(list) do
                if not made_items[item] then
                    buildable = false
                    break
                end
            end
            if buildable then
                unlock_new = unlock_powerless_machines("electric", energy_types, avaible_crafting, powerless_machines) or unlock_new
            end
        end
    end
    return unlock_new
end

local unlock_categories = function(result, energy_types, avaible_crafting, powerless_machines)
    local unlock_new = false
    if s_util.get_list_items_that_unlock_categories()[result] then
        local place_result
        for _, places in pairs({"assembling-machine","reactor","furnace","boiler","rocket-silo","boiler","burner-generator","offshore-pump","lab","mining-drill"}) do
            if data.raw[places][data.raw.item[result].place_result] then
                place_result = data.raw[places][data.raw.item[result].place_result]
                break
            end
        end
        if place_result then
            local energy_source
            for _, places in pairs({"burner","energy_source"}) do
                if place_result[places] then
                    energy_source = place_result[places]
                    break
                end
            end
            if energy_source then
                local energy_type
                if energy_source.type then energy_type = energy_source.type end
                if energy_source.type == "burner" then energy_type = energy_source.fuel_category end
                if energy_types[energy_type] then
                    for _, category in pairs(s_util.get_list_items_that_unlock_categories()[result]) do
                        avaible_crafting[category] = true
                    end
                else
                    powerless_machines[energy_type] = powerless_machines[energy_type] or {}
                    table.insert(powerless_machines[energy_type], result)
                end
            else
                for _, category in pairs(s_util.get_list_items_that_unlock_categories()[result]) do
                    avaible_crafting[category] = true
                end
            end
        else
            for _, category in pairs(s_util.get_list_items_that_unlock_categories()[result]) do
                avaible_crafting[category] = true
            end
        end
    end
end

local functions = {}
functions.run = function()

    local energy_types = {["heat"] = false, ["electric"] = false}
    local powerless_machines = {["heat"] = {}, ["electric"] = {}}
    local made_items = {}
    local avaible_crafting = r_util.deepcopy(randomtorio_starting_crafting_categories)
    local unused_recipes = s_util.get_fresh_recipe_copy()
    local locked_recipes = s_util.get_resource_list()
    local ingredients_to_pick = {}
    local researched_recipes = s_util.get_starting_recipes()
    
    storage_function_reset()

    local required_items = get_required_items(energy_types, made_items, avaible_crafting, unused_recipes)

    unlock_locked_recipes(locked_recipes, avaible_crafting, made_items)
    new_stuff(unused_recipes, ingredients_to_pick, avaible_crafting, made_items)
    for item, _ in pairs(made_items) do
        if data.raw.item[item] then
            if data.raw.item[item].fuel_category then
                energy_types[data.raw.item[item].fuel_category] = true
            end
        end
    end

    while #ingredients_to_pick >= 1 do

        required_items = get_required_items(energy_types, made_items, avaible_crafting, unused_recipes)

        if nothing_left(ingredients_to_pick, avaible_crafting, researched_recipes) then
            break
        end

        local rand_num = 0
        while true do
            if #ingredients_to_pick == 1 then
                rand_num = 1
            else
                rand_num = r_util.random(#ingredients_to_pick)
            end
            if researched_recipes[ingredients_to_pick[rand_num].crafting_category] then
                if #researched_recipes[ingredients_to_pick[rand_num].crafting_category] >= 1 then
                    break
                end
            end
        end
        rand_ingredients = table.remove(ingredients_to_pick, rand_num)
        
        if #researched_recipes[rand_ingredients.crafting_category] == 1 then
            rand_num = 1
        else
            rand_num = r_util.random(#researched_recipes[rand_ingredients.crafting_category])
        end
        rand_recipe = table.remove(researched_recipes[rand_ingredients.crafting_category], rand_num)

        if required_items[rand_ingredients.crafting_category] then
            if #required_items[rand_ingredients.crafting_category] >= #researched_recipes[rand_ingredients.crafting_category] + 1 then
                rand_num = r_util.random(#required_items[rand_ingredients.crafting_category])
                for index, result in pairs(unused_recipes.results[rand_ingredients.crafting_category]) do
                    if table.compare(required_items[rand_ingredients.crafting_category][rand_num], result) then
                        rand_num = index
                        break
                    end
                end
            else
                if #ingredients_to_pick <= #required_items[rand_ingredients.crafting_category] then
                    rand_num = force_more_recipes(rand_ingredients, unused_recipes, made_items, avaible_crafting, energy_types)
                else
                    rand_num = r_util.random(#unused_recipes.results[rand_ingredients.crafting_category])
                end
            end
        else
            local left_that_do = get_list_of_items_that_open_possibilities(rand_ingredients, unused_recipes, made_items, avaible_crafting, energy_types)
            if #ingredients_to_pick <= 1 or #ingredients_to_pick <= #left_that_do then
                rand_num = force_more_recipes(rand_ingredients, unused_recipes, made_items, avaible_crafting, energy_types)
            else
                rand_num = r_util.random(#unused_recipes.results[rand_ingredients.crafting_category])
            end
        end
        rand_result = table.remove(unused_recipes.results[rand_ingredients.crafting_category], rand_num)

        data.raw.recipe[rand_recipe].ingredients = rand_ingredients.ingredients
        data.raw.recipe[rand_recipe].results = rand_result
        
        local unlock_new = false
        for _, result in pairs(rand_result) do
            if not made_items[result.name] then
                made_items[result.name] = true
                unlock_new = true
                unlock_new = (unlock_power(made_items, energy_types, avaible_crafting, powerless_machines, result.name) or unlock_new)
                unlock_new = (unlock_categories(result.name, energy_types, avaible_crafting, powerless_machines) or unlock_new)
                unlock_new = (science_unlock(result.name, energy_types, researched_recipes) or unlock_new)
            end
        end
        while unlock_new do
            unlock_new = false
            for item, _ in pairs(unlock_locked_recipes(locked_recipes, avaible_crafting, made_items)) do
                unlock_new = unlock_power(made_items, energy_types, avaible_crafting, powerless_machines, item) or unlock_new
                unlock_new = unlock_categories(item, energy_types, avaible_crafting, powerless_machines) or unlock_new
            end
            for _, item in pairs(s_util.call_for_science()) do
                if made_items[item.name] then
                    unlock_new = science_unlock(item.name, energy_types, researched_recipes) or unlock_new
                end
            end
            new_stuff(unused_recipes, ingredients_to_pick, avaible_crafting, made_items)
        end

    end
    if table_size(unused_recipes.ingredients) >= 1 or table_size(ingredients_to_pick) >= 1 then
        return false
    else
        return true
    end
end

functions.startup = function()
    r_util.startup()
    cleanup()
end

functions.multiruns = function()
    if settings.startup["randomtorio-first-randomizer"].value == false then
        functions.startup()
        local count = 0
        local seed = settings.startup["randomtorio-randomseed"].value
        local possible = functions.run()
        while not possible and count < settings.startup["randomtorio-check-amount"].value do
            count = count + 1
            seed = seed + 1
            r_util.seed(seed)
            possible = functions.run()
        end
        if possible then
            log("\n------------------------------------------------------------------------\n                        This is the working seed:\n                        "..seed.."\n------------------------------------------------------------------------")
        else
            log("\n------------------------------------------------------------------------\n              This is the current seed, it is not completeble:\n                        "..seed.."\n------------------------------------------------------------------------")
        end
    end
end

return functions