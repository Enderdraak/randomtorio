data:extend({
    {
        type = "int-setting",
        name = "randomtorio-randomseed",
        setting_type = "startup",
        default_value = 925,
        order = "a-a"
    },
    {
        type = "int-setting",
        name = "randomtorio-check-amount",
        setting_type = "startup",
        min_value = 1,
        default_value = 100,
        order = "b-a"
    },
    {
        type = "int-setting",
        name = "randomtorio-log-seed-gap",
        setting_type = "startup",
        min_value = 1,
        default_value = 1,
        order = "b-b"
    },
    {
        type = "bool-setting",
        name = "randomtorio-keep-on-looking",
        setting_type = "startup",
        default_value = false,
        order = "b-c"
    },
    {
        type = "string-setting",
        name = "randomtorio-normal-or-expensive",
        setting_type = "startup",
        allowed_values = {"normal", "expensive"},
        default_value = "normal",
        order = "c-d"
    },
    {
        type = "bool-setting",
        name = "randomtorio-keep-icon-with-result",
        setting_type = "startup",
        default_value = true,
        order = "c-e"
    },
    {
        type = "string-setting",
        name = "randomtorio-display-costs",
        setting_type = "startup",
        default_value = "[item=transport-belt][item=fast-transport-belt][item=express-transport-belt][item=underground-belt][item=fast-underground-belt][item=express-underground-belt][item=splitter][item=fast-splitter][item=express-splitter][item=inserter][item=long-handed-inserter][item=fast-inserter][item=filter-inserter][item=stack-inserter][item=stack-filter-inserter]",
        order = "d-a"
    },
    {
        type = "bool-setting",
        name = "randomtorio-force-restriction",
        setting_type = "startup",
        default_value = false,
        order = "d-b"
    },
    {
        type = "string-setting",
        name = "randomtorio-do-not-use",
        setting_type = "startup",
        default_value = "[item=wood][item=raw-fish]",
        order = "d-c"
    },
    {
        type = "string-setting",
        name = "randomtorio-start-with",
        setting_type = "startup",
        default_value = "{[item=stone-furnace][item=steel-furnace][item=electric-furnace]}{[item=burner-mining-drill][item=electric-mining-drill]}{[item=transport-belt][item=fast-transport-belt][item=express-transport-belt]}",
        order = "d-c"
    },
})