local enemy = require("enemy")

local gameManager = {}

local spawnEnemy, gameOver, randomizePosition, increaseDifficulty, newSpawnTimer, newDifficultyTimer, randomizeType

local ENM_MIN_SPEED = 5
local ENM_MAX_SPEED = 50
local ENM_SPEED_STEP = 5

local DIFFICULTY_DELAY = 10000
local SPAWN_DELAY = 3000
local SPAWN_DELAY_STEP = 100
local MIN_SPAWN_DELAY = 500

function gameOver(gm)

	print("gameOver")
end

function increaseDifficulty(event)

	local gm = event.source.params.gm

	gm.spawnDelay = gm.spawnDelay - SPAWN_DELAY_STEP

	if gm.spawnDelay < MIN_SPAWN_DELAY then
		gm.spawnDelay = MIN_SPAWN_DELAY
	end

	gm.enmMinSpeed = gm.enmMinSpeed + ENM_SPEED_STEP
	gm.enmMaxSpeed = gm.enmMaxSpeed + ENM_SPEED_STEP

	timer.cancel(gm.spawnTimer)
	newSpawnTimer(gm)

	print(gm.enmMinSpeed, gm.enmMaxSpeed, gm.spawnDelay)
end

function newDifficultyTimer(gm)

	gm.difficultyTimer = timer.performWithDelay( DIFFICULTY_DELAY, increaseDifficulty, -1 )
	gm.difficultyTimer.params = {gm = gm}
end

function newSpawnTimer(gm)

	gm.spawnTimer = timer.performWithDelay( gm.spawnDelay, spawnEnemy, -1 )
	gm.spawnTimer.params = {gm = gm}
end


function gameManager.new()
	
	gm = {}

	gm.enmMinSpeed = ENM_MIN_SPEED
	gm.enmMaxSpeed = ENM_MAX_SPEED
	gm.spawnDelay = SPAWN_DELAY

	gm.zoneR = 50

	gm.group = display.newGroup( )

	display.newCircle( gm.group, 0.5*display.contentWidth, 0.5*display.contentHeight, gm.zoneR )

	newDifficultyTimer(gm)
	newSpawnTimer(gm)

	gm.gameOver = gameOver

	return gm
end

function spawnEnemy(event)

	local gm = event.source.params.gm

	local x, y = randomizePosition()

	enemy.new(gm, x, y, 0.1 * math.random( ENM_MIN_SPEED, ENM_MAX_SPEED ), math.random(1,3))
end

function randomizePosition()

	local dice = math.random()

	-- left edge
	if  dice < 0.25 then

		return -100, math.random(0, display.contentHeight)

	-- top edge
	elseif dice >= 0.25 and dice < 0.5 then

		return math.random(0, display.contentWidth), -100

	-- right edge
	elseif dice >= 0.5 and dice < 0.75 then

		return display.contentWidth + 100, math.random(0, display.contentHeight)

	-- bottom edge
	else

		return math.random(0, display.contentWidth), display.contentHeight + 100

	end
end


return gameManager