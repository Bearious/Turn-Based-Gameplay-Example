Enemy = class("Enemy",StatefulObject)

function Enemy:initialize(params)
	super.initialize(self)
	local image, name, hp, atk, matk, eva

	-- Enemy List Params
	self.image = params.image
	self.name = params.name
	self.hp = params.hp
	self.atk = params.atk
	self.matk = params.matk
	self.eva = params.eva

	-- Extra Params
	self.lv = params.lv
	self.dead = false

	self:addStats()
end

function Enemy:addStats() -- Add stats based on the enemies lv
	local lvBns = self.lv-1
	self.hp = self.hp + (10*lvBns)
	self.atk = self.atk + (1*lvBns)
	self.matk = self.matk + (1*lvBns)
	self.eva = self.eva + (1*lvBns)
end