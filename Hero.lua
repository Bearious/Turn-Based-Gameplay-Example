Hero = class("Hero", StatefulObject)
heroArray = {}

function Hero:initialize(params)
	super.initialize(self)
	local image, name, hp, atk, matk, acc

	self.id = params.id

	-- Hero List Params
	self.image = params.image
	self.name = params.name
	self.hp = params.hp
	self.atk = params.atk
	self.matk = params.matk
	self.acc = params.acc

	-- Extra Params
	self.hate = 0
	self.dead = false
end