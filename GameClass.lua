GameObject = class("GameObject",StatefulObject)

function GameObject:initialize()
	super.initialize(self)
end

function runClock()
	if Game ~= nil then
		if Game:isInState("Display") then
			Game:update()
		end
	end
	timer.performWithDelay(100,runClock)
end

function playMusic()
	audio.play(myMusic,{onComplete=playMusic})
end





