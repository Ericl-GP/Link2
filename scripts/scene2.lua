local composer = require( "composer" )
local scene = composer.newScene()
local dpad = require( "scripts.dpad" )
local physics = require( "physics" )
local playerModule = require( "scripts.player" ) 
local backgroundMusic = audio.loadStream( "Song/SEGA-Michael-Jacksons.mp3" )
audio.setVolume( 0.4, { channel = 1 } )
audio.play( backgroundMusic, { channel = 1, loops = -1, fadein = 2000 } )

local config = {
    moveSpeed = 200,
    enemySpeed = 100
}

local gamePad
local linkSprite = nil
local worldGroup = nil
local isPaused = false
local keysPressed = { w = false, a = false, s = false, d = false }
local inimigosList = {} 

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
    math.randomseed(os.time())
    
    -- [CORREÇÃO] Limpa a Cena 1 aqui de forma segura
    composer.removeScene("scripts.scene1")

    isPaused = false
    local sceneGroup = self.view
    physics.start()
    physics.setGravity( 0, 0 )

    worldGroup = display.newGroup()
    sceneGroup:insert( worldGroup )
    inimigosList = {}

    gamePad = dpad.newDPad( 450, "assets/pad.png", 0.8, false )

    local halfW = display.contentWidth * 0.5
    local halfH = display.contentHeight * 0.5

    local ground = display.newRect( worldGroup, halfW, halfH, 3000, 3000 )
    ground.fill = { type = "gradient", color1 = { 0.1, 0.4, 0.2 }, color2 = { 0.05, 0.15, 0.08 }, direction = "down" }
    ground.isBackground = true 

    local cabana = display.newImageRect( worldGroup, "assets/PNG/casa.png", 140, 130 )
    cabana.x = halfW
    cabana.y = halfH - 800
    cabana.isCabin = true
    physics.addBody( cabana, "static", { isSensor = true, radius = 65 } )

    local treeOptions = { width = 64, height = 80, numFrames = 117 }
    local treeSheet = graphics.newImageSheet( "assets/Tiled_files/Trees_animation.png", treeOptions )
    
    for i = 1, 30 do
        local arvoreFrame = math.random(1, 9) 
        local arvore = display.newSprite( worldGroup, treeSheet, { { name="default", start=arvoreFrame, count=1 } } )
        arvore.x = halfW + math.random(-1000, 1000)
        arvore.y = halfH + math.random(-500, 1000)
        arvore.xScale = 1.5; arvore.yScale = 1.5
        physics.addBody( arvore, "static", { box = { halfWidth = 15, halfHeight = 10, x = 0, y = 30 } } )
    end

    local enemyOptions = { width = 118, height = 128, numFrames = 80, border = 1 }
    local enemySheet = graphics.newImageSheet( "assets/link.png", enemyOptions )
    local enemyAnims = {
        { name="idle_down", sheet=enemySheet, start=1, count=3, time=800, loopCount=1, loopDirection="bounce" },
        { name="idle_left", sheet=enemySheet, start=11, count=3, time=800, loopCount=1, loopDirection="bounce" },
        { name="idle_up", sheet=enemySheet, start=21, count=1, time=800, loopCount=1, loopDirection="bounce" },
        { name="idle_right", sheet=enemySheet, start=31, count=3, time=800, loopCount=1, loopDirection="bounce" },
        { name="walk_down", sheet=enemySheet, start=41, count=10, time=1000, loopCount=0 },
        { name="walk_left", sheet=enemySheet, start=51, count=10, time=1000, loopCount=0 },
        { name="walk_up", sheet=enemySheet, start=61, count=10, time=1000, loopCount=0 },
        { name="walk_right", sheet=enemySheet, start=71, count=10, time=1000, loopCount=0 }
    }

    for i = 1, 10 do
        local inimigo = display.newSprite( worldGroup, enemySheet, enemyAnims )
        
        -- [CORREÇÃO] ZONA SEGURA: Garante que inimigo não nasce em cima do player (halfW, halfH + 500)
        local ex, ey
        repeat
            ex = halfW + math.random(-800, 800)
            ey = halfH + math.random(-800, 800)
        until math.abs(ex - halfW) > 150 or math.abs(ey - (halfH + 500)) > 150

        inimigo.x = ex
        inimigo.y = ey
        inimigo.xScale = 0.8; inimigo.yScale = 0.8
        inimigo.isEnemy = true
        
        physics.addBody( inimigo, "dynamic", { radius = 25, bounce = 1 } )
        inimigo.isFixedRotation = true
        
        local moveX, moveY = 0, 0
        while moveX == 0 and moveY == 0 do
            moveX = math.random(-1, 1) * config.enemySpeed
            moveY = math.random(-1, 1) * config.enemySpeed
        end
        inimigo:setLinearVelocity( moveX, moveY )
        table.insert(inimigosList, inimigo)
    end

    linkSprite = playerModule.new( worldGroup, halfW, halfH + 500 )

    local function onCollision(event)
        if isPaused then return end -- [CORREÇÃO] Bloqueia mensagens e eventos em looping

        if event.phase == "began" then
            local other = event.other

            if other.isEnemy or other.isCabin then
                isPaused = true
                physics.pause()
                keysPressed = { w = false, a = false, s = false, d = false }
                gamePad.isMoving = false; gamePad.isMovingUp = false; gamePad.isMovingDown = false; gamePad.isMovingLeft = false; gamePad.isMovingRight = false
                
                linkSprite:setLinearVelocity(0, 0)
                linkSprite:setSequence("idle_" .. (linkSprite.walkingDirection or "down"))
                linkSprite:play()

                if other.isEnemy then
                    native.showAlert("Capturado!", "Um inimigo te pegou. Voltando ao início...", {"OK"}, function()
                        isPaused = false
                        physics.start()
                        composer.gotoScene("scripts.scene1", { effect = "slideRight", time = 500 })
                    end)

                elseif other.isCabin then
                    native.showAlert("VITÓRIA!", "Você chegou à cabana em segurança!", {"Menu Principal"}, function()
                        isPaused = false
                        physics.start()
                        audio.stop( 1 ) -- Para a música de fundo
                        composer.gotoScene("scripts.menu", { effect = "crossFade", time = 500 })
                    end)
                end
            end
        end
    end

    linkSprite:addEventListener("collision", onCollision)
end

local function onEnterFrame( event )
    playerModule.updateMovement( linkSprite, gamePad, keysPressed, config.moveSpeed, isPaused )

    if not isPaused then
        for _, inimigo in ipairs(inimigosList) do
            if inimigo and inimigo.getLinearVelocity then
                local vx, vy = inimigo:getLinearVelocity()
                local animDirection = inimigo.walkingDirection or "down"

                if math.abs(vx) > math.abs(vy) then
                    if vx > 5 then animDirection = "right" elseif vx < -5 then animDirection = "left" end
                else
                    if vy > 5 then animDirection = "down" elseif vy < -5 then animDirection = "up" end
                end

                if animDirection ~= inimigo.walkingDirection then
                    inimigo.walkingDirection = animDirection
                    inimigo:setSequence("walk_" .. animDirection)
                    inimigo:play()
                end
            end
        end
    end

    if worldGroup and worldGroup.x then
        worldGroup.x = display.contentWidth * 0.5 - linkSprite.x
        worldGroup.y = display.contentHeight * 0.5 - linkSprite.y
        zSort(worldGroup)
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