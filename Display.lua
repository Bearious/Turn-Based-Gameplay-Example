Display = GameObject:addState("Display")
local displayGroup = display.newGroup()
local updateGroup = display.newGroup()

function Display:enterState()
	self:loadGraphics()
	playMusic()
	runClock()
end

function Display:update()
	for n=updateGroup.numChildren,1,-1 do
		updateGroup[n]:removeSelf()
	end

	local turn = currQuest.turn 
	local text = currQuest:checkText()
	
	-- Text in the middle of the screen
	local midText = display.newText(text,0,H_/2,"alagard",25)
	midText.x = W_/2
	updateGroup:insert(midText)

	-- Enemy Hp
	for n=1,#currQuest.enemy do
		local hpText = display.newText(currQuest.enemy[n].hp,W_*(n*.25)+W_*.15,H_*.20,"alagard",10)
		updateGroup:insert(hpText)
	end
	-- Hero Hp
	for n=1,#heroArray do
		local hpText = display.newText(heroArray[n].hp,W_*(n*.25)-W_*.05,H_*.75,"alagard",10)
		updateGroup:insert(hpText)
	end

	if turn > #heroArray then 	
		-- Enemy Turn Arrow
		local arrow = display.newImageRect("UI/Arrow.png",30,16)
		arrow.x = W_*((turn-#heroArray)*.25)+W_*.05
		arrow.y = H_*.33
		arrow.yScale = -1
		updateGroup:insert(arrow)
	else 
		-- Hero Turn Arrow
		local arrow = display.newImageRect("UI/Arrow.png",30,16)
		arrow.x = W_*(turn*.25)-W_*.15
		arrow.y = H_*.67
		updateGroup:insert(arrow)
	end
end

function Display:loadGraphics()
	-- Draw Heroes
	for n=1,#heroArray do
		local currHero = display.newImageRect(heroArray[n].image,64,64)
		currHero.id = n
		currHero.x = W_*(n*.25)-W_
		currHero.y = H_*.83
		displayGroup:insert(currHero)
		transition.to(currHero,{time=2000,x=W_*(n*.25)-W_*.15})

		local atkText = display.newText(heroArray[n].atk,W_*(n*.25)-W_*.05,H_*.80,"alagard",10)
		local matkText = display.newText(heroArray[n].matk,W_*(n*.25)-W_*.05,H_*.85,"alagard",10)
		local accText = display.newText(heroArray[n].acc,W_*(n*.25)-W_*.05,H_*.90,"alagard",10)
		displayGroup:insert(atkText)
		displayGroup:insert(matkText)
		displayGroup:insert(accText)
	end

	-- Draw Enemies
	for n=1,#currQuest.enemy do
		local currEnemy = display.newImageRect(currQuest.enemy[n].image,64,64)
		currEnemy.id = n
		currEnemy.x = W_*(n*.25)+W_
		currEnemy.y = H_*.17
		currEnemy:addEventListener("touch",selectEnemy)
		transition.to(currEnemy,{time=2000,x=W_*(n*.25)+W_*.05})
		displayGroup:insert(currEnemy)

		local lvText = display.newText("Lv."..currQuest.enemy[n].lv,W_*(n*.25)+W_*.15,H_*.15,"alagard",10)	
		displayGroup:insert(lvText)
	end

	-- Draw Buttons
	for n=1,3 do
		local moveBtn = ui.newButton{
		defaultSrc = "UI/Btn.png",
		defaultX = 52,
		defaultY = 28,
		overSrc = "UI/Btn_P.png",
		overX = 52,
		overY = 28,
		onEvent = selectMove
		}
		moveBtn.id = n
		moveBtn.x = W_*.85
		moveBtn.y = H_*(.1*n) + H_*.6
		displayGroup:insert(moveBtn)
	end

	local attackText = display.newText("Attack",W_*.855,H_*.7,"alagard",15)
	local abilitiesText = display.newText("Abilities",W_*.85,H_*.8,"alagard",15)
	local passText = display.newText("Pass",W_*.8525,H_*.9,"alagard",15)
	displayGroup:insert(attackText)
	displayGroup:insert(abilitiesText)
	displayGroup:insert(passText)
end

function selectMove(e)
	if e.phase == "release" then
		local id = e.target.id
		if id == 1 then
			print("Attack Selected")
			currQuest:moveSelect("Attack")
		elseif id == 2 then
			print("No abilites available")
			currQuest:moveSelect("Ability")
		elseif id == 3 then
			currQuest:moveSelect("Pass")
		end
	end
end

function selectEnemy(e)
	if e.phase == "ended" then
		local id = e.target.id 
		currQuest:targetSelect(id)
	end
end
























































	-- local eTurn = (currTurn-#heroArray) - enemiesDead
	-- 	print(eTurn)
	-- 	if enemyArray[eTurn].hp <= 0 then -- Enemy has died, skip the turn
	-- 		print(enemyArray[eTurn].name .. " " .. currTurn .. " is dead")
	-- 		enemiesDead = currQuest:death("Enemy",eTurn)
	-- 		currTurn = currTurn + 1
	-- 	else