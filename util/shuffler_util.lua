r_util = require("util/randomutil")

local keep_this_safe = {
    recipes = nil,
    minable = nil,
    resources = nil,
    item_to_category = nil,
    category_to_item = nil,
    starting_recipes = nil,
    call_science = nil,
    lab_list = nil,
    pack_to_pack = {},
    tech_to_item = nil,
    powerpoles = nil,
    fuel_category_to_items = nil,
    item_to_category_with_results = {},
    results_icon = nil,
}


local set_propper_results = function(this_needs_fixing, name)
    local results = {}
    if this_needs_fixing.results then
        for _, result in pairs(this_needs_fixing.results) do
            if result.name then
                table.insert(results, r_util.deepcopy(result))
            else
                table.insert(results, {name = r_util.deepcopy(result[1]), amount = r_util.deepcopy(result[2]), type = "item"})
            end
        end
    elseif this_needs_fixing.result then
        if this_needs_fixing.count then
            results = {{type = "item", name = r_util.deepcopy(this_needs_fixing.result), amount = r_util.deepcopy(this_needs_fixing.count)}}
        else
            results = {{type = "item", name = r_util.deepcopy(this_needs_fixing.result), amount = 1}}
        end
    else
        results = {{type = "item", name = r_util.deepcopy(name), amount = 1}}
    end
    this_needs_fixing.results = results
    this_needs_fixing.result = nil
    this_needs_fixing.count = nil
end

local get_fresh_recipe_copy = function()
    if keep_this_safe.recipes then return r_util.deepcopy(keep_this_safe.recipes) end
    keep_this_safe.recipes = {results = {} , ingredients = {}}
    for _, recipe in pairs(data.raw.recipe) do
        if not recipe.hidden then
            keep_this_safe.recipes.results[recipe.category] = keep_this_safe.recipes.results[recipe.category] or {}
            keep_this_safe.recipes.ingredients["recipe-"..recipe.name] = keep_this_safe.recipes.ingredients["recipe-"..recipe.name] or {}
            keep_this_safe.recipes.results[recipe.category][#keep_this_safe.recipes.results[recipe.category]+1] = recipe.results
            keep_this_safe.recipes.ingredients["recipe-"..recipe.name] = {ingredients = recipe.ingredients, crafting_category = recipe.category}
        end
    end
    return r_util.deepcopy(keep_this_safe.recipes)
end

local get_starting_recipes = function()
    if keep_this_safe.starting_recipes then return r_util.deepcopy(keep_this_safe.starting_recipes) end
    keep_this_safe.starting_recipes = {}
    for _, recipe in pairs(data.raw.recipe) do
        if recipe.enabled then
            keep_this_safe.starting_recipes[recipe.category] = keep_this_safe.starting_recipes[recipe.category] or {}
            table.insert(keep_this_safe.starting_recipes[recipe.category], recipe.name)
        end
    end
    return r_util.deepcopy(keep_this_safe.starting_recipes)
end

local get_minable_list = function()
    if keep_this_safe.minable then return r_util.deepcopy(keep_this_safe.minable) end
    keep_this_safe.minable = {}
    for _, resource in pairs(data.raw.resource) do
        set_propper_results(resource.minable, resource.name)
        keep_this_safe.minable["resource-"..resource.name] = {results = resource.minable.results}
        keep_this_safe.minable["resource-"..resource.name].crafting_category = resource.category or "basic-solid"
        if resource.minable.fluid_amount then
            keep_this_safe.minable["resource-"..resource.name].ingredients = {
                {
                type = "fluid",
                name = resource.minable.required_fluid,
                amount = resource.minable.fluid_amount
                }
            }
            if resource.category then
                keep_this_safe.minable["resource-"..resource.name].crafting_category = resource.category.."-fluid"
            else
                keep_this_safe.minable["resource-"..resource.name].crafting_category = "basic-solid-fluid"
            end
        end
    end
    for _, pump in pairs(data.raw["offshore-pump"]) do
        keep_this_safe.minable["offshore-pump-"..pump.fluid.."-"..pump.name] = {
            crafting_category = "offshore-pump-"..pump.fluid,
            results = {
                {
                type = "fluid",
                name = pump.fluid,
                amount = pump.pumping_speed
                },
            }
        }
    end
    for _, tree in pairs(data.raw.tree) do
        if tree.minable then
            set_propper_results(tree.minable, tree.name)
            keep_this_safe.minable["tree-"..tree.name] = {
                crafting_category = "tree-mining",
                results = tree.minable.results,
            }
        end
    end
    for _, fish in pairs(data.raw.fish) do
        if fish.minable then
            set_propper_results(fish.minable, fish.name)
            keep_this_safe.minable["fish-"..fish.name] = {
                crafting_category = "fish-mining",
                results = fish.minable.results,
            }
        end
    end
    return r_util.deepcopy(keep_this_safe.minable)
end


local get_resource_list = function()
    if keep_this_safe.resources then return r_util.deepcopy(keep_this_safe.resources) end
    keep_this_safe.resources = get_minable_list()
    for _, item in pairs(data.raw.item) do
        if item.burnt_result then
            keep_this_safe.resources["burn-"..item.name] = {
                crafting_category = "burning-"..item.fuel_category,
                ingredients = {
                    {
                        type = "item",
                        name = item.name,
                        amount = 1
                    },
                },
                results = {
                    {
                    type = "item",
                    name = item.burnt_result,
                    amount = 1
                    },
                }
            }
        end
        if item.rocket_launch_product or item.rocket_launch_products then
            if item.rocket_launch_products then
                for index, result in pairs(item.rocket_launch_products) do
                    if result[1] then
                        result = {
                            type = "item",
                            name = result[1],
                            amount = result[2],
                        }
                    end
                end
                item.rocket_launch_product = nil
            end
            if item.rocket_launch_product then 
                if item.rocket_launch_product[1] then
                    item.rocket_launch_products = {{
                        type = "item",
                        name = item.rocket_launch_product[1],
                        amount = item.rocket_launch_product[2],
                    }}
                else
                    item.rocket_launch_products = {{
                        type = "item",
                        name = item.rocket_launch_product.name,
                        amount = item.rocket_launch_product.count,
                    }}
                end
            end
            keep_this_safe.resources["rocket-launch-"..item.name] = {
                crafting_category = "rocket-launching",
                ingredients = {
                    {
                        type = "item",
                        name = item.name,
                        amount = 1
                    },
                },
                results = item.rocket_launch_products,
            }
        end
    end
    for _, boiler in pairs(data.raw.boiler) do
        if boiler.fluid_box.filter and boiler.output_fluid_box.filter then
            keep_this_safe.resources["boiler-"..boiler.name] = {
                crafting_category = boiler.fluid_box.filter.."-"..boiler.output_fluid_box.filter,
                ingredients = {
                    {
                        type = "fluid",
                        name = boiler.fluid_box.filter,
                        amount = 1
                    },
                },
                results = {
                    {
                    type = "fluid",
                    name = boiler.output_fluid_box.filter,
                    amount = 1
                    },
                }
            }
        end
    end
    return r_util.deepcopy(keep_this_safe.resources)
end

local powerpoles = function(made_items)
    if not keep_this_safe.powerpoles then
        keep_this_safe.powerpoles = {}
        for _, item in pairs(data.raw.item) do
            if item.place_result then
                if data.raw["electric-pole"][item.place_result] then
                    table.insert(keep_this_safe.powerpoles, item.name)
                end
            end
        end
    end
    if made_items then
        for _, pole in pairs(keep_this_safe.powerpoles) do
            if made_items[pole] then
                return true
            end
        end
        return false
    else
        return keep_this_safe.powerpoles
    end
end

local get_fuel_category_to_items = function()
    if keep_this_safe.fuel_category_to_items then return keep_this_safe.fuel_category_to_items end
    keep_this_safe.fuel_category_to_items = {}
    for _, item in pairs(data.raw.item) do
        if item.fuel_category then
            keep_this_safe.fuel_category_to_items[item.fuel_category] = keep_this_safe.fuel_category_to_items[item.fuel_category] or {}
            table.insert(keep_this_safe.fuel_category_to_items[item.fuel_category], item.name)
        end
    end
    return keep_this_safe.fuel_category_to_items
end

local get_list_items_that_unlock_categories = function()
    if keep_this_safe.item_to_category then return keep_this_safe.item_to_category end
    keep_this_safe.item_to_category = randomtorio_crafting_category_unlocks
    for _, item in pairs(data.raw.item) do
        if item.place_result then
            for _, place in pairs({"assembling-machine","furnace","rocket-silo"}) do
                if data.raw[place][item.place_result] then
                    if data.raw[place][item.place_result].crafting_categories then
                        for _, names in pairs(data.raw[place][item.place_result].crafting_categories) do
                            keep_this_safe.item_to_category[item.name] = keep_this_safe.item_to_category[item.name] or {}
                            table.insert(keep_this_safe.item_to_category[item.name], names)
                        end
                    end
                end
            end
            for _, place in pairs({"reactor","furnace","boiler"}) do
                if data.raw[place][item.place_result] and data.raw[place][item.place_result].energy_source and data.raw[place][item.place_result].energy_source.fuel_category then
                    keep_this_safe.item_to_category[item.name] = keep_this_safe.item_to_category[item.name] or {}
                    table.insert(keep_this_safe.item_to_category[item.name], "burning-"..data.raw[place][item.place_result].energy_source.fuel_category)
                end
            end
            if data.raw["burner-generator"][item.place_result] and data.raw["burner-generator"][item.place_result].energy_source then
                keep_this_safe.item_to_category[item.name] = keep_this_safe.item_to_category[item.name] or {}
                table.insert(keep_this_safe.item_to_category[item.name], "burning-"..data.raw["burner-generator"][item.place_result].burner.fuel_category)
            end
            if data.raw["offshore-pump"][item.place_result] and data.raw["offshore-pump"][item.place_result].fluid then
                keep_this_safe.item_to_category[item.name] = keep_this_safe.item_to_category[item.name] or {}
                table.insert(keep_this_safe.item_to_category[item.name], "offshore-pump-"..data.raw["offshore-pump"][item.place_result].fluid)
            end
            if data.raw["boiler"][item.place_result] and data.raw["boiler"][item.place_result].fluid_box and data.raw["boiler"][item.place_result].output_fluid_box and data.raw["boiler"][item.place_result].fluid_box.filter and data.raw["boiler"][item.place_result].output_fluid_box.filter then
                keep_this_safe.item_to_category[item.name] = keep_this_safe.item_to_category[item.name] or {}
                table.insert(keep_this_safe.item_to_category[item.name], data.raw["boiler"][item.place_result].fluid_box.filter.."-"..data.raw["boiler"][item.place_result].output_fluid_box.filter)
            end
            if data.raw["mining-drill"][item.place_result] then
                keep_this_safe.item_to_category[item.name] = keep_this_safe.item_to_category[item.name] or {}
                if data.raw["mining-drill"][item.place_result].resource_categories then
                    for _, category in pairs(data.raw["mining-drill"][item.place_result].resource_categories) do
                        table.insert(keep_this_safe.item_to_category[item.name], category)
                    end
                    if data.raw["mining-drill"][item.place_result].input_fluid_box then
                        for _, category in pairs(data.raw["mining-drill"][item.place_result].resource_categories) do
                            table.insert(keep_this_safe.item_to_category[item.name], category.."-fluid")
                        end
                    end
                else
                    table.insert(keep_this_safe.item_to_category[item.name], "basic-solid")
                    if data.raw["mining-drill"][item.place_result].resource_categories.input_fluid_box then
                        table.insert(keep_this_safe.item_to_category[item.name], "basic-solid-fluid")
                    end
                end
            end                    
        end
    end
    return keep_this_safe.item_to_category
end

local get_list_categories_that_get_unlocked_by_items = function()
    if keep_this_safe.category_to_item then return keep_this_safe.category_to_item end
    keep_this_safe.category_to_item = {}
    for item, categories in pairs(get_list_items_that_unlock_categories()) do
        for index, category in pairs(categories) do
            keep_this_safe.category_to_item[category] = keep_this_safe.category_to_item[category] or {}
            table.insert(keep_this_safe.category_to_item[category], item)
        end
    end
    return keep_this_safe.category_to_item
end

local get_tech_to_item = function()
    if keep_this_safe.tech_to_item then return keep_this_safe.tech_to_item end

    for item, techs in pairs(randomtorio_techs) do
        for _, tech in pairs(techs) do
            keep_this_safe.tech_to_item[tech] = item
        end
    end
    return keep_this_safe.tech_to_item
end

local get_good_packs = function(pack_list)
    local pack_string = "base-"
    for name, _ in pairs(pack_list) do
        pack_string = pack_string..name.."-"
    end
    
    if keep_this_safe.pack_to_pack[pack_string] then return keep_this_safe.pack_to_pack[pack_string] end

    keep_this_safe.pack_to_pack[pack_string] = {}
    local packs_in_list = {}
    for _, tech in pairs(data.raw.technology) do
        local difference = 0
        local new_pack
        for _, pack in pairs(tech.unit.ingredients) do
            pack_name = pack[1] or pack.name
            if not pack_list[pack_name] then
                difference = difference + 1
                new_pack = pack_name
            end
        end
        if difference == 1 then
            if get_tech_to_item() then
                if get_tech_to_item()[tech] then
                    new_pack = get_tech_to_item()[tech]
                end
            end
            if not packs_in_list[new_pack] then
                table.insert(keep_this_safe.pack_to_pack[pack_string], new_pack)
                packs_in_list[new_pack] = true
            end
        end
    end
    return keep_this_safe.pack_to_pack[pack_string]
end


local get_lab_list = function()
    if keep_this_safe.lab_list then return keep_this_safe.lab_list end
    keep_this_safe.lab_list = {}
    for _, lab in pairs(data.raw.lab) do
        keep_this_safe.lab_list[lab.name] = {name = lab.name, items = {}, recipes = {}}
        local pack_list = {}
        for _, pack in pairs(lab.inputs) do
            pack_list[pack] = true
        end
        for _, lab2 in pairs(data.raw.lab) do
            local commons = 0
            for _, pack2 in pairs(lab2.inputs) do
                if pack_list[pack2] then
                    commons = commons + 1
                end
            end
            if commons == table_size(pack_list) and table_size(lab2.inputs) > commons then
                keep_this_safe.lab_list[lab.name].upgrades = keep_this_safe.lab_list[lab.name].upgrades or {}
                keep_this_safe.lab_list[lab.name].upgrades[lab2.name] = true
            elseif table_size(lab2.inputs) > commons then
                keep_this_safe.lab_list[lab.name].side_step = keep_this_safe.lab_list[lab.name].side_step or {}
                keep_this_safe.lab_list[lab.name].side_step[lab2.name] = true
            end
        end
    end
    local item_to_lab = {}
    for _, item in pairs(data.raw.item) do
        if item.place_result then
            if keep_this_safe.lab_list[item.place_result] then
                keep_this_safe.lab_list[item.place_result].items[item.name] = true
                item_to_lab[item.name] = item.place_result
            end
        end
    end
    for _, recipe in pairs(data.raw.recipe) do
        if recipe.results then
            for _, result in pairs(recipe.results) do
                if item_to_lab[result.name] then
                    keep_this_safe.lab_list[item_to_lab[result.name]].recipes[recipe.name] = {
                        name = recipe.name,
                        results = recipe.results,
                        category = recipe.crafting_category
                    }
                end
            end
        end
    end
    return keep_this_safe.lab_list
end

local call_for_science = function()
    if keep_this_safe.call_science then return keep_this_safe.call_science end
    keep_this_safe.call_science = {}
    for _, item in pairs(data.raw.item) do
        if item.place_result then
            if data.raw.lab[item.place_result] then
                keep_this_safe.call_science[item.name] = {}
                keep_this_safe.call_science[item.name].lab = true
                keep_this_safe.call_science[item.name].name = item.name
            end
        end
    end
    for _, lab in pairs(data.raw.lab) do
        for _, pack in pairs(lab.inputs) do
            keep_this_safe.call_science[pack] = keep_this_safe.call_science[pack] or {}
            keep_this_safe.call_science[pack].pack = true
            keep_this_safe.call_science[pack].name = pack
        end
    end
    for name, _ in pairs(randomtorio_techs) do
        for index, tech in pairs(randomtorio_techs[name]) do
            if not data.raw.technology[tech] then
                table.remove(randomtorio_techs, index)
            end
        end
        if randomtorio_techs[name] then
            keep_this_safe.call_science[name] = keep_this_safe.call_science[name] or {}
            keep_this_safe.call_science[name].item = true
            keep_this_safe.call_science[name].name = name
        end
    end
    return keep_this_safe.call_science
end

local item_to_all_its_crafts = function(item, unused_recipes)
    if keep_this_safe.item_to_category_with_results[item] then return keep_this_safe.item_to_category_with_results[item] end
    keep_this_safe.item_to_category_with_results[item] = {}
    for category, result_list in pairs(unused_recipes.results) do
        for _, results in pairs(result_list) do
            for _, result in pairs(results) do
                if result.name == item then
                    table.insert(keep_this_safe.item_to_category_with_results[item], {results = results, category = category})
                end
            end
        end
    end
    for _, recipe in pairs(s_util.get_resource_list()) do
        if recipe.results then
            for _, result in pairs(recipe.results) do
                if result.name == item then
                    table.insert(keep_this_safe.item_to_category_with_results[item], {results = recipe.results, category = recipe.crafting_category, lock = true})
                end
            end
        end
    end
    return keep_this_safe.item_to_category_with_results[item]
end

local result_to_icon_store = function()
    if keep_this_safe.result_icon then return end
    keep_this_safe.result_icon = {}
    for name, recipe in pairs(data.raw.recipe) do
        keep_this_safe.result_icon[name] = {
            icons = r_util.deepcopy(recipe.icons),
            results = r_util.deepcopy(recipe.results),
        }
    end
end

local result_to_icon_write = function()
    local result_icon = r_util.deepcopy(keep_this_safe.result_icon)
    for name, recipe in pairs(data.raw.recipe) do
        local storage_name
        for name2, recipe2 in pairs(result_icon) do
            if table.compare(recipe.results, recipe2.results) then
                recipe.icons = recipe2.icons
                storage_name = name2
                break
            end
        end
        result_icon[storage_name] = nil
    end
end

local calculate_item_costs = function(made_items, costs, result_name, result_amount, base_resources)
    --This will calculate the worth of the old and new output and put the lowest of the two in the made_items list
    if made_items[result_name] then
        local cost_value = {old = 0, new = 0}
        for _, value in pairs(costs) do
            cost_value.new = cost_value.new + value
        end
        cost_value.new = cost_value.new/result_amount
        for _, value in pairs(made_items[result_name]) do
            cost_value.old = cost_value.old + value
        end
        if cost_value.new > cost_value.old then return end
    end
    made_items[result_name] = {}
    for name, value in pairs(costs) do
        made_items[result_name][name] = value/result_amount
    end
    if base_resources[result_name] and not made_items[result_name] then
        made_items[result_name] = 1
    end
    return
end

local costs_calculator = function()
    --makes a list of how much each item costs

    local minables = get_minable_list()
    local resources = get_resource_list()
    local base_resources = {}
    local made_items = {}

    --sorts out base resources. Like iron, copper and uranium so that it can display the value of that.
    for name, resource in pairs(resources) do
        if minables[name] then
            if resource.results and not resource.ingredients then
                for _, result in pairs(resource.results) do
                    base_resources[result.name] = true
                    made_items[result.name] = {[result.name] = 1}
                end
                resources[name] = nil
            elseif resource.results then
                for _, result in pairs(resource.results) do
                    base_resources[result.name] = true
                end
            end
        end
    end

    local recipes = util.table.deepcopy(data.raw.recipe)

    --merges the base resource list with the recipe list.
    for name, resource in pairs(resources) do
        if not recipes[name] then
            recipes[name] = resource
        elseif not recipes["randomtorio-"..name] then
            recipes["randomtorio-"..name] = resource
        elseif not recipes["resource-thingy-"..name] then
            recipes["resource-thingy-"..name] = resource
        elseif not recipes["resource-collecting-"..name] then
            recipes["resource-collecting-"..name] = resource
        elseif not recipes["hw83p29wnscg2a1lp_s-"..name] then
            recipes["hw83p29wnscg2a1lp_s-"..name] = resource
        else
            error("could not merge 2 lists without making conflicts")
        end
    end

    --Makes the recipe.amount value a float based on what it truly will give.
    for _, recipe in pairs(recipes) do
        if recipe.results then
            for _, result in pairs(recipe.results) do
                if not result.amount then
                    if result.amount_min < result.amount_max then
                        result.amount = (result.amount_min + result.amount_max) / 2
                    else
                        result.amount = result.amount_min
                    end
                end                    
                if result.probability then
                    result.amount = result.amount * result.probability
                end
            end
        end
    end

    --loops trhoug the recipes a max of 1 000 000 times and looks during that what items can be made and calculates the cost for that.
    local loops = 0
    while table_size(recipes) >= 1 and loops <= 1000000 do
        loops = loops + 1
        for recipe_name, recipe in pairs(recipes) do
            if recipe.hidden then
                recipes[recipe_name] = nil
            else
                if recipe.ingredients then
                    local makeble = true
                    local costs = {time = recipe.energy_required or 0}
                    for _, ingredient in pairs(recipe.ingredients) do
                        if not made_items[ingredient.name] then
                            makeble = false
                            break
                        else
                            for name, value in pairs(made_items[ingredient.name]) do
                                costs[name] = costs[name] or 0
                                costs[name] = costs[name] + value * ingredient.amount
                            end
                        end
                    end
                    if makeble then
                        for _, result in pairs(recipe.results) do
                            calculate_item_costs(made_items, costs, result.name, result.amount, base_resources)
                        end
                        recipes[recipe_name] = nil
                    end
                else
                    local costs = {time = recipe.energy_required or 0}
                    for _, result in pairs(recipe.results) do
                        calculate_item_costs(made_items, costs, result.name, result.amount, base_resources)
                    end
                    recipes[recipe_name] = nil
                end
            end
        end
    end

    return made_items
end

local display_items_layout = function()

    --makes a list of items that need to be displayed.
    local item_cost = costs_calculator()
    local items_to_display = {}
    for name, info in pairs(call_for_science()) do
        if info.pack or info.item then
            if item_cost[name] then
                items_to_display[name] = item_cost[name]
            end
        end
    end
    for index, name in pairs(r_util.settings_extractor("randomtorio-display-costs")) do 
        if item_cost[name] then
            items_to_display[name] = item_cost[name]
        end
    end

    --determains what the dimentions of each space needs to be so everything lines up
    local layout = {num_len = {}, name_size = 0}

    for name, costs in pairs(items_to_display) do
        name_len = string.len(name)
        if name_len > layout.name_size then
            layout.name_size = name_len
        end
        for name, cost in pairs(costs) do
            cost = math.floor(cost * 100 + 0.5) / 100
            costs[name] = cost
            num_size = math.floor(math.log(cost,10)) + 1
            layout.num_len[name] = layout.num_len[name] or 0
            if num_size > layout.num_len[name] then
                layout.num_len[name] = num_size
            end
        end
    end

    local stringcompiling = "        Science packs cost:"
    for name, info in pairs(call_for_science()) do
        if items_to_display[name] and (info.pack or info.item) then
            stringcompiling = stringcompiling.."\n            "..string.format("%-"..layout.name_size.."s", name).." needs "
            for crafting, size in pairs(layout.num_len) do
                if crafting ~= "time" then
                    local space = size+3
                    
                    if items_to_display[name][crafting] == nil then
                        stringcompiling = stringcompiling.." "..string.format("%"..space.."s", "").." "..crafting..","
                    else
                        stringcompiling = stringcompiling.." "..string.format("%"..space..".2f", items_to_display[name][crafting]).." "..crafting..","
                    end
                end
            end
            local space = layout.num_len.time+3

            if items_to_display[name].time == nil then
                stringcompiling = string.sub(stringcompiling, 1, -2).." and "..string.format("%"..space.."s", "").." seconds spend crafting"
            else
                stringcompiling = string.sub(stringcompiling, 1, -2).." and "..string.format("%"..space..".2f", items_to_display[name].time).." seconds spend crafting"
            end
            items_to_display[name] = nil
        end
    end

    if table_size(items_to_display) >= 1 then
        stringcompiling = stringcompiling.."\n\n        Others cost:"
        for name, _ in pairs(items_to_display) do
            stringcompiling = stringcompiling.."\n            "..string.format("%-"..layout.name_size.."s", name).." needs "
            for crafting, size in pairs(layout.num_len) do
                if crafting ~= "time" then
                    local space = size+3

                    if items_to_display[name][crafting] == nil then
                        stringcompiling = stringcompiling.." "..string.format("%"..space.."s", "").." "..crafting..","
                    else
                        stringcompiling = stringcompiling.." "..string.format("%"..space..".2f", items_to_display[name][crafting]).." "..crafting..","
                    end
                end
            end
            local space = layout.num_len.time+3

            if items_to_display[name].time == nil then
                stringcompiling = string.sub(stringcompiling, 1, -2).." and "..string.format("%"..space.."s", "").." seconds spend crafting"
            else
                stringcompiling = string.sub(stringcompiling, 1, -2).." and "..string.format("%"..space..".2f", items_to_display[name].time).." seconds spend crafting"
            end
            items_to_display[name] = nil
        end
    end

    return stringcompiling
end

local setting_info = function()
    local return_string = "\n\n        Settings:"

    local display_costs = settings.startup["randomtorio-display-costs"].value
    local no_use = settings.startup["randomtorio-do-not-use"].value
    local start_with = settings.startup["randomtorio-start-with"].value
    return_string = return_string.."\n            log items:  "..display_costs
    return_string = return_string.."\n            Processed:  "..serpent.line(r_util.settings_extractor("randomtorio-display-costs"))
    return_string = return_string.."\n            no use:     "..no_use
    return_string = return_string.."\n            Processed:  "..serpent.line(r_util.settings_extractor("randomtorio-do-not-use"))
    return_string = return_string.."\n            start with: "..start_with
    return_string = return_string.."\n            Processed:  "..serpent.line(r_util.settings_extractor("randomtorio-start-with"))

    return return_string
end

local log_seed_info = function(seed, possible)
    
    if type(seed) ~= "number" then
        log("\n------------------------------------------------------------------------\n   The calculated costs without randomizing:\n\n"..display_items_layout()..setting_info().."\n------------------------------------------------------------------------")
    else
        if possible then
            log("\n------------------------------------------------------------------------\n   The calculated costs for seed, you can play it: "..seed.."\n\n"..display_items_layout().."\n------------------------------------------------------------------------")
        else
            log("\n------------------------------------------------------------------------\n   No costs are calulated for the incompletable seed: "..seed.."\n------------------------------------------------------------------------")
        end
    end
end
    
local functions = {
    set_propper_results = set_propper_results,
    get_fresh_recipe_copy = get_fresh_recipe_copy,
    get_starting_recipes = get_starting_recipes,
    get_minable_list = get_minable_list,
    get_resource_list = get_resource_list,
    powerpoles = powerpoles,
    get_fuel_category_to_items = get_fuel_category_to_items,
    get_list_items_that_unlock_categories = get_list_items_that_unlock_categories,
    get_list_categories_that_get_unlocked_by_items = get_list_categories_that_get_unlocked_by_items,
    get_tech_to_item = get_tech_to_item,
    get_good_packs = get_good_packs,
    get_lab_list = get_lab_list,
    call_for_science = call_for_science,
    item_to_all_its_crafts = item_to_all_its_crafts,
    result_to_icon_store = result_to_icon_store,
    result_to_icon_write = result_to_icon_write,
    costs_calculator = costs_calculator,
    log_seed_info = log_seed_info,
}

return functions