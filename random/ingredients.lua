local randomizing = function()
    return true
end

if not settings.startup["randomtorio-ingredients"].value then
    return randomizing
end

local ingredient_list = {}
local get_ingredients_list = function(list, type)
    if ingredient_list[type] then return ingredient_list[type] end
    ingredient_list[type] = {}
    for _, recipe_name in pairs(list) do
        local recipe = data.raw.recipe[recipe_name]
        ingredient_list[type][recipe.category] = ingredient_list[type][recipe.category] or {}
        ingredient_list[type][recipe.category][#ingredient_list[type][recipe.category]+1] = r_util.deepcopy(recipe[type].ingredients)
    end
    return ingredient_list[type]
end

local random_ingredients = function(list, type)

    local ingredient_list = r_util.deepcopy(get_ingredients_list(list, type))
    log(serpent.line(ingredient_list))
    for _, recipe_name in pairs(list) do
        local recipe = data.raw.recipe[recipe_name]
        local ingredient = table.remove(ingredient_list[recipe.category], r_util.random(#ingredient_list[recipe.category]))
        recipe[type].ingredients = ingredient
    end
end

randomizing = function()
    random_ingredients(r_util.get_normal_recipe_list(), "normal")
    random_ingredients(r_util.get_expensive_recipe_list(), "expensive")
end

return randomizing