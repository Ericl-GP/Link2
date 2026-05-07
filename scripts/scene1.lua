------------------------------------------------------------------------
-- Cena principal do jogo top-down com movimento físico e objetos interativos
------------------------------------------------------------------------

local composer = require( "composer" )
local playerModule = require( "scripts.player" )
local scene = composer.newScene()
local dpad = require( "scripts.dpad" )
local itensColetados = 0 -- Contador de itens coletados
composer.removeScene("scripts.scene2")
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
	audio.loadSound( "Song/michael55.mp3" ),

}

-- Carregar a música de fundo (loadStream é melhor para arquivos longos, economiza RAM)
local backgroundMusic = audio.loadStream( "Song/958530_Medieval.mp3" )

-- [NOVO] Importa e inicia o motor de física
local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 ) -- Jogo top-down não tem gravidade
-- physics.setDrawMode( "hybrid" ) -- Descomenta isto para ver as áreas de colisão

local gamePad = dpad.newDPad( 450, "assets/pad.png", 0.8, false )

display.setDefault( "background", 0.18, 0.62, 0.32 )

local screenW = display.contentWidth
local screenH = display.contentHeight
local halfW = display.contentWidth * 0.5
local halfH = display.contentHeight * 0.5

local linkSprite = nil
local worldGroup = nil
local isPaused = false -- Controla a pausa do jogo
local keysPressed = { w = false, a = false, s = false, d = false } -- Teclas WASD pressionadas

local function zSort( group )
    local kids = {}
    -- Pega todos os objetos, exceto os que marcarmos como "isBackground"
    for i=1, group.numChildren do
        if not group[i].isBackground then
            table.insert(kids, group[i])
        end
    end
    -- Ordena com base no eixo Y (quem está mais abaixo na tela fica à frente)
    table.sort( kids, function(a,b) return (a.y or 0) < (b.y or 0) end )
    -- Volta a colocá-los no grupo na ordem correta
    for i=1, #kids do
        kids[i]:toFront()
    end
end

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
    ground.isBackground = true -- Marca como fundo para não ser considerado no zSort

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
		if event.phase == "began" then
			local other = event.other
			if other.isBox then

				local randomIdx = math.random( 1, #boxSounds )
            	audio.play( boxSounds[randomIdx] )
				
				if other.hasItem then
					itensColetados = itensColetados + 1
					other:setSequence("delete")
					other:play()

					-- [CORREÇÃO] Pausa o mundo inteiro e limpa as teclas "presas"
					isPaused = true
					physics.pause()
					keysPressed = { w = false, a = false, s = false, d = false }
					gamePad.isMoving = false; gamePad.isMovingUp = false; gamePad.isMovingDown = false; gamePad.isMovingLeft = false; gamePad.isMovingRight = false
					linkSprite:setLinearVelocity(0, 0)
					linkSprite:setSequence("idle_" .. (linkSprite.walkingDirection or "down"))
					linkSprite:play()

					if itensColetados >= 1 then
						native.showAlert("Portal Aberto!", "Você encontrou 5 itens! A próxima área foi liberada.", {"Ir para Fase 2"}, function()
							isPaused = false
							physics.start() -- Despausa o mundo ao fechar o alerta
							composer.removeScene("scripts.scene1")
							composer.gotoScene("scripts.scene2", { effect = "crossFade", time = 500 })
						end)
					else
						native.showAlert("Item Recebido!", "Você encontrou um item! Faltam " .. (5 - itensColetados) .. ".", {"OK"}, function()
							isPaused = false
							physics.start() -- Despausa o mundo ao fechar o alerta
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

	linkSprite = playerModule.new( worldGroup, halfW, halfH )
    linkSprite:addEventListener("collision", onCollision)
end


-- [NOVO] Função para atualizar o movimento do Link a cada frame
local function onEnterFrame( event )

	-- 1. Usa o módulo do jogador para o mover e animar:
	playerModule.updateMovement( linkSprite, gamePad, keysPressed, config.moveSpeed, isPaused )

	-- 2. LÓGICA DA CÂMARA (Atualiza o mapa consoante a nova posição física do Link)
	if worldGroup and worldGroup.x then
		worldGroup.x = display.contentWidth * 0.5 - linkSprite.x
		worldGroup.y = display.contentHeight * 0.5 - linkSprite.y
        
        -- 3. CHAMA O Z-SORT PARA ORDENAR A PROFUNDIDADE
        zSort( worldGroup )
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
		itensColetados = 0 -- Reseta o contador de itens coletados ao mostrar a cena
        -- channel = 1 reserva um canal fixo para a música
        -- loops = -1 faz a música repetir para sempre
		audio.setVolume( 0.4, { channel = 1 } )
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