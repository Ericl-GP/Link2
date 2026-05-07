local composer = require( "composer" )
local scene = composer.newScene()
local dpad = require( "scripts.dpad" )
local physics = require( "physics" )

local config = {
    moveSpeed = 200,
    enemySpeed = 100
}

local gamePad
local linkSprite = nil
local worldGroup = nil
local isPaused = false
local keysPressed = { w = false, a = false, s = false, d = false }

function scene:create( event )
    local sceneGroup = self.view
    physics.start()
    physics.setGravity( 0, 0 )

    worldGroup = display.newGroup()
    sceneGroup:insert( worldGroup )

    gamePad = dpad.newDPad( 450, "assets/pad.png", 0.8, false )

    local halfW = display.contentWidth * 0.5
    local halfH = display.contentHeight * 0.5

    -- 1. Chão
    local ground = display.newRect( worldGroup, halfW, halfH, 3000, 3000 )
    ground.fill = { type = "gradient", color1 = { 0.1, 0.4, 0.2 }, color2 = { 0.05, 0.15, 0.08 }, direction = "down" }

    -- 2. A Cabana de Vitória (Agora usando a imagem correta casa.png)
    local cabana = display.newImageRect( worldGroup, "assets/PNG/casa.png", 140, 130 )
    cabana.x = halfW
    cabana.y = halfH - 800
    cabana.isCabin = true
    physics.addBody( cabana, "static", { isSensor = true, radius = 65 } )

    -- 3. Árvores Detalhadas (SpriteSheet configurado)
    local treeOptions = { width = 64, height = 80, numFrames = 117 }
    local treeSheet = graphics.newImageSheet( "assets/Tiled_files/Trees_animation.png", treeOptions )
    
    for i = 1, 30 do
        local arvore = display.newSprite( worldGroup, treeSheet, { { name="default", start=1, count=9 } } )
        arvore.x = halfW + math.random(-1000, 1000)
        arvore.y = halfH + math.random(-500, 1000)
        arvore.xScale = 1.5
        arvore.yScale = 1.5
        -- Escolhe um frame aleatório da primeira linha (1 a 9)
        arvore:setFrame( math.random(1, 9) ) 
        physics.addBody( arvore, "static", { radius = 30 } )
    end

    -- 4. Inimigos (SpriteSheet configurado)
    local enemyOptions = { width = 118, height = 128, numFrames = 80, border = 1 }
    local enemySheet = graphics.newImageSheet( "assets/link.png", enemyOptions )
    local enemyAnims = { 
        -- Ajuste os frames (start/count) caso a animação de andar não seja logo a primeira
        { name="walk", start=1, count=10, time=800, loopCount=0 } 
    }

    for i = 1, 10 do
        local inimigo = display.newSprite( worldGroup, enemySheet, enemyAnims )
        inimigo.x = halfW + math.random(-800, 800)
        inimigo.y = halfH + math.random(-800, 800)
        inimigo.xScale = 0.8
        inimigo.yScale = 0.8
        inimigo.isEnemy = true
        inimigo:setSequence("walk")
        inimigo:play()

        physics.addBody( inimigo, "dynamic", { radius = 25, bounce = 1 } )
        inimigo.isFixedRotation = true
        
        -- Faz o inimigo se mover em uma direção aleatória
        local moveX = math.random(-1, 1) * config.enemySpeed
        local moveY = math.random(-1, 1) * config.enemySpeed
        inimigo:setLinearVelocity( moveX, moveY )
    end

    -- 5. Personagem Principal
    local linkSpriteSheet = graphics.newImageSheet( "assets/michael2_2.png", { width = 55, height = 143, numFrames = 42, border = 0 } )
    local linkSpriteSheet_IDLE = graphics.newImageSheet( "assets/michael_IDE.png", { width = 55, height = 143, numFrames = 96, border = 0 } )
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
    
    linkSprite = display.newSprite( worldGroup, linkSpriteSheet_IDLE, linkAnimationSequences )
    linkSprite.x = halfW
    linkSprite.y = halfH + 500
    linkSprite.xScale = 1.5
    linkSprite.yScale = 1.5
    linkSprite:setSequence( "idle_down" )
    linkSprite:play()
    
    physics.addBody( linkSprite, "dynamic", { radius = 30, bounce = 0 } )
    linkSprite.isFixedRotation = true

    -- Lógica de Colisão da Fase 2
    local function onCollision(event)
        if event.phase == "began" then
            local other = event.other

            if other.isEnemy then
                isPaused = true
                linkSprite:setLinearVelocity(0, 0)
                native.showAlert("Capturado!", "Um inimigo te pegou. Voltando ao início...", {"OK"}, function()
                    isPaused = false
                    composer.removeScene("scripts.scene1")
                    composer.gotoScene("scripts.scene1", { effect = "slideRight", time = 500 })
                end)

            elseif other.isCabin then
                isPaused = true
                linkSprite:setLinearVelocity(0, 0)
                native.showAlert("VITÓRIA!", "Você chegou à cabana em segurança!", {"Menu Principal"}, function()
                    isPaused = false
                    composer.removeScene("scripts.scene2")
                    composer.gotoScene("scripts.menu", { effect = "crossFade", time = 500 })
                end)
            end
        end
    end

    linkSprite:addEventListener("collision", onCollision)
end

-- Função de movimento 
local function onEnterFrame( event )
    if isPaused then return end

    local vx, vy = 0, 0
    if gamePad.isMovingUp or keysPressed.w then vy = -config.moveSpeed end
    if gamePad.isMovingDown or keysPressed.s then vy = config.moveSpeed end
    if gamePad.isMovingLeft or keysPressed.a then vx = -config.moveSpeed end
    if gamePad.isMovingRight or keysPressed.d then vx = config.moveSpeed end
    
  
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
    if worldGroup then
        worldGroup.x = display.contentWidth * 0.5 - linkSprite.x
        worldGroup.y = display.contentHeight * 0.5 - linkSprite.y
    end
end

local function onKeyEvent( event )
    local keyName = event.keyName
    if event.phase == "down" then
        if keysPressed[keyName] ~= nil then keysPressed[keyName] = true end
    elseif event.phase == "up" then
        if keysPressed[keyName] ~= nil then keysPressed[keyName] = false end
    end
    return false
end

function scene:show( event )
    if event.phase == "did" then
        isPaused = false
        Runtime:addEventListener( "enterFrame", onEnterFrame )
        Runtime:addEventListener( "key", onKeyEvent )
    end
end

function scene:hide( event )
    if event.phase == "will" then
        Runtime:removeEventListener( "enterFrame", onEnterFrame )
        Runtime:removeEventListener( "key", onKeyEvent )
    end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )

return scene