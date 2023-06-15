r_util = require("util/randomutil")

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

    local give = r_util.deepcopy(giveth)

    recieve.enabled = give.enabled or recieve.enabled
    recieve.energy_required = give.energy_required or recieve.energy_required or 0.5
    recieve.emissions_multiplier = give.emissions_multiplier or recieve.emissions_multiplier
    recieve.requester_paste_multiplier = give.requester_paste_multiplier or recieve.requester_paste_multiplier
    recieve.overload_multiplier = give.overload_multiplier or recieve.overload_multiplier
    recieve.allow_inserter_overload = give.allow_inserter_overload or recieve.allow_inserter_overload
    recieve.hidden = give.hidden or recieve.hidden
    recieve.hide_from_stats = give.hide_from_stats or recieve.hide_from_stats
    recieve.hide_from_player_crafting = give.hide_from_player_crafting or recieve.hide_from_player_crafting
    recieve.allow_decomposition = give.allow_decomposition or recieve.allow_decomposition
    recieve.allow_as_intermediate = give.allow_as_intermediate or recieve.allow_as_intermediate
    recieve.allow_intermediates = give.allow_intermediates or recieve.allow_intermediates
    recieve.always_show_made_in = give.always_show_made_in or recieve.always_show_made_in
    recieve.show_amount_in_title = give.show_amount_in_title or recieve.show_amount_in_title
    recieve.always_show_products = give.always_show_products or recieve.always_show_products
    recieve.unlock_results = give.unlock_results or recieve.unlock_results
    recieve.main_product = give.main_product or recieve.main_product

    recieve.results = give.results or recieve.results
    recieve.result = give.result or recieve.result
    recieve.result_count = give.result_count or recieve.result_count 

    recieve.ingredients = give.ingredients or recieve.ingredients

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

local set_recipe = function(recipe, difficulty)

    if recipe.normal == false and difficulty == "normal" then
        if recipe.expensive then
            set_normal_or_expensive(recipe, recipe.expensive)
        end
        recipe.normal = nil
        recipe.expensive = nil
        recipe.hidden = true
    elseif recipe.expensive == false and difficulty == "expensive" then
        if recipe.normal then
            set_normal_or_expensive(recipe, recipe.normal)
        end
        recipe.normal = nil
        recipe.expensive = nil
        recipe.hidden = true
    elseif recipe.normal == nil and recipe.expensive == nil then
        if recipe.enabled == nil then
            recipe.enabled = true
        end
    elseif recipe.normal == nil then
        if recipe.expensive.enabled == nil then
            recipe.expensive.enabled = true
        end
        set_normal_or_expensive(recipe, recipe.expensive)
        recipe.expensive = nil
    elseif recipe.expensive == nil then
        if recipe.normal.enabled == nil then
            recipe.normal.enabled = true
        end
        set_normal_or_expensive(recipe, recipe.normal)
        recipe.normal = nil
    else
        if difficulty == "normal" then
            if recipe.normal.enabled == nil then
                recipe.normal.enabled = true
            end
            set_normal_or_expensive(recipe, recipe.normal)
            recipe.normal = nil
            recipe.expensive = nil
        end
        if difficulty == "expensive" then
            if recipe.expensive.enabled == nil then
                recipe.expensive.enabled = true
            end
            set_normal_or_expensive(recipe, recipe.expensive)
            recipe.normal = nil
            recipe.expensive = nil
        end
    end
    set_propper_results(recipe, recipe.name)
    set_propper_ingredients(recipe)

    local base_item = {}
    
    if recipe.main_product and recipe.main_product ~= "" then
        base_item = get_item_deepcopy(recipe.main_product)
    elseif recipe.result then
        base_item = get_item_deepcopy(recipe.result)
    elseif recipe.results and #recipe.results == 1 then
        if recipe.results[1].name then
            base_item = get_item_deepcopy(recipe.results[1].name)
        else
            base_item = get_item_deepcopy(recipe.results[1][1])
        end
    else
        base_item = get_item_deepcopy(recipe.name)
    end
    
    if recipe.icons or recipe.icon then
        recipe.icons = get_propper_icons(recipe)
    else
        if not base_item then
            log(serpent.line(recipe))
            log(serpent.line(base_item))
            error(recipe.name.." has no base item or fluid found to take icons from and the recipe does not have any on its own")
        end
        recipe.icons = get_propper_icons(base_item)
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

    recipe.category = recipe.category or "crafting"
    recipe.always_show_products = true
    recipe.main_product = nil
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
    set_recipe(recipe, settings.startup["randomtorio-normal-or-expensive"].value)
    if not recipe.enabled and not recipe_list[recipe.name] then
        recipe.hidden = true
    end
end