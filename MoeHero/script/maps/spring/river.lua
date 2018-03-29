
	local region = require 'types.region'
	local rect = require 'types.rect'

	local self = {}
	
	--注册河流
	function self.init_river()
		local river = region.create()

		for i = 1, 99 do
			local rct = rect.j_rect(('waves%02d'):format(i))
			if not rct then
				break
			end

			river = river + rct
		end

		return river
	end

	function self.main()

		self.river = self.init_river()
		
		return self
	end

	return self.main()