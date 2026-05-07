-- scripts/player.lua
local physics = require( "physics" )

local Player = {}

-- Função que cria o jogador e o devolve para a cena
function Player.new( worldGroup, startX, startY )
    local linkSpriteSheet = graphics.newImageSheet( "assets/michael2_2.png", { width = 55, height = 143, numFrames = 42, border = 0 } )
    local linkSpriteSheet_IDLE = graphics.newImageSheet( "assets/michael_IDE.png", { width = 55, height = 143, numFrames = 96, border = 0 } )
    
    local linkAnimationSequences = {
        { name="idle_down", sheet=linkSpriteSheet_IDLE, start=1, count=14, time=2000, loopCount=1, loopDirection="bounce" },
        { name="idle_left", sheet=linkSpriteSheet_IDLE, start=17, count=12, time=2000, loopCount=1, loopDirection="bounce" },
        { name="idle_up", sheet=linkSpriteSheet_IDLE, start=33, count=12, time=2000, loopCount=1, loopDirection="bounce" },
        { name="idle_right", sheet=linkSpriteSheet_IDLE, start=49, count=11, time=2000, loopCount=1, loopDirection="bounce" },
        { name="walk_down", sheet=linkSpriteSheet, start=29, count=7, time=1000, loopCount=0 },
        { name="walk_left", sheet=linkSpriteSheet, start=36, count=7, time=1000, loopCount=0 },
        { name="walk_up", sheet=linkSpriteSheet, start=1, count=7, time=1000, loopCount=0 },
        { name="walk_right", sheet=linkSpriteSheet, start=15, count=7, time=1000, loopCount=0 }
    }
    
    local linkSprite = display.newSprite( worldGroup, linkSpriteSheet_IDLE, linkAnimationSequences )
    linkSprite.x = startX
    linkSprite.y = startY
    linkSprite.xScale = 1.5
    linkSprite.yScale = 1.5
    linkSprite:setSequence( "idle_down" )
    linkSprite:play()
    
    physics.addBody( linkSprite, "dynamic", { radius = 30, bounce = 0 } )
    linkSprite.isFixedRotation = true

    return linkSprite
end

-- Função que processa o movimento do jogador (pode ser chamada no onEnterFrame da cena)
function Player.updateMovement( linkSprite, gamePad, keysPressed, moveSpeed, isPaused )
    if not linkSprite or not linkSprite.setLinearVelocity then return end
    
    if isPaused then 
        linkSprite:setLinearVelocity(0, 0)
        return 
    end

    local vx, vy = 0, 0
    local direction = nil

    if gamePad.isMovingUp or keysPressed.w then vy = -moveSpeed; direction = "up" end
    if gamePad.isMovingDown or keysPressed.s then vy = moveSpeed; direction = "down" end
    if gamePad.isMovingLeft or keysPressed.a then vx = -moveSpeed; direction = "left" end
    if gamePad.isMovingRight or keysPressed.d then vx = moveSpeed; direction = "right" end
    
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

return Player