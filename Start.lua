Start = GameObject:addState("Start")
local startGroup = display.newGroup()
local currDifficulty = 1
local text = {}
text[1] = "Easy"
text[2] = "Medium"
text[3] = "Hard"
text[4] = "Very Hard"
text[5] = "Impossibru!"

function Start:enterState()
	self:loadGraphics()
end

function Start:exitState()
	for n=startGroup.numChildren,1,-1 do
		startGroup[n]:removeSelf()
	end
end	

function Start:loadGraphics()
	-- Hero Buttons
	for n=1,3 do
		local heroBtn = ui.newButton{
		defaultSrc = "UI/Btn.png",
		defaultX = 52,
		defaultY = 28,
		overSrc = "UI/Btn_P.png",
		overX = 52,
		overY = 28,
		onEvent = selectHero
		}
		heroBtn.id = n
		heroBtn.x = W_*(n*.15)+W_*.2
		heroBtn.y = H_*.25
		startGroup:insert(heroBtn)
	end

	local selectHeroText = display.newText("Select Heroes",0,H_*.14,"alagard",25)
	selectHeroText.x = W_*.5
	startGroup:insert(selectHeroText)

	local warText = display.newText("Warrior",W_*.3525,H_*.25,"alagard",15)
	local rogText = display.newText("Rogue",W_*.5025,H_*.25,"alagard",15)
	local magText = display.newText("Mage",W_*.655,H_*.25,"alagard",15)
	startGroup:insert(warText)
	startGroup:insert(rogText)
	startGroup:insert(magText)

	-- Difficulty Buttons
	for n=1,5 do
		local diffBtn = ui.newButton{
		defaultSrc = "UI/Btn.png",
		defaultX = 52,
		defaultY = 28,
		overSrc = "UI/Btn_P.png",
		overX = 52,
		overY = 28,
		onEvent = selectDifficulty
		}
		diffBtn.id = n
		diffBtn.x = W_*(n*.15)+W_*.045
		diffBtn.y = H_*.55
		startGroup:insert(diffBtn)
	end

	local eText = display.newText("Easy",W_*.1975,H_*.55,"alagard",15)
	local mText = display.newText("Medium",W_*.3475,H_*.55,"alagard",15)
	local hText = display.newText("Hard",W_*.4975,H_*.55,"alagard",15)
	local vhText = display.newText("V Hard",W_*.6475,H_*.55,"alagard",15)
	local iText = display.newText("Impossibru",W_*.80,H_*.55,"alagard",15)
	startGroup:insert(eText)
	startGroup:insert(mText)
	startGroup:insert(hText)
	startGroup:insert(vhText)
	startGroup:insert(iText)

	local selectDiffText = display.newText("Select Difficulty",0,H_*.44,"alagard",25)
	selectDiffText.x = W_*.5
	startGroup:insert(selectDiffText)

	-- Start button
	local startBtn = ui.newButton{
	defaultSrc = "UI/Btn.png",
	defaultX = 78,
	defaultY = 42,
	overSrc = "UI/Btn_P.png",
	overX = 78,
	overY = 42,
	onEvent = startQuest
	}
	startBtn.x = W_*.5
	startBtn.y = H_*.8
	startGroup:insert(startBtn)

	local startText = display.newText("Start",0,H_*.8,"alagard",25)
	startText.x = W_*.505
	startGroup:insert(startText)
end

function selectHero(e)
	if e.phase == "release" then -- Ui buttons use "release" instead of ended
		local id = e.target.id -- Set event id to the btn id
		if #heroArray ~= 3 then	
			print("Creating " .. heroList[id].name)
			params = heroList[id]
			params.id = #heroArray + 1 -- Add to the array size
			heroArray[params.id] = Hero:new(params) -- Create a new hero (I made heroArray seperate from Quest for purposes beyond this example)
		else
			print("You already have 3 heroes")
		end
	end
end

function selectDifficulty(e)
	if e.phase == "release" then
		local id = e.target.id		
		currDifficulty = id	-- Set difficulty 
		print(text[currDifficulty] .. " Selected")
	end
end

function startQuest(e)
	if e.phase == "release" then
		if #heroArray >= 1 then
			params = questList[1] -- Set the params
			params.difficulty = currDifficulty
			params.hero = {}
			for n=1,#heroArray do
				params.hero[n] = heroArray[n] -- Create a new instance of the heroArray for this specific quest
			end
			print("Starting Quest with " .. #heroArray .. " hero(es) on " ..  text[currDifficulty])
			currQuest = Quest:new(params) -- Start a new quest
			Game:gotoState("Display") -- Go the Display state
		else
			print("Select a hero first")
		end
	end
end


