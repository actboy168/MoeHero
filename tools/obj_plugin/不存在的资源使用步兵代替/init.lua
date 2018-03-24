local w2l = require 'w3x2lni'

local ignore = {
    [".mdx"] = true,
    [".mdl"] = true,
    ["model\\dummy.mdl"] = true,
}

for id, u in pairs(w2l.slk.unit) do
    if u.file and not ignore[u.file:lower()] and not w2l:file_load('resource', u.file) then
        u.file = [[units\human\Footman\Footman.mdx]]
    end
    if u.art and not w2l:file_load('resource', u.art) then
        u.art = [[ReplaceableTextures\CommandButtons\BTNFootman.blp]]
    end
end
