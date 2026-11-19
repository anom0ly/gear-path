-- Loads an addon file the way the game does: with (addonName, ns) as its varargs.
local helper = {}

function helper.loadAddonFile(path, ns)
    ns = ns or {}
    local chunk = assert(loadfile(path))
    chunk("GearPath", ns)
    return ns
end

return helper
