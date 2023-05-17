local randomizing = function()
    return true
end

if not settings.startup["randomtorio-results"].value then
    return randomizing
end

local result_list = {}
local get_results_list = function(list, type)
    if result_list[type] then return result_list[type] end
    result_list[type] = {}
    for _, recipe_name in pairs(list) do
        local recipe = data.raw.recipe[recipe_name]
        result_list[type][recipe.category] = result_list[type][recipe.category] or {}
        result_list[type][recipe.category][#result_list[type][recipe.category]+1] = r_util.deepcopy(recipe[type].results)
    end
    return result_list[type]
end

local random_results = function(list, type)

    local result_list = r_util.deepcopy(get_results_list(list, type))

    for _, recipe_name in pairs(list) do
        local recipe = data.raw.recipe[recipe_name]
        local result = table.remove(result_list[recipe.category], r_util.random(#result_list[recipe.category]))
        recipe[type].results = result
        recipe[type].always_show_products = true
        recipe[type].show_amount_in_title = false
    end
end

randomizing = function()
    random_results(r_util.get_normal_recipe_list(), "normal")
    random_results(r_util.get_expensive_recipe_list(), "expensive")
end

return randomizing