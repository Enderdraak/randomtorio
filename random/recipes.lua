



local get_propper_results = function(recipe)
    local results
    if recipe.results then
        results = recipe.results
    elseif recipe.result then
        if recipe.result_count then
            results = {{type = "item", name = recipe.result, amount = recipe.result_count}}
        else
            results = {{type = "item", name = recipe.result, amount = 1}}
        end
    else
        results = {{type = "item", name = recipe.name, amount = 1}}
    end
    return results
end

local ingredients = {}
local results = {}

for _, recipe in pairs(data.raw.recipe) do
    category = recipe.category or "crafting"
    ingredients[category] = ingredients[category] or {}
    results[category] = results[category] or {}

    if recipe.normal or recipe.expensive then
        log("normal/expensive   "..recipe.name)
        table.insert(ingredients[category], {normal = {}, expensive = {}, main_product = recipe.main_product})
        table.insert(results[category], {normal = {}, expensive = {}, main_product = recipe.main_product})
        if not recipe.normal then
            ingredients[category][#ingredients[category]].normal = recipe.expensive.ingredients
            results[category][#results[category]].normal = get_propper_results(recipe.expensive)
        else
            ingredients[category][#ingredients[category]].normal = recipe.normal.ingredients
            results[category][#results[category]].normal = get_propper_results(recipe.normal)
        end
        if not recipe.expensive then
            ingredients[category][#ingredients[category]].expensive = recipe.normal.ingredients
            results[category][#results[category]].expensive = get_propper_results(recipe.normal)
        else
            ingredients[category][#ingredients[category]].expensive = recipe.expensive.ingredients
            results[category][#results[category]].expensive = get_propper_results(recipe.expensive)
        end
    else
        log("base               "..recipe.name)
        table.insert(ingredients[category], recipe.ingredients)
        table.insert(results[category], {main_product = recipe.main_product})
        results[category][#results[category]].results = get_propper_results(recipe)
    end
end
log(serpent.line(ingredients))
log(serpent.line(results))
math.randomseed(1734728)
for _, recipe in pairs(data.raw.recipe) do

    category = recipe.category or "crafting"
    log(category.."   "..recipe.name)

    local base_item
    local base_type = "item"
    if recipe.main_product and not recipe.main_product == "" then
        base_item = recipe.main_product
    elseif recipe.result then
        base_item = recipe.result
    elseif recipe.results and #recipe.results == 1 then
        base_item = recipe.results[1].name
        base_type = recipe.results[1].type
    else
        base_item = recipe.name
    end
    if base_type == "fluid" then
        base_item = data.raw.fluid[base_item]
    else
        if data.raw.item[base_item] then
            base_item = data.raw.item[base_item]
        elseif data.raw["item-with-entity-data"][base_item] then
            base_item = data.raw["item-with-entity-data"][base_item]
        end
    end

    if not recipe.icon and not recipe.icons then
        recipe.icon = base_item.icon
        recipe.icon_size = base_item.icon_size
        recipe.icons = base_item.icons
    end
    if not recipe.order then
        recipe.order = base_item.order
    end
    if not recipe.subgroup then
        recipe.subgroup = base_item.subgroup
    end

    if #ingredients[category] == 1 then
        rand_ingredient = 1
    else
        rand_ingredient = math.random(1,#ingredients[category])
    end
    if #results[category] == 1 then
        rand_result = 1
    else
        rand_result = math.random(1,#results[category])
    end
    ingredient = table.remove(ingredients[category], rand_ingredient)
    result = table.remove(results[category], rand_result)


    if result.normal or ingredient.normal or recipe.normal or recipe.expensive then
        recipe.normal = recipe.normal or {}    
        recipe.expensive = recipe.expensive or {}        
        if not recipe.normal and recipe.expensive then
            recipe.normal.enabled = recipe.enabled or recipe.expensive.enabled
            recipe.normal.energy_required = recipe.energy_required or recipe.expensive.energy_required
            recipe.normal.emissions_multiplier = recipe.emissions_multiplier or recipe.expensive.emissions_multiplier
            recipe.normal.requester_paste_multiplier = recipe.requester_paste_multiplier or recipe.expensive.requester_paste_multiplier
            recipe.normal.overload_multiplier = recipe.overload_multiplier or recipe.expensive.overload_multiplier
            recipe.normal.allow_inserter_overload = recipe.allow_inserter_overload or recipe.expensive.allow_inserter_overload
            recipe.normal.hidden = recipe.hidden or recipe.expensive.hidden
            recipe.normal.hide_from_stats = recipe.hide_from_stats or recipe.expensive.hide_from_stats
            recipe.normal.hide_from_player_crafting = recipe.hide_from_player_crafting or recipe.expensive.hide_from_player_crafting
            recipe.normal.allow_decomposition = recipe.allow_decomposition or recipe.expensive.allow_decomposition
            recipe.normal.allow_as_intermediate = recipe.allow_as_intermediate or recipe.expensive.allow_as_intermediate
            recipe.normal.allow_intermediates = recipe.allow_intermediates or recipe.expensive.allow_intermediates
            recipe.normal.always_show_made_in = recipe.always_show_made_in or recipe.expensive.always_show_made_in
            recipe.normal.show_amount_in_title = recipe.show_amount_in_title or recipe.expensive.show_amount_in_title
            recipe.normal.always_show_products = recipe.always_show_products or recipe.expensive.always_show_products
            recipe.normal.unlock_results = recipe.unlock_results or recipe.expensive.unlock_results
            recipe.normal.main_product = recipe.main_product or recipe.expensive.main_product
        elseif not recipe.normal then
            recipe.normal.enabled = recipe.enabled
            recipe.normal.energy_required = recipe.energy_required
            recipe.normal.emissions_multiplier = recipe.emissions_multiplier
            recipe.normal.requester_paste_multiplier = recipe.requester_paste_multiplier
            recipe.normal.overload_multiplier = recipe.overload_multiplier
            recipe.normal.allow_inserter_overload = recipe.allow_inserter_overload
            recipe.normal.hidden = recipe.hidden
            recipe.normal.hide_from_stats = recipe.hide_from_stats
            recipe.normal.hide_from_player_crafting = recipe.hide_from_player_crafting
            recipe.normal.allow_decomposition = recipe.allow_decomposition
            recipe.normal.allow_as_intermediate = recipe.allow_as_intermediate
            recipe.normal.allow_intermediates = recipe.allow_intermediates
            recipe.normal.always_show_made_in = recipe.always_show_made_in
            recipe.normal.show_amount_in_title = recipe.show_amount_in_title
            recipe.normal.always_show_products = recipe.always_show_products
            recipe.normal.unlock_results = recipe.unlock_results
            recipe.normal.main_product = recipe.main_product
        end
        if not recipe.expensive and recipe.normal then
            recipe.expensive.enabled = recipe.enabled or recipe.normal.enabled
            recipe.expensive.energy_required = recipe.energy_required or recipe.normal.energy_required
            recipe.expensive.emissions_multiplier = recipe.emissions_multiplier or recipe.normal.emissions_multiplier
            recipe.expensive.requester_paste_multiplier = recipe.requester_paste_multiplier or recipe.normal.requester_paste_multiplier
            recipe.expensive.overload_multiplier = recipe.overload_multiplier or recipe.normal.overload_multiplier
            recipe.expensive.allow_inserter_overload = recipe.allow_inserter_overload or recipe.normal.allow_inserter_overload
            recipe.expensive.hidden = recipe.hidden or recipe.normal.hidden
            recipe.expensive.hide_from_stats = recipe.hide_from_stats or recipe.normal.hide_from_stats
            recipe.expensive.hide_from_player_crafting = recipe.hide_from_player_crafting or recipe.normal.hide_from_player_crafting
            recipe.expensive.allow_decomposition = recipe.allow_decomposition or recipe.normal.allow_decomposition
            recipe.expensive.allow_as_intermediate = recipe.allow_as_intermediate or recipe.normal.allow_as_intermediate
            recipe.expensive.allow_intermediates = recipe.allow_intermediates or recipe.normal.allow_intermediates
            recipe.expensive.always_show_made_in = recipe.always_show_made_in or recipe.normal.always_show_made_in
            recipe.expensive.show_amount_in_title = recipe.show_amount_in_title or recipe.normal.show_amount_in_title
            recipe.expensive.always_show_products = recipe.always_show_products or recipe.normal.always_show_products
            recipe.expensive.unlock_results = recipe.unlock_results or recipe.normal.unlock_results
            recipe.expensive.main_product = recipe.main_product or recipe.normal.main_product
        elseif not recipe.expensive then
            recipe.expensive.enabled = recipe.enabled
            recipe.expensive.energy_required = recipe.energy_required
            recipe.expensive.emissions_multiplier = recipe.emissions_multiplier
            recipe.expensive.requester_paste_multiplier = recipe.requester_paste_multiplier
            recipe.expensive.overload_multiplier = recipe.overload_multiplier
            recipe.expensive.allow_inserter_overload = recipe.allow_inserter_overload
            recipe.expensive.hidden = recipe.hidden
            recipe.expensive.hide_from_stats = recipe.hide_from_stats
            recipe.expensive.hide_from_player_crafting = recipe.hide_from_player_crafting
            recipe.expensive.allow_decomposition = recipe.allow_decomposition
            recipe.expensive.allow_as_intermediate = recipe.allow_as_intermediate
            recipe.expensive.allow_intermediates = recipe.allow_intermediates
            recipe.expensive.always_show_made_in = recipe.always_show_made_in
            recipe.expensive.show_amount_in_title = recipe.show_amount_in_title
            recipe.expensive.always_show_products = recipe.always_show_products
            recipe.expensive.unlock_results = recipe.unlock_results
            recipe.expensive.main_product = recipe.main_product
        end

        if ingredient.normal then
            recipe.normal.ingredients = ingredient.normal
            recipe.expensive.ingredients = ingredient.expensive
        else
            recipe.normal.ingredients = ingredient
            recipe.expensive.ingredients = ingredient
        end
        if result.normal then
            recipe.normal.results = result.normal
            recipe.expensive.results = result.expensive
            recipe.normal.main_product = result.main_product
            recipe.expensive.main_product = result.main_product
        else
            recipe.normal.results = result.results
            recipe.expensive.results = result.results
            recipe.main_product = result.main_product
        end

    else
        recipe.ingredients = ingredient
        recipe.results = result.results
        recipe.main_product = result.main_product
    end
    log(category.."\n"..rand_ingredient.."   "..serpent.line(ingredient).."\n"..rand_result.."   "..serpent.line(result))
end