local composer = require( "composer" )
local scene = composer.newScene()
local widget = require( "widget" )

-- -----------------------------------------------------------------------------------
-- Funções de transição dos botões
-- -----------------------------------------------------------------------------------

local function gotoGame()
    -- Leva para a sua scene1 com uma transição suave
    composer.gotoScene( "scripts.scene1", { time=500, effect="crossFade" } )
end

local function gotoCredits()
    -- Leva para a tela de créditos (que criaremos depois)
    composer.gotoScene( "scripts.credito", { time=500, effect="crossFade" } )
end

local function exitGame()
    -- Fecha o aplicativo
    native.requestExit()
end

-- -----------------------------------------------------------------------------------
-- Funções da Cena (Composer)
-- -----------------------------------------------------------------------------------

-- create() é executado quando a cena é carregada pela primeira vez
function scene:create( event )
    local sceneGroup = self.view

    -- Fundo escuro simples para o menu
    local background = display.newRect( sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
    background:setFillColor( 0.15, 0.15, 0.15 )

    -- Título do Jogo
    local title = display.newText( sceneGroup, "MICHAEL NA FLORESTA", display.contentCenterX, display.contentCenterY - 150, native.systemFontBold, 36 )
    title:setFillColor( 1, 1, 1 )

    -- Botão "Jogar"
    local playButton = widget.newButton(
        {
            label = "Jogar",
            onRelease = gotoGame,
            shape = "roundedRect",
            width = 200,
            height = 50,
            cornerRadius = 8,
            fillColor = { default={0.1, 0.5, 0.8, 1}, over={0.1, 0.5, 0.8, 0.7} },
            labelColor = { default={ 1, 1, 1, 1 }, over={ 1, 1, 1, 0.7 } }
        }
    )
    playButton.x = display.contentCenterX
    playButton.y = display.contentCenterY - 30
    sceneGroup:insert( playButton )

    -- Botão "Créditos"
    local creditsButton = widget.newButton(
        {
            label = "Créditos",
            onRelease = gotoCredits,
            shape = "roundedRect",
            width = 200,
            height = 50,
            cornerRadius = 8,
            fillColor = { default={0.4, 0.4, 0.4, 1}, over={0.4, 0.4, 0.4, 0.7} },
            labelColor = { default={ 1, 1, 1, 1 }, over={ 1, 1, 1, 0.7 } }
        }
    )
    creditsButton.x = display.contentCenterX
    creditsButton.y = display.contentCenterY + 40
    sceneGroup:insert( creditsButton )

    -- Botão "Sair"
    local exitButton = widget.newButton(
        {
            label = "Sair",
            onRelease = exitGame,
            shape = "roundedRect",
            width = 200,
            height = 50,
            cornerRadius = 8,
            fillColor = { default={0.8, 0.2, 0.2, 1}, over={0.8, 0.2, 0.2, 0.7} },
            labelColor = { default={ 1, 1, 1, 1 }, over={ 1, 1, 1, 0.7 } }
        }
    )
    exitButton.x = display.contentCenterX
    exitButton.y = display.contentCenterY + 110
    sceneGroup:insert( exitButton )
end

-- show()
function scene:show( event )
    local phase = event.phase
    if ( phase == "did" ) then
        -- Código executado logo após a cena aparecer completamente na tela
    end
end

-- hide()
function scene:hide( event )
    local phase = event.phase
    if ( phase == "will" ) then
        -- Código executado pouco antes da cena sair da tela
    end
end

-- destroy()
function scene:destroy( event )
    -- Limpeza de elementos caso a cena seja destruída
end

-- -----------------------------------------------------------------------------------
-- Listeners da Cena
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene