type p = {
	Test: (player: Player) -> new,
}

type new = {
	P: (player: Player) -> (),
}
local p = {}

local new = {}

new.__index = new

function p.Test(player: Player): new
	local self = setmetatable({}, new)
	return self
end

function new.P(player: Player): () end

return p :: p
