r_util = require("util/randomutil")

require("util/unify_all_recipes")

possible = require("util/check_possible")

local randomizing = {
    ingredients = require("random/ingredients"),
    results = require("random/results"),
}


if settings.startup["randomtorio-first-randomizer"].value then
    
    r_util.startup()
    
    for _, func in pairs(randomizing) do
        func()
    end

    local seed = settings.startup["randomtorio-randomseed"].value

    if settings.startup["randomtorio-check-possible"].value ~= "disable" then
        local count = 0
        while not possible() and count < settings.startup["randomtorio-check-amount"].value do
            count = count + 1
            seed = seed + 1
            r_util.seed(seed)
            for _, func in pairs(randomizing) do
                func()
            end
        end
    end

    log(possible(true))
    if possible() then
        log("\n------------------------------------------------------------------------\n                        This is the working seed:\n                        "..seed.."\n------------------------------------------------------------------------")
    else
        log("\n------------------------------------------------------------------------\n              This is the current seed, it is not completeble:\n                        "..seed.."\n------------------------------------------------------------------------")
    end
end