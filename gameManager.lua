local composer = require("composer")
local enemy = require("enemy")
local soundTable = require("soundTable")
local loadsave = require("loadsave")

local gameManager = {}

local spawnEnemy, gameOver, randomizePosition, increaseDifficulty, 
	newSpawnTimer, newDifficultyTimer, randomizeType, destroyEnemies, changeBgm, updateScore, saveScore

local ENM_MIN_SPEED = 5
local ENM_MAX_SPEED = 20
local ENM_SPEED_STEP = 5

local DIFFICULTY_DELAY = 2000
local SPAWN_DELAY = 1500
local SPAWN_DELAY_STEP = 100
local MIN_SPAWN_DELAY = 300

local BGM_SWITCH_DELAY_VALUE = 500

function gameOver(gm)

	audio.play( soundTable.death )

	composer.removeScene( "gameScene" )
	composer.gotoScene( "gameover", {params = {currentScore = gm.score, bestScore = gm.bestScore}} )

	gameManager.destroy(gm)
end

function increaseDifficulty(event)

	local gm = event.source.params.gm

	changeBgm(gm)

	if gm.spawnDelay >= MIN_SPAWN_DELAY then
		timer.cancel(gm.spawnTimer)
		newSpawnTimer(gm)
		gm.spawnDelay = gm.spawnDelay - SPAWN_DELAY_STEP
	end

	gm.enmMinSpeed = gm.enmMinSpeed + ENM_SPEED_STEP
	gm.enmMaxSpeed = gm.enmMaxSpeed + ENM_SPEED_STEP


	print(gm.enmMinSpeed, gm.enmMaxSpeed, gm.spawnDelay)
end

function changeBgm(gm)

	if gm.bgmType == "slow" and gm.spawnDelay <= BGM_SWITCH_DELAY_VALUE then

		gm.bgmType = "fast"
		audio.stop(gm.bgm)
		gm.bgm = audio.play(audio.loadStream("audio/fast.wav"), {loops = -1})
	end
end

function newDifficultyTimer(gm)

	gm.difficultyTimer = timer.performWithDelay( DIFFICULTY_DELAY, increaseDifficulty, -1 )
	gm.difficultyTimer.params = {gm = gm}
end

function newSpawnTimer(gm)

	gm.spawnTimer = timer.performWithDelay( gm.spawnDelay, spawnEnemy, -1 )
	gm.spawnTimer.params = {gm = gm}
end



function destroyEnemies(gm)

	print("destroy enemies")
	print(gm.group.numChildren)

	for i = gm.enemyGroup.numChildren, 1, -1 do


		enemy.destroy(gm.enemyGroup[i])
		print("destroyed")
	end
end

function gameManager.new(sceneGroup)
	
	local gm = {}

	local scoreTable = loadsave.loadTable("score")

	if scoreTable then
		gm.bestScore = scoreTable.score or 0
	else
		gm.bestScore = 0
	end
 
	gm.bgm = audio.play(audio.loadStream("audio/slow.wav"), {loops = -1})


	gm.isPaused = false

	gm.enmMinSpeed = ENM_MIN_SPEED
	gm.enmMaxSpeed = ENM_MAX_SPEED
	gm.spawnDelay = SPAWN_DELAY

	gm.bgmType = "slow"

	gm.zoneR = 45

	gm.group = display.newGroup( )
	sceneGroup:insert(gm.group)

	local bg = display.newImageRect( gm.group, "images/terrain_dungeon.png", 1000, 500)

	bg.x, bg.y = 0.5*display.contentWidth, 0.5*display.contentHeight 

	local ritualImg = display.newImageRect( gm.group, "images/ritual_symbol.png", 2 * gm.zoneR, 2 * gm.zoneR )
	ritualImg.x = 0.5 * display.contentWidth
	ritualImg.y = 0.5 * display.contentHeight

	gm.enemyGroup = display.newGroup( )
	sceneGroup:insert(gm.enemyGroup )

	newDifficultyTimer(gm)
	newSpawnTimer(gm)

	gm.gameOver = gameOver
	gm.updateScore = updateScore

	gm.score = 0

	gm.scoreTextObj = display.newText( sceneGroup, "0", 0.5 * display.contentWidth, 20)

	return gm
end


function saveScore(gm)

	if gm.score > gm.bestScore then

		gm.bestScore = gm.score

		loadsave.saveTable({score = gm.score}, "score")
	end
end

function gameManager.destroy(gm)

	saveScore(gm)

	audio.stop(gm.bgm)
	gm.bgm = nil
	destroyEnemies(gm)
	timer.cancel( gm.spawnTimer )
	timer.cancel( gm.difficultyTimer )
	gm.group:removeSelf( )
end

function gameManager.pause(gm)

	gm.isPaused = true
	timer.pause( gm.difficultyTimer )
	timer.pause( gm.spawnTimer)
end

function gameManager.resume(gm)

	gm.isPaused = false
	timer.resume( gm.difficultyTimer )
	timer.resume( gm.spawnTimer )
end

function updateScore(gm, score)

	gm.score = gm.score + score

	gm.scoreTextObj.text = gm.score
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