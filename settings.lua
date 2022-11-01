data:extend({
    {
        type = "bool-setting",
        name = "randomtorio-results",
        setting_type = "startup",
        default_value = false
    },
    {
        type = "bool-setting",
        name = "randomtorio-ingredients",
        setting_type = "startup",
        default_value = true
    },
    {
        type = "string-setting",
        name = "randomtorio-check-possible",
        setting_type = "startup",
        allowed_values = {"disable", "normal-only", "expensive-only", "normal-and-expensive"},
        default_value = "disable",
    },
    {
        type = "int-setting",
        name = "randomtorio-randomseed",
        setting_type = "startup",
        default_value = 47605
    },
    {
        type = "int-setting",
        name = "randomtorio-check-amount",
        setting_type = "startup",
        min_value = 1,
        default_value = 100000
    },
})