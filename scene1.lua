------------------------------------------------------------------------
-- Cena principal do jogo top-down com movimento físico e objetos interativos
------------------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()
local dpad = require( "dpad" )

-- Configurações globais do jogo
local config = {
    worldWidth = 3000,
    worldHeight = 3000,
    spawnMargin = 120,
    moveSpeed = 200,
    bushCount = 100,
    boxCount = 20,
    boxScale = 4
}
-- Tabela para armazenar os efeitos sonoros da pasta Song
local boxSounds = {
    audio.loadSound( "Song/michael1.mp3" ),
	audio.loadSound( "Song/michael2.mp3" ),
	audio.loadSound( "Song/michael3.mp3" ),
	audio.loadSound( "Song/michael4.mp3" ),
	audio.loadSound( "Song/michael5.mp3" ),

}

-- Carregar a música de fundo (loadStream é melhor para arquivos longos, economiza RAM)
local backgroundMusic = audio.loadStream( "Song/958530_Medieval.mp3" )

-- [NOVO] Importa e inicia o motor de física
local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 ) -- Jogo top-down não tem gravidade
-- physics.setDrawMode( "hybrid" ) -- Descomenta isto para ver as áreas de colisão

local gamePad = dpad.newDPad( 450, "pad.png", 0.8, false )

display.setDefault( "background", 0.18, 0.62, 0.32 )

local screenW = display.contentWidth
local screenH = display.contentHeight
local halfW = display.contentWidth * 0.5
local halfH = display.contentHeight * 0.5

local linkSprite = nil
local worldGroup = nil
local isPaused = false -- Controla a pausa do jogo
local keysPressed = { w = false, a = false, s = false, d = false } -- Teclas WASD pressionadas

function scene:create( event )

	local sceneGroup = self.view

	-- Inicializamos o worldGroup e o colocamos dentro da cena principal.
	worldGroup = display.newGroup()
	sceneGroup:insert( worldGroup )

	------------------------------------------------------------------------
	-- CONFIGURAÇÃO DO MUNDO E SPAWN
	------------------------------------------------------------------------

	local spawnBounds = {
		minX = halfW - config.worldWidth * 0.7 + config.spawnMargin,
		maxX = halfW + config.worldWidth * 0.7 - config.spawnMargin,
		minY = halfH - config.worldHeight * 0.7 + config.spawnMargin,
		maxY = halfH + config.worldHeight * 0.7 - config.spawnMargin,
	}

	-- Função auxiliar para calcular distância mínima baseada na quantidade
	local function getMinSpawnDistance(count)
		-- Reduzido para valores realistas para evitar loop infinito
		if count <= 50 then
			return 150
		elseif count <= 100 then
			return 100
		else
			return 50
		end
	end

	-- Função auxiliar para encontrar posição sem overlap
	local function findSpawnPosition(existing, radius, bounds, separation)
		for attempt = 1, 500 do
			local x = math.random(bounds.minX, bounds.maxX)
			local y = math.random(bounds.minY, bounds.maxY)
			local ok = true
			for _, item in ipairs(existing) do
				local dx = x - item.x
				local dy = y - item.y
				local minDist = item.radius + radius + separation
				if dx * dx + dy * dy < minDist * minDist then
					ok = false
					break
				end
			end
			if ok then
				return x, y
			end
		end
		-- Fallback: retorna posição aleatória (pode haver overlap mínimo)
		return math.random(bounds.minX, bounds.maxX), math.random(bounds.minY, bounds.maxY)
	end

	-- Função genérica para spawn de objetos
	local spawnedObjects = {}
	local function spawnObjects(count, radiusFunc, createFunc, separation)
		for i = 1, count do
			local radius = radiusFunc()
			local x, y = findSpawnPosition(spawnedObjects, radius, spawnBounds, separation)
			local obj = createFunc(x, y, radius)
			table.insert(spawnedObjects, { x = x, y = y, radius = radius })
		end
	end

	-- 1. Chão gigante com degradê contínuo
	local ground = display.newRect( worldGroup, halfW, halfH, config.worldWidth, config.worldHeight )
	ground.fill = { type = "gradient", color1 = { 0.18, 0.62, 0.32 }, color2 = { 0.06, 0.24, 0.10 }, direction = "down" }

	-- 2. Arbustos com física
	local bushSeparation = getMinSpawnDistance(config.bushCount)
	spawnObjects(config.bushCount,
		function() return math.random(20, 60) end, -- Raio aleatório
		function(x, y, radius)
			local bush = display.newCircle(worldGroup, x, y, radius)
			local greenTone = math.random(40, 80) / 100
			bush:setFillColor(0.1, greenTone, 0.1)
			physics.addBody(bush, "static", { radius = radius, bounce = 0 })
			return bush
		end,
		bushSeparation
	)

	-- 3. Objetos (caixas)
	local imageSheet = "Objetos.png"
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
		if event.phase == "began" then

			
			local other = event.other
			if other.isBox then

				local randomIdx = math.random( 1, #boxSounds ) -- Sorteia um número entre 1 e o total de sons
            	audio.play( boxSounds[randomIdx] )
				if other.hasItem then
					isPaused = true
					keysPressed.w = false
					keysPressed.a = false
					keysPressed.s = false
					keysPressed.d = false
					gamePad.isMoving = false
					gamePad.isMovingUp = false
					gamePad.isMovingDown = false
					gamePad.isMovingLeft = false
					gamePad.isMovingRight = false
					native.showAlert("Item Recebido!", "Você ganhou um item!", {"OK"}, function()
						other:setSequence("delete")
						other:play()
						isPaused = false
					end)
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
		function() return 28 * config.boxScale end, -- Tamanho da caixa
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

	------------------------------------------------------------------------
	-- CONFIGURANDO O PERSONAGEM
	------------------------------------------------------------------------

	local linkSpriteSheet = graphics.newImageSheet( "michael2_2.png", { width = 55, height = 143, numFrames = 42, border = 0 } )
	local linkSpriteSheet_IDLE = graphics.newImageSheet( "michael_IDE.png", { width = 55, height = 143, numFrames = 96, border = 0 } )
	
	local linkAnimationSequences =
	{
		
		{ name="idle_down", sheet=linkSpriteSheet_IDLE, start=1, count=14, time=2000, loopCount=1, loopDirection="bounce" },
		{ name="idle_left", sheet=linkSpriteSheet_IDLE, start=17, count=12, time=2000, loopCount=1, loopDirection="bounce" },
		{ name="idle_up", sheet=linkSpriteSheet_IDLE, start=33, count=12, time=2000, loopCount=1, loopDirection="bounce" },
		{ name="idle_right", sheet=linkSpriteSheet_IDLE, start=49, count=11, time=2000, loopCount=1, loopDirection="bounce" },

		{ name="walk_down", sheet=linkSpriteSheet, start=29, count=7, time=1000, loopCount=0 },
		{ name="walk_left", sheet=linkSpriteSheet, start=36, count=7, time=1000, loopCount=0 },
		{ name="walk_up", sheet=linkSpriteSheet, start=1, count=7, time=1000, loopCount=0 },
		{ name="walk_right", sheet=linkSpriteSheet, start=15, count=7, time=1000, loopCount=0 }
	}
	
	linkSprite = display.newSprite( linkSpriteSheet_IDLE, linkAnimationSequences )
	linkSprite.x = halfW
	linkSprite.y = halfH
	linkSprite.xScale = 1.5
	linkSprite.yScale = 1.5
	linkSprite:setSequence( "idle_down" )
	linkSprite:play()

	linkSprite.walkingDirection = nil

	-- Insere o Link no worldGroup (fica por cima dos arbustos)
	worldGroup:insert( linkSprite )

	-- [NOVO] Adiciona o corpo físico ao Link (dynamic)
	physics.addBody( linkSprite, "dynamic", { radius = 30, bounce = 0 } )
	linkSprite.isFixedRotation = true -- Impede o Link de rodar ao bater

	-- Adiciona listener de colisão ao Link
	linkSprite:addEventListener("collision", onCollision)

end


-- [NOVO] Função para atualizar o movimento do Link a cada frame
function onEnterFrame( event )

	-- Se o jogo está pausado, não atualiza movimento
	if isPaused then
		linkSprite:setLinearVelocity(0, 0)
		return
	end

	-- Função auxiliar para atualizar movimento e animação
	local function updateMovement()
		local vx, vy = 0, 0
		local direction = nil
		
		-- Verifica inputs (D-Pad ou WASD)
		if gamePad.isMovingUp or keysPressed.w then vy = -config.moveSpeed; direction = "up" end
		if gamePad.isMovingDown or keysPressed.s then vy = config.moveSpeed; direction = "down" end
		if gamePad.isMovingLeft or keysPressed.a then vx = -config.moveSpeed; direction = "left" end
		if gamePad.isMovingRight or keysPressed.d then vx = config.moveSpeed; direction = "right" end
		
		-- Aplica movimento e animação
		linkSprite:setLinearVelocity(vx, vy)
		if direction and linkSprite.walkingDirection ~= direction then
			linkSprite.walkingDirection = direction
			linkSprite:setSequence("walk_" .. direction)
			linkSprite:play()
		elseif not direction and linkSprite.walkingDirection then
			linkSprite:setSequence("idle_" .. linkSprite.walkingDirection)
			linkSprite:play()
			linkSprite.walkingDirection = nil
		end
	end

	updateMovement()

	-- LÓGICA DA CÂMARA (Atualiza o mapa consoante a nova posição física do Link)
	if worldGroup then
		worldGroup.x = halfW - linkSprite.x
		worldGroup.y = halfH - linkSprite.y
	end

end


local function onKeyEvent( event )
	local keyName = event.keyName
	local phase = event.phase

	-- Mapeamento de teclas para simplificar
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
			-- Verifica se ainda há movimento
			local hasMovement = keysPressed.w or keysPressed.a or keysPressed.s or keysPressed.d or
				gamePad.isMovingUp or gamePad.isMovingDown or gamePad.isMovingLeft or gamePad.isMovingRight
			if not hasMovement then
				gamePad.isMoving = false
			end
		end
	end

	return false
end

-- Inicializa/remov listeners de eventos
function scene:show( event )
	local phase = event.phase
	
    if phase == "did" then
        -- channel = 1 reserva um canal fixo para a música
        -- loops = -1 faz a música repetir para sempre
        audio.play( backgroundMusic, { channel = 1, loops = -1, fadein = 2000 } )
        
        Runtime:addEventListener( "enterFrame", onEnterFrame )
        Runtime:addEventListener( "key", onKeyEvent )
    end
end


function scene:hide( event )
	local phase = event.phase
	if phase == "will" then
		audio.stop( 1 ) -- Para a música de fundo no canal 1
		Runtime:removeEventListener( "enterFrame", onEnterFrame )
		Runtime:removeEventListener( "key", onKeyEvent )
	end
end

------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )

------------------------------------------------------------------------

return scene