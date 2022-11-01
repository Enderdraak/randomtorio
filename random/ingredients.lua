local randomizing = function()
    return true
end

if not settings.startup["randomtorio-ingredients"].value then
    return randomizing
end

local ingredient_list
local get_ingredients_list = function(list, type)
    if ingredient_list then return ingredient_list end
    ingredient_list = {}
    for _, recipe_name in pairs(list) do
        local recipe = data.raw.recipe[recipe_name]
        ingredient_list[recipe.category] = ingredient_list[recipe.category] or {}
        ingredient_list[recipe.category][#ingredient_list[recipe.category]+1] = r_util.deepcopy(recipe[type].ingredients)
    end
    return ingredient_list
end

local random_ingredients = function(list, type)

    local ingredient_list = r_util.deepcopy(get_ingredients_list(list, type))

    for _, recipe_name in pairs(list) do
        local recipe = data.raw.recipe[recipe_name]
        local rand_num
        if #ingredient_list[recipe.category] == 1 then
            rand_num = 1
        else
            rand_num = r_util.random(#ingredient_list[recipe.category])
        end
        local ingredient = table.remove(ingredient_list[recipe.category], rand_num)
        recipe[type].ingredients = ingredient
    end
end

randomizing = function()
    random_ingredients(r_util.get_normal_recipe_list(), "normal")
    random_ingredients(r_util.get_expensive_recipe_list(), "expensive")
end

return randomizing