local check_function = function()
    return true
end

--if settings.startup["randomtorio-check-possible"].value == "disable" then
--    return check_function
--end

local set_propper_results = function(this_needs_fixing, name)
    local results
    if this_needs_fixing.results then
        results = this_needs_fixing.results
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

local get_enabled_recipes = function(type)
    local enabled_recipes = {}
    for _, recipe in pairs(data.raw.recipe) do
        if recipe[type] and recipe[type].enabled and recipe[type].results then
            enabled_recipes["recipe-"..recipe.name] = {ingredients = recipe[type].ingredients, results = recipe[type].results}
        end
    end
    return enabled_recipes
end

local get_resource_list = function()
    local resource_list = {}
    for _, resource in pairs(data.raw.resource) do
        set_propper_results(resource.minable, resource.name)
        resource_list["resource-"..resource.name] = {results = resource.minable.results}
        if resource.minable.fluid_amount then
            resource_list["resource-"..resource.name].ingredients = {
                {
                type = "fluid",
                name = resource.minable.required_fluid,
                amount = resource.minable.fluid_amount
                }
            }
        end
        if resource.name == "crude-oil" then
            resource_list["resource-"..resource.name].ingredients = {
                {
                    type = "item",
                    name = "pumpjack",
                    amount = 1
                },
            }
        end
    end
    for _, pump in pairs(data.raw["offshore-pump"]) do
        resource_list["offshore-pump-"..pump.fluid.."-"..pump.name] = {
            ingredients = {
                {
                    type = "item",
                    name = pump.name,
                    amount = 1
                },
            },
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
        set_propper_results(tree.minable, tree.name)
        resource_list["tree-"..tree.name] = {results = tree.minable.results}
    end
    for _, fish in pairs(data.raw.fish) do
        set_propper_results(fish.minable, fish.name)
        resource_list["fish-"..fish.name] = {results = fish.minable.results}
    end
    for _, item in pairs(data.raw.item) do
        if item.burnt_result then
            resource_list["burn-"..item.name] = {
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
    end
    for _, item in pairs(data.raw.item) do
        if item.rocket_launch_product then
            resource_list["burn-"..item.name] = {
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
                    name = item.rocket_launch_product[1],
                    amount = item.rocket_launch_product[2]
                    },
                }
            }
        end
    end
    for _, boiler in pairs(data.raw.boiler) do
        resource_list["boiler-"..boiler.name] = {
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
    return resource_list
end

local type_list
local get_type_list = function()
    if type_list then return type_list end
    if settings.startup["randomtorio-check-possible"].value == "disable" then
        type_list = {"normal"}
    end
    if settings.startup["randomtorio-check-possible"].value == "normal-only" then
        type_list = {"normal"}
    end
    if settings.startup["randomtorio-check-possible"].value == "expensive-only" then
        type_list = {"expensive"}
    end
    if settings.startup["randomtorio-check-possible"].value == "normal-and-expensive" then
        type_list = {"normal", "expensive"}
    end
    return type_list
end

local science_packs
local get_science_packs = function()
    if science_packs then return science_packs end
    science_packs = {}
    for _, lab in pairs(data.raw.lab) do
        for _, pack in pairs(lab.inputs) do
            if not science_packs[pack] then
                science_packs[pack] = true
            end
        end
    end
    if randomtorio_techs then
        for item, techs in pairs(randomtorio_techs) do
            for _, tech in pairs(techs) do
                if data.raw.technology[tech] then
                    science_packs[item] = true
                end
            end
        end
    end
    return science_packs
end

local get_researched_recipes = function(pack_list, new_pack, difficulty)
    local return_list = {}
    local techs_on_item = {}
    if randomtorio_techs[new_pack] then
        for _, name in pairs(randomtorio_techs[new_pack]) do
            techs_on_item[name] = true
        end
    end
    for name, tech in pairs(data.raw.technology) do
        if not tech.hidden then
            local is_new = false
            local can_be_researched = true
            for _, packs in pairs(tech.unit.ingredients) do
                if not pack_list[packs[1]] and not pack_list[packs.name] then
                    can_be_researched = false
                elseif packs[1] == new_pack or packs.name == new_pack then
                    is_new = true
                end
            end
            if techs_on_item[name] then
                is_new = true
                can_be_researched = true
            end
            if is_new and can_be_researched then
                if tech.effects then
                    for _, effect in pairs(tech.effects) do
                        if effect.type == "unlock-recipe" then
                            if data.raw.recipe[effect.recipe][difficulty] then
                                return_list[effect.recipe] = {
                                    ingredients = data.raw.recipe[effect.recipe][difficulty].ingredients,
                                    results = data.raw.recipe[effect.recipe][difficulty].results
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    return return_list
end

local get_starter_items = function()
    return_list = {}
    if randomtorio_starting_items then
        for index, name in pairs(randomtorio_starting_items) do
            return_list[name] = true
        end
    end
    return return_list
end

check_function = function(output)

    local science_packs = get_science_packs()
    local completable = true
    for _, difficulty in pairs(get_type_list()) do
        local accesiable_recipe_list = get_enabled_recipes(difficulty)
        for name, info in pairs(get_resource_list()) do
            accesiable_recipe_list[name] = info
        end
        local usable_items = get_starter_items() or {}
        local made_packs = {}
        local new_finds = true
        while new_finds do
            new_finds = false
            for recipe_name, recipe in pairs(accesiable_recipe_list) do
                local craftable = true
                if recipe.ingredients then
                    for _, ingredient in pairs(recipe.ingredients) do
                        if not usable_items[ingredient.name] then
                            craftable = false
                        end
                    end
                end
                if craftable then
                    if recipe.results == nil then
                        log(serpent.line(recipe))
                    else
                        for _, result in pairs(recipe.results) do
                            if not usable_items[result.name] or (not made_packs[result.name] and science_packs[result.name]) then
                                usable_items[result.name] = true
                                new_finds = true
                                if science_packs[result.name] then
                                    --add more recipes based on tech unlocks
                                    made_packs[result.name] = true
                                    for name, info in pairs(get_researched_recipes(made_packs, result.name, difficulty)) do
                                        accesiable_recipe_list[name] = info
                                    end
                                end
                            end
                        end
                    end
                    accesiable_recipe_list[recipe_name] = nil
                end
            end
        end
        if output then
            log(table_size(accesiable_recipe_list))
            log(serpent.line(accesiable_recipe_list))
        end
        if table_size(accesiable_recipe_list) ~= 0 then
            if output then
                log("not completable, the items you can make:\n\n"..serpent.line(usable_items).."\n\nand these are the recipes you can not make:\n\n"..serpent.line(accesiable_recipe_list).."\n")
            end
            completable = false
        else
            log("completable")
        end
        if table_size(made_packs) > 0 then
            log(serpent.line(made_packs))
        end
    end
    return completable
end

return check_function