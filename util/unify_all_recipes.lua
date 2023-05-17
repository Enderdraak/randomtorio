local list_of_item_places = {}
for _, list in pairs({defines.prototypes.item,defines.prototypes.fluid}) do
    for place, _ in pairs(list) do
        if not list_of_item_places[place] then
            list_of_item_places[place] = true
        end
    end
end

local set_propper_ingredients = function(this_needs_fixing)
    local ingredients = {}
    for _, ingredient in pairs(this_needs_fixing.ingredients) do
        if ingredient.name then
            table.insert(ingredients, r_util.deepcopy(ingredient))
        else
            table.insert(ingredients, {name = r_util.deepcopy(ingredient[1]), amount = r_util.deepcopy(ingredient[2]), type = "item"})
        end
    end
    this_needs_fixing.ingredients = ingredients
end

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
        if this_needs_fixing.result_count then
            results = {{type = "item", name = r_util.deepcopy(this_needs_fixing.result), amount = r_util.deepcopy(this_needs_fixing.result_count)}}
        else
            results = {{type = "item", name = r_util.deepcopy(this_needs_fixing.result), amount = 1}}
        end
    else
        results = {{type = "item", name = r_util.deepcopy(name), amount = 1}}
    end
    this_needs_fixing.results = results
    this_needs_fixing.result = nil
    this_needs_fixing.result_count = nil
end

local get_propper_icons = function(prototype)
    local return_icons
    if prototype.icons then
        return_icons = prototype.icons
        for _, icon in pairs(return_icons) do
            if not icon.icon_size then
                icon.icon_size = prototype.icon_size
            end
        end
    else
        return_icons = {{icon = prototype.icon, icon_size = prototype.icon_size, icon_mipmaps = prototype.icon_mipmaps}}
    end
    return return_icons
end

local set_normal_or_expensive = function(recieve, giveth)
    local give = {}
    if giveth then
        give = r_util.deepcopy(giveth)
    end

    recieve.enabled = give.enabled
    recieve.energy_required = give.energy_required
    recieve.emissions_multiplier = give.emissions_multiplier
    recieve.requester_paste_multiplier = give.requester_paste_multiplier
    recieve.overload_multiplier = give.overload_multiplier
    recieve.allow_inserter_overload = give.allow_inserter_overload
    recieve.hidden = give.hidden
    recieve.hide_from_stats = give.hide_from_stats
    recieve.hide_from_player_crafting = give.hide_from_player_crafting
    recieve.allow_decomposition = give.allow_decomposition
    recieve.allow_as_intermediate = give.allow_as_intermediate
    recieve.allow_intermediates = give.allow_intermediates
    recieve.always_show_made_in = give.always_show_made_in
    recieve.show_amount_in_title = give.show_amount_in_title
    recieve.always_show_products = give.always_show_products
    recieve.unlock_results = give.unlock_results
    recieve.main_product = give.main_product

    recieve.results = give.results
    recieve.result = give.result
    recieve.result_count = give.result_count 

    recieve.ingredients = give.ingredients

end

local get_item_deepcopy = function(name)
    for item_type, _ in pairs(list_of_item_places) do
        if data.raw[item_type][name] then
            return r_util.deepcopy(data.raw[item_type][name])
        end
    end
end

local get_entity_deepcopy = function(name)
    for places, _ in pairs(defines.prototypes.entity) do
        for name_entity, entity in pairs(data.raw[places]) do
            if name == name_entity then
                return r_util.deepcopy(entity)
            end
        end
    end
end

local is_equipment = function(name)
    for places, _ in pairs(defines.prototypes.equipment) do
        for _, equipment in pairs(data.raw[places]) do
            if name == equipment.name then
                return true
            end
        end
    end
end

for _, recipe in pairs(data.raw.recipe) do
    local base_item = {}
    
    if recipe.main_product and recipe.main_product ~= "" then
        base_item = get_item_deepcopy(recipe.main_product)
    elseif recipe.normal and recipe.normal.main_product and recipe.normal.main_product ~= "" then
        base_item = get_item_deepcopy(recipe.normal.main_product)
    elseif recipe.expensive and recipe.expensive.main_product and recipe.expensive.main_product ~= "" then
        base_item = get_item_deepcopy(recipe.expensive.main_product)
    elseif recipe.result then
        base_item = get_item_deepcopy(recipe.result)
    elseif recipe.normal and recipe.normal.result then
        base_item = get_item_deepcopy(recipe.normal.result)
    elseif recipe.expensive and recipe.expensive.result then
        base_item = get_item_deepcopy(recipe.expensive.result)
    elseif recipe.results and #recipe.results == 1 then
        if recipe.results[1].name then
            base_item = get_item_deepcopy(recipe.results[1].name)
        else
            base_item = get_item_deepcopy(recipe.results[1][1])
        end
    elseif recipe.normal and recipe.normal.results and #recipe.normal.results == 1 then
        if recipe.normal.results[1].name then
            base_item = get_item_deepcopy(recipe.normal.results[1].name)
        else
            base_item = get_item_deepcopy(recipe.normal.results[1][1])
        end
    elseif recipe.expensive and recipe.expensive.results and #recipe.expensive.results == 1 then
        if recipe.expensive.results[1].name then
            base_item = get_item_deepcopy(recipe.expensive.results[1].name)
        else
            base_item = get_item_deepcopy(recipe.expensive.results[1][1])
        end
    else
        base_item = get_item_deepcopy(recipe.name)
    end
    recipe.category = recipe.category or "crafting"
    
    if not recipe.icons then
        if recipe.icon then
            recipe.icons = {{icon = r_util.deepcopy(recipe.icon), icon_size = r_util.deepcopy(recipe.icon_size), icon_mipmaps = r_util.deepcopy(recipe.icon_mipmaps)}}
            recipe.icon = nil
            recipe.icon_size = nil
            recipe.icon_mipmaps = nil
        else
            if not base_item then
                log(serpent.line(recipe))
                log(serpent.line(base_item))
                error(recipe.name.." has no base item or fluid found to take icons from and the recipe does not have any on its own")
            end
            recipe.icons = get_propper_icons(base_item)
        end
    end
    
    if not recipe.order then
        if base_item == nil then
            recipe.order ="what-the-fuck-do-you-want????"
        else
            recipe.order = base_item.order
        end
    end
    if not recipe.subgroup then
        if base_item == nil then
            recipe.subgroup = "what-the-fuck-do-you-want????"
        else
            recipe.subgroup = base_item.subgroup
        end
    end
    if not recipe.localised_name then
        if base_item and recipe.main_product ~= "" then
            if base_item.localised_name then
                recipe.localised_name = base_item.localised_name
            elseif base_item.place_result then
                local entity = get_entity_deepcopy(base_item.place_result)
                if entity then
                    if entity.localised_name then
                        recipe.localised_name = entity.localised_name
                    else
                        recipe.localised_name = {"entity-name."..entity.name}
                    end
                else
                    if base_item.type == "fluid" then
                        recipe.localised_name = {"fluid-name."..base_item.name}
                    else
                        recipe.localised_name = {"item-name."..base_item.name}
                    end
                end
            elseif is_equipment(base_item.name) then
                if base_item.localised_name then
                    recipe.localised_name = base_item.localised_name
                else
                    recipe.localised_name = {"equipment-name."..base_item.name}
                end
            else
                if base_item.type == "fluid" then
                    recipe.localised_name = {"fluid-name."..base_item.name}
                else
                    recipe.localised_name = {"item-name."..base_item.name}
                end
            end
        else
            recipe.localised_name = {"recipe-name."..recipe.name}
        end
    end

    if recipe.normal == nil and recipe.expensive == nil then
        recipe.normal = {}
        recipe.expensive = {}
        if recipe.enabled == nil then
            recipe.enabled = true
        end
        set_normal_or_expensive(recipe.normal, recipe)
        set_normal_or_expensive(recipe.expensive, recipe)
    elseif recipe.normal == nil then
        recipe.normal = {}
        if recipe.expensive.enabled == nil then
            recipe.expensive.enabled = true
        end
        set_normal_or_expensive(recipe.normal, recipe.expensive)
    elseif recipe.expensive == nil then
        recipe.expensive = {}
        if recipe.normal.enabled == nil then
            recipe.normal.enabled = true
        end
        set_normal_or_expensive(recipe.expensive, recipe.normal)
    else
        if recipe.normal.enabled == nil then
            recipe.normal.enabled = true
        end
        if recipe.expensive.enabled == nil then
            recipe.expensive.enabled = true
        end
    end
    if recipe.normal then
        set_propper_results(recipe.normal, recipe.name)
        set_propper_ingredients(recipe.normal)
    end 
    if recipe.expensive then
        set_propper_results(recipe.expensive, recipe.name)
        set_propper_ingredients(recipe.expensive)
    end
    
    set_normal_or_expensive(recipe)
end

local get_one_type = function()
    if settings.startup["randomtorio-normal-or-expensive"].value == "normal" then
        for _, recipe in pairs(data.raw.recipe) do
            if recipe.normal == false then
                set_normal_or_expensive(recipe, recipe.expensive)
                recipe.hidden = true
                recipe.normal = nil
                recipe.expensive = nil
                recipe.always_show_products = true
            else
                set_normal_or_expensive(recipe, recipe.normal)
                recipe.normal = nil
                recipe.expensive = nil
                recipe.always_show_products = true
            end
        end
    else
        for _, recipe in pairs(data.raw.recipe) do
            if recipe.expensive == false then
                set_normal_or_expensive(recipe, recipe.normal)
                recipe.hidden = true
                recipe.normal = nil
                recipe.expensive = nil
                recipe.always_show_products = true
            else
                set_normal_or_expensive(recipe, recipe.expensive)
                recipe.normal = nil
                recipe.expensive = nil
                recipe.always_show_products = true
            end
        end
    end
    local recipe_list = {}
    for _, tech in pairs(data.raw.technology) do
        if tech.effects then
            for _, effect in pairs(tech.effects) do
                if effect.type == "unlock-recipe" then
                    recipe_list[effect.recipe] = true
                end
            end
        end
    end
    for _, recipe in pairs(data.raw.recipe) do
        if not recipe.enabled and not recipe_list[recipe.name] then
            recipe.hidden = true
        end
    end
end

return get_one_type