local category_to_machines_map
local category_to_machines = function()
    if category_to_machines_map then return category_to_machines_map end
    category_to_machines_map = {}
    for type_name, _ in pairs(defines.prototypes.entity) do
        for _, entity in pairs(data.raw[type_name]) do
            if entity.crafting_categories then
                for _, name in pairs(entity.crafting_categories) do
                    if category_to_machines_map[name] then
                        table.insert(category_to_machines_map[name], entity.name)
                    else
                        category_to_machines_map[name] = {entity.name}
                    end
                end
            end
        end
    end
    return category_to_machines_map
end

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
            enabled_recipes["recipe-"..recipe.name] = {ingredients = recipe[type].ingredients, results = recipe[type].results, machines = category_to_machines()[recipe.category]}
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
        resource_list["offshore-pump-"..pump.fluid] = {
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
                    type = "fluid",
                    name = item.burnt_result,
                    amount = 1
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
