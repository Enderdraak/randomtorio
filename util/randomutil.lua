require("util/randomlua")
util = require("util")

local lib = {}

lib.startup = function()
    random_gen = mwc(0)
    random_gen:randomseed(settings.startup["randomtorio-randomseed"].value)
end

lib.random = function(arg1, arg2)
    if arg2 then
        local rand = random_gen:random()
        local random_num = math.floor(arg1 + ((arg2 - arg1) * rand))
        if random_num > arg2 then
            random_num = arg1
        end
        return random_num
    elseif arg1 then
        if arg1 == 1 then
            return 1
        else
            local rand = random_gen:random()
            local random_num = math.floor(arg1 * rand) + 1
            if random_num > arg1 then
                random_num = 1
            end
            return random_num
        end
    else
        return random_gen:random()
    end
end

lib.seed = function(num)
    random_gen:randomseed(num)
end

lib.deepcopy = function(thing)
    return util.table.deepcopy(thing)
end

local normal_recipe_list
lib.get_normal_recipe_list = function()
    if normal_recipe_list then return normal_recipe_list end
    normal_recipe_list = {}
    for _, recipe in pairs(data.raw.recipe) do
        if recipe.normal and recipe.normal.enabled then
            table.insert(normal_recipe_list, recipe.name)
        end
    end
    for _, tech in pairs(data.raw.technology) do
        if tech.effects then
            for _, effect in pairs(tech.effects) do
                if effect.type == "unlock-recipe" then
                    if data.raw.recipe[effect.recipe].normal then
                        table.insert(normal_recipe_list, effect.recipe)
                    end
                end
            end
        end
    end
    return normal_recipe_list
end

local expensive_recipe_list
lib.get_expensive_recipe_list = function()
    if expensive_recipe_list then return expensive_recipe_list end
    expensive_recipe_list = {}
    for _, recipe in pairs(data.raw.recipe) do
        if recipe.expensive and recipe.expensive.enabled then
            table.insert(expensive_recipe_list, recipe.name)
        end
    end
    for _, tech in pairs(data.raw.technology) do
        if tech.effects then
            for _, effect in pairs(tech.effects) do
                if effect.type == "unlock-recipe" then
                    if data.raw.recipe[effect.recipe].expensive then
                        table.insert(expensive_recipe_list, effect.recipe)
                    end
                end
            end
        end
    end
    return expensive_recipe_list
end

local list_of_item_places = {}
for _, list in pairs({defines.prototypes.item,defines.prototypes.fluid}) do
    for place, _ in pairs(list) do
        if not list_of_item_places[place] then
            list_of_item_places[place] = true
        end
    end
end

lib.recursive_check_if_item_exists = {}
lib.recursive_check_if_item_exists = function(lst)
    if type(lst) == "string" then
        for place, _ in pairs(list_of_item_places) do
            if data.raw[place][lst] then
                return true, lst
            end
        end
        return false, lst
    end

    local useful = false
    local return_list = {}
    for index, list in pairs(lst) do
        local item, list = lib.recursive_check_if_item_exists(list)
        if item then table.insert(return_list, list) end
        useful = useful or item
    end

    return useful, return_list
end

lib.recursive_make_list_with_depth = {}
lib.recursive_make_list_with_depth = function(array, allow_depth, first)
    local return_array = {}
    for index, str in pairs(array) do
        local found = string.match(str, "[%{%}]")
        if found and allow_depth then
            if found == "{" and first then
                array[index] = string.gsub(str, "{", " ", 1)
                table.insert(return_array, lib.recursive_make_list_with_depth(array, allow_depth, false))
            end
            if found == "}" and not first then
                array[index] = string.gsub(str, "}", " ", 1)
                return return_array
            end
        else
            table.insert(return_array, str)
            array[index] = nil
        end
    end
    return return_array
end

lib.str_to_list = function(str, allow_depth)
    local items = {}
    for match in string.gmatch(str, "([^%[%]%=]+)") do
      table.insert(items, match)
    end

    items = lib.recursive_make_list_with_depth(items, allow_depth, true)
    _, items = lib.recursive_check_if_item_exists(items)

    return items
end

local setting_store = {}
lib.settings_extractor = function(str)
    if setting_store[str] then return r_util.deepcopy(setting_store[str]) end
    setting_store[str] = {}
    if settings.startup[str].value then
        setting_store[str] = lib.str_to_list(settings.startup[str].value, str == "randomtorio-start-with")
    else
        setting_store[str] = false
    end
    return setting_store[str]
end

return lib