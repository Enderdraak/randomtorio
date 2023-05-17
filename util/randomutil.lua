require("util/randomlua")
util = require("util")

local lib = {}

lib.startup = function()
    random_gen = mwc(0)
    random_gen:randomseed(settings.startup["randomtorio-randomseed"].value)
    log("startup seed: "..settings.startup["randomtorio-randomseed"].value)
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
    log("seed: "..num)
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

return lib