

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

for _, recipe in pairs(data.raw.recipe) do
    