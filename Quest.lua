Quest = class("Quest", StatefulObject)

function Quest:initialize(params)
	super.initialize(self)
	local turn, gameOver, attackReady

	self.turn = 1 -- Represents total turns (#self.hero+#self.enemy)
	self.gameOver = false
	self.attackReady = false

	-- Quest List Params
	self.name = params.name
	self.enemyLv = params.enemyLv
	self.enemyAmnt = params.enemyAmnt 
	self.enemyType = params.enemyType
	self.typeBonus = params.typeBonus

	self.difficulty = params.difficulty

	-- Quest Heroes
	self.hero = {}
	self.heroesAlive = {}
	self.hero = params.hero
	for n=1,#self.hero do
		table.insert(self.heroesAlive,self.hero[n].id) 
	end

	-- Quest Enemies
	self.enemy = {}
	self.enemiesAlive = {}

	self:setDifficulty()
end

function Quest:setDifficulty() -- This could be done quite a lot better, but idk how I want the system to work
	local bonus = self.difficulty-1

	-- Insert more values (that correspond with enemy types) to created weighted random spawning
	for n=1,bonus do
		for m=1,#self.typeBonus do
			table.insert(self.enemyType,self.typeBonus[m])
		end
	end

	self.enemyLv[1] = self.enemyLv[1] + bonus -- Chanege min/max enemy lv based on difficulty
	self.enemyLv[2] = self.enemyLv[2] + bonus

	if self.difficulty == 2 then -- Change amount of potential enemies based on difficulty
		self.enemyAmnt[2] = self.enemyAmnt[2] + 1
	elseif self.difficulty == 3 then 
		self.enemyAmnt[1] = self.enemyAmnt[1] + 1
		self.enemyAmnt[2] = self.enemyAmnt[2] + 2
	elseif self.difficulty > 3 then 
		self.enemyAmnt[1] = self.enemyAmnt[1] + 2
		self.enemyAmnt[2] = self.enemyAmnt[2] + 2
	end
	self:spawnEnemies()
end

function Quest:spawnEnemies()
	local currEnemyAmnt = math.random(self.enemyAmnt[1],self.enemyAmnt[2]) -- Set enemy amount

	for n=1,currEnemyAmnt do
		local currEnemyLv = math.random(self.enemyLv[1],self.enemyLv[2]) -- Set enemy lv
		local currEnemyType = self.enemyType[math.random(#self.enemyType)] -- Select enemy types

		params = enemyList[currEnemyType]
		params.lv = currEnemyLv
		self.enemiesAlive[n] = n
		self.enemy[n] = Enemy:new(params) -- Create new enemies
	end
end

function Quest:moveSelect(type)
	if self.turn <= #self.hero then -- Check if it's the heroes turn
		if type == "Attack" then
			self.attackReady = true -- Set attack ready for target select phase
		end
		if type == "Ability" then -- Currently does nothing
		end
		if type == "Pass" then
			self:checkTurn() -- Check turn increases the turn by 1, essentially skipping the heroes turn
		end
	else
		print("It's not your turn")
	end
end

function Quest:targetSelect(target)
	local dmg = self.hero[self.turn].atk + self.hero[self.turn].matk

	if self.enemy[target].dead == false then -- Check if enemy is dead
		if self.attackReady == true then -- Check if attack has been selected
			self.attackReady = false -- Reset attack check
			self.enemy[target].hp = self.enemy[target].hp - dmg -- Apply dmg to enemy
			self.hero[self.turn].hate = self.hero[self.turn].hate + dmg -- Add hate to hero
			print(self.hero[self.turn].name.." "..self.turn.." dealing "..dmg.." dmg to "..self.enemy[target].name.." "..target.."\n"..self.hero[self.turn].name.." "..target.." hate is now "..self.hero[self.turn].hate)
			self:checkDeath(target) -- Will eventually need to play anim here instead
		else
			print("Select a move first")
		end
	else
		print("This enemy is dead")
	end
end

function Quest:enemyTargetSelect()
	local turn = self.turn - #self.hero -- Since self.turn represents the total turns, we must subtract the # of self.hero to get the current enemy
	local dmg = self.enemy[turn].atk + self.enemy[turn].matk
	local target = self:checkHate()
	
	self.hero[target].hp = self.hero[target].hp - dmg -- Apply dmg to hero
	self.hero[target].hate = self.hero[target].hate - dmg -- Remove hate from hero attacked
	if self.hero[target].hate < 0 then self.hero[target].hate = 0 end -- Make sure hero hate can't go below 0
	print(self.enemy[turn].name.." "..turn.." dealing "..dmg.." dmg to "..self.hero[target].name.." "..target.."\n"..self.hero[target].name.." "..target.." hate is now "..self.hero[target].hate)
	self:checkDeath(target)
end

function Quest:checkHate() -- Check to see which hero the enemies should attack
	local max = 0
	-- This system is far from perfect, but I implimented it quick to show a proof of concept
	for n=1,#self.hero do
		if self.hero[n].dead == false then -- If the hero isn't dead
			if self.hero[n].hate > max then -- If hero[n] hate is greater than max
				max = self.hero[n].hate -- Set new max
				target = n -- Set the hero has the target
			elseif self.hero[n].hate == max then -- This is what messes up if an incorrect target is chosen
				target = self.heroesAlive[math.random(#self.heroesAlive)] -- If hero 1 and 3 have equal hate it could still random 2
			end
		end
	end	
	return target
end

function Quest:checkDeath(target) -- Check to see if a hero/enemy has died
	if self.turn <= #self.hero then
		if self.enemy[target].hp <= 0 then  -- Hero has killed an enemy
			self.enemy[target].dead = true
			table.remove(self.enemiesAlive,table.indexOf(self.enemiesAlive,target)) -- Remove enemy from the enemiesAlive array
			--print(self.enemy[target].name.." had died")
			print(#self.enemiesAlive.." enemies left")
		end
	else
		if self.hero[target].hp <= 0 then -- Enemy has killed a hero
			self.hero[target].dead = true
			table.remove(self.heroesAlive,table.indexOf(self.heroesAlive,target)) -- Remove hero from the heroesALive array
			--print(self.hero[target].name.." "..target.." has died")
			print(#self.heroesAlive.." heroes left")
		end
	end
	if #self.enemiesAlive == 0 or #self.heroesAlive == 0 then -- All heroes or enemies have died
		self.gameOver = true
	end
	self:checkTurn()
end

function Quest:checkTurn()
	if self.gameOver == false then -- Make sure game isn't over
		self.turn = self.turn + 1 -- Increase turn
		-- Switch between hero/enemy phase
		if self.turn > #self.hero+#self.enemy then -- Reset back to hero
			self.turn = 1
		end
		if self.turn <= #self.hero then -- Check if it's the heroes turn 
			if self.hero[self.turn].dead == true then -- Check to see if the hero is dead
				print("Skipped "..self.hero[self.turn].name)
				self:checkTurn() -- Call check turn again to skip the dead heroes turn
				return
			end			
		else
			if self.enemy[self.turn-#self.hero].dead == true then -- Skip enemy turn if dead
				print("Skipped "..self.enemy[self.turn-#self.hero].name)
				self:checkTurn()
				return
			end
		end
		-- Start enemy phase
		if self.turn > #self.hero then 
			timer.performWithDelay(1500,stupidDelayTimerWontWorkWithClasses) -- Delay timer so enemy attacks take 1.5 seconds
		end
	else
		print("Game over")
	end
	self:checkText()
end

function Quest:checkText() -- Change text based on the games status
	if self.gameOver == false then
		if self.turn <= #self.hero then
			if self.attackReady == false then
				text = "Select Move"
			else
				text = "Select Target"
			end
		else
			text = "Enemy Turn"
		end
	else
		if #self.enemiesAlive == 0 then
			text = "You Win"
		else
			text = "You Lose"
		end

	end
	return text
end

function stupidDelayTimerWontWorkWithClasses()
	currQuest:enemyTargetSelect() 
end
