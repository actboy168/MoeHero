local w2l = require 'w3x2lni'

if w2l:file_load('resource', 'model/dummy.mdl') then
    return
end

local ignore = {
    [".mdx"] = true,
    [".mdl"] = true,
    ["model\\dummy.mdl"] = true,
}

for id, u in pairs(w2l.slk.unit) do
    if u.file and not ignore[u.file:lower()] then
        u.file = [[units\human\Footman\Footman.mdx]]
    end
    if u.art then
        u.art = [[ReplaceableTextures\CommandButtons\BTNFootman.blp]]
    end
end
