local randomizing = function()
    return true
end

if not settings.startup["randomtorio-results"].value then
    return randomizing
end

local result_list
local get_results_list = function(list, type)
    if result_list then return result_list end
    result_list = {}
    for _, recipe_name in pairs(list) do
        local recipe = data.raw.recipe[recipe_name]
        result_list[recipe.category] = result_list[recipe.category] or {}
        result_list[recipe.category][#result_list[recipe.category]+1] = r_util.deepcopy(recipe[type].results)
    end
    return result_list
end

local random_results = function(list, type)

    local result_list = r_util.deepcopy(get_results_list(list, type))

    for _, recipe_name in pairs(list) do
        local recipe = data.raw.recipe[recipe_name]
        local rand_num
        if #result_list[recipe.category] == 1 then
            rand_num = 1
        else
            rand_num = r_util.random(#result_list[recipe.category])
        end
        local result = table.remove(result_list[recipe.category], rand_num)
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