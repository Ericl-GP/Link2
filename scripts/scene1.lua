------------------------------------------------------------------------
-- Cena principal do jogo top-down com movimento físico e objetos interativos
------------------------------------------------------------------------

local composer = require( "composer" )
local playerModule = require( "scripts.player" )
local scene = composer.newScene()
local dpad = require( "scripts.dpad" )

local itensColetados = 0 

local config = {
    worldWidth = 3000,
    worldHeight = 3000,
    spawnMargin = 120,
    moveSpeed = 200,
    bushCount = 100,
    boxCount = 20,
    boxScale = 4
}

local boxSounds = {
    audio.loadSound( "Song/michael1.mp3" ),
	audio.loadSound( "Song/michael2.mp3" ),
	audio.loadSound( "Song/michael3.mp3" ),
	audio.loadSound( "Song/michael4.mp3" ),
	audio.loadSound( "Song/michael5.mp3" ),
	audio.loadSound( "Song/michael55.mp3" ),
}

local backgroundMusic = audio.loadStream( "Song/958530_Medieval.mp3" )

local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )

local gamePad = dpad.newDPad( 450, "assets/pad.png", 0.8, false )

display.setDefault( "background", 0.18, 0.62, 0.32 )

local halfW = display.contentWidth * 0.5
local halfH = display.contentHeight * 0.5

local linkSprite = nil
local worldGroup = nil
local isPaused = false 
local keysPressed = { w = false, a = false, s = false, d = false }

local function zSort( group )
    local kids = {}
    for i=1, group.numChildren do
        if not group[i].isBackground then
            table.insert(kids, group[i])
        end
    end
    table.sort( kids, function(a,b) return (a.y or 0) < (b.y or 0) end )
    for i=1, #kids do
        kids[i]:toFront()
    end
end

function scene:create( event )
    -- [CORREÇÃO] Gera aleatoriedade real a cada inicialização
    math.randomseed(os.time())
    
    -- [CORREÇÃO] Limpa a cena 2 apenas quando a cena 1 for carregada
    composer.removeScene("scripts.scene2")

    itensColetados = 0
    isPaused = false

	local sceneGroup = self.view
	worldGroup = display.newGroup()
	sceneGroup:insert( worldGroup )

	local spawnBounds = {
		minX = halfW - config.worldWidth * 0.7 + config.spawnMargin,
		maxX = halfW + config.worldWidth * 0.7 - config.spawnMargin,
		minY = halfH - config.worldHeight * 0.7 + config.spawnMargin,
		maxY = halfH + config.worldHeight * 0.7 - config.spawnMargin,
	}

	local function getMinSpawnDistance(count)
		if count <= 50 then return 150
		elseif count <= 100 then return 100
		else return 50 end
	end

	local function findSpawnPosition(existing, radius, bounds, separation)
		for attempt = 1, 500 do
			local x = math.random(bounds.minX, bounds.maxX)
			local y = math.random(bounds.minY, bounds.maxY)
			local ok = true
            
            -- [CORREÇÃO] Cria uma ZONA SEGURA ao redor do jogador (halfW, halfH)
            local distToPlayerX = x - halfW
            local distToPlayerY = y - halfH
            if (distToPlayerX * distToPlayerX) + (distToPlayerY * distToPlayerY) < 200 * 200 then
                ok = false
            end

			if ok then
				for _, item in ipairs(existing) do
					local dx = x - item.x
					local dy = y - item.y
					local minDist = item.radius + radius + separation
					if dx * dx + dy * dy < minDist * minDist then
						ok = false
						break
					end
				end
			end
			if ok then return x, y end
		end
		return math.random(bounds.minX, bounds.maxX), math.random(bounds.minY, bounds.maxY)
	end

	local spawnedObjects = {}
	local function spawnObjects(count, radiusFunc, createFunc, separation)
		for i = 1, count do
			local radius = radiusFunc()
			local x, y = findSpawnPosition(spawnedObjects, radius, spawnBounds, separation)
			local obj = createFunc(x, y, radius)
			table.insert(spawnedObjects, { x = x, y = y, radius = radius })
		end
	end

	local ground = display.newRect( worldGroup, halfW, halfH, config.worldWidth, config.worldHeight )
    ground.fill = { type = "gradient", color1 = { 0.18, 0.62, 0.32 }, color2 = { 0.06, 0.24, 0.10 }, direction = "down" }
    ground.isBackground = true

	local bushSeparation = getMinSpawnDistance(config.bushCount)
	spawnObjects(config.bushCount,
		function() return math.random(20, 60) end,
		function(x, y, radius)
			local bush = display.newCircle(worldGroup, x, y, radius)
			local greenTone = math.random(40, 80) / 100
			bush:setFillColor(0.1, greenTone, 0.1)
			physics.addBody(bush, "static", { radius = radius, bounce = 0 })
			return bush
		end,
		bushSeparation
	)

	local imageSheet = "assets/Objetos.png"
	local caixa = graphics.newImageSheet(imageSheet, { width = 63, height = 63, numFrames = 84, border = 0 })
	local caixaAnimationSequences = {
		{ name="idle", sheet=caixa, start=15, count=3, time=800, loopCount=0, loopDirection="bounce" },
		{ name="delete", sheet=caixa, start=25, count=4, time=500, loopCount=1 },
	}

	local function onSpriteEvent(event)
		if event.phase == "ended" and event.target.sequence == "delete" then
			display.remove(event.target)
		end
	end

	local function onCollision(event)
        -- [CORREÇÃO] Bloqueia alertas duplos
        if isPaused then return end 

		if event.phase == "began" then
			local other = event.other
			if other.isBox then
				local randomIdx = math.random( 1, #boxSounds )
            	audio.play( boxSounds[randomIdx] )
				
				if other.hasItem then
					itensColetados = itensColetados + 1
					other:setSequence("delete")
					other:play()

					isPaused = true
					physics.pause()
					keysPressed = { w = false, a = false, s = false, d = false }
					gamePad.isMoving = false; gamePad.isMovingUp = false; gamePad.isMovingDown = false; gamePad.isMovingLeft = false; gamePad.isMovingRight = false
					linkSprite:setLinearVelocity(0, 0)
					linkSprite:setSequence("idle_" .. (linkSprite.walkingDirection or "down"))
					linkSprite:play()

                    -- Se estava testando com 1, mude para 5
					if itensColetados >= 5 then
						native.showAlert("Portal Aberto!", "Você encontrou 5 itens! A próxima área foi liberada.", {"Ir para Fase 2"}, function()
							isPaused = false
							physics.start()
							composer.gotoScene("scripts.scene2", { effect = "crossFade", time = 500 })
						end)
					else
						native.showAlert("Item Recebido!", "Você encontrou um item! Faltam " .. (5 - itensColetados) .. ".", {"OK"}, function()
							isPaused = false
							physics.start()
						end)
					end
				else
					other:setSequence("delete")
					other:play()
				end
			end
		end
	end

	local boxSeparation = getMinSpawnDistance(config.boxCount)
	local boxId = 0
	spawnObjects(config.boxCount,
		function() return 28 * config.boxScale end,
		function(x, y, radius)
			boxId = boxId + 1
			local objeto = display.newSprite(worldGroup, caixa, caixaAnimationSequences)
			objeto.x = x
			objeto.y = y
			objeto.xScale = config.boxScale
			objeto.yScale = config.boxScale
			objeto:setSequence("idle")
			objeto:play()
			objeto.id = boxId
			objeto.hasItem = math.random(2) == 1
			objeto.isBox = true
			objeto:addEventListener("sprite", onSpriteEvent)
			physics.addBody(objeto, "static", { box = { halfWidth = radius * 0.5, halfHeight = radius * 0.5 }, isSensor = true })
			return objeto
		end,
		boxSeparation
	)

	linkSprite = playerModule.new( worldGroup, halfW, halfH )
    linkSprite:addEventListener("collision", onCollision)
end

local function onEnterFrame( event )
	playerModule.updateMovement( linkSprite, gamePad, keysPressed, config.moveSpeed, isPaused )
	if worldGroup and worldGroup.x then
		worldGroup.x = display.contentWidth * 0.5 - linkSprite.x
		worldGroup.y = display.contentHeight * 0.5 - linkSprite.y
        zSort( worldGroup )
	end
end

local function onKeyEvent( event )
	local keyName = event.keyName
	local phase = event.phase
	local keyMap = {
		w = "w", a = "a", s = "s", d = "d",
		up = "up", down = "down", left = "left", right = "right"
	}
	if phase == "down" then
		if keyMap[keyName] then
			if keyName == "w" or keyName == "a" or keyName == "s" or keyName == "d" then
				keysPressed[keyName] = true
			else
				gamePad["isMoving" .. keyName:gsub("^%l", string.upper)] = true
				gamePad.isMoving = true
			end
		end
	elseif phase == "up" then
		if keyMap[keyName] then
			if keyName == "w" or keyName == "a" or keyName == "s" or keyName == "d" then
				keysPressed[keyName] = false
			else
				gamePad["isMoving" .. keyName:gsub("^%l", string.upper)] = false
			end
			local hasMovement = keysPressed.w or keysPressed.a or keysPressed.s or keysPressed.d or
				gamePad.isMovingUp or gamePad.isMovingDown or gamePad.isMovingLeft or gamePad.isMovingRight
			if not hasMovement then
				gamePad.isMoving = false
			end
		end
	end
	return false
end

function scene:show( event )
	local phase = event.phase
    if phase == "did" then
		audio.setVolume( 0.4, { channel = 1 } )
        audio.play( backgroundMusic, { channel = 1, loops = -1, fadein = 2000 } )
        Runtime:addEventListener( "enterFrame", onEnterFrame )
        Runtime:addEventListener( "key", onKeyEvent )
    end
end

function scene:hide( event )
	local phase = event.phase
	if phase == "will" then
		audio.stop( 1 )
		Runtime:removeEventListener( "enterFrame", onEnterFrame )
		Runtime:removeEventListener( "key", onKeyEvent )
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )

return scene