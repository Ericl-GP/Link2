local composer = require( "composer" )
local scene = composer.newScene()
local widget = require( "widget" )

local backgroundMusic = audio.loadStream( "Song/SEGA-Michael-Jacksons.mp3" )
audio.setVolume( 0.4, { channel = 1 } )
audio.play( backgroundMusic, { channel = 1, loops = -1, fadein = 2000 } )
-- Formatando os créditos com base no Referencias.md
local creditosTexto = [[
Desenvolvido por:
Ericles & Danilo!

Áudio in game:
OcularNebula (Newgrounds)

Background Music: SEGA - Michael Jackson's Moonwalker (Arcade Version)
Digimaks - Newgrounds

Efeitos Sonoros:
Repositório da Comunidade (MyInstants)

Sprite Principal (Michael Jackson):
Dinner Sonic (Spriters Resource)

Objetos Destrutíveis (Caixas):
Elthen's Pixel Art Shop (Itch.io)

Cenário (Árvores e Cabana):
Autor Desconhecido (CraftPix)
]]

-- create()
function scene:create( event )
    local sceneGroup = self.view

    -- Fundo preto básico para destacar o texto
    local background = display.newRect( sceneGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight )
    background:setFillColor( 0, 0, 0 )

    -- Grupo que vai guardar os textos para podermos animar tudo junto
    self.rolagemGroup = display.newGroup()
    sceneGroup:insert(self.rolagemGroup)

    -- Título de Créditos
    local titulo = display.newText( {
        parent = self.rolagemGroup,
        text = "CRÉDITOS",
        x = display.contentCenterX,
        y = display.contentHeight + 50, -- Começa fora da tela, na parte de baixo
        font = native.systemFontBold,
        fontSize = 40
    } )

    -- Texto descritivo
    local texto = display.newText( {
        parent = self.rolagemGroup,
        text = creditosTexto,
        x = display.contentCenterX,
        y = titulo.y + 350, -- Fica abaixo do título
        width = display.contentWidth - 40,
        font = native.systemFont,
        fontSize = 20,
        align = "center"
    } )

    -- Calcula uma posição Y para colocar a imagem logo abaixo do final do texto
    local posY_daImagem = texto.y + (texto.height / 2) + 150 

    -- Carrega a imagem (como michael2_2.png ou link.png que estão na raiz)
    -- Os números 150, 150 representam a largura e altura na tela. Ajuste como preferir!
    local imagemFinal = display.newImageRect( self.rolagemGroup, "assets/michael2_2.png", 150, 150 ) 
    local imagemFinal1 = display.newImageRect(self.rolagemGroup, "assets/link.png", 150, 150);
    local imagemFinal2 = display.newImageRect(self.rolagemGroup, "assets/Objetos.png", 150, 150);
    imagemFinal.x = display.contentCenterX
    imagemFinal.y = posY_daImagem
    imagemFinal1.x = display.contentCenterX - 200
    imagemFinal1.y = posY_daImagem
    imagemFinal2.x = display.contentCenterX + 200
    imagemFinal2.y = posY_daImagem



    -- Criando o botão para Voltar ao Menu
    local btnVoltar = widget.newButton(
        {
            label = "Voltar ao Menu",
            onRelease = function()
                -- Cancela a animação do texto caso o jogador saia antes de terminar
                transition.cancel( self.rolagemGroup )
                audio.stop( 1 ) -- Para a música de fundo
                -- Se o seu menu.lua estiver na raiz do projeto, use "menu", 
                -- se estiver na pasta scripts, use "scripts.menu"
                composer.removeScene("scripts.credito");
                composer.gotoScene( "scripts.menu", { time=500, effect="crossFade" } )
            end,
            shape = "roundedRect",
            width = 200,
            height = 50,
            cornerRadius = 10,
            fillColor = { default={ 0.2, 0.2, 0.8, 1 }, over={ 0.1, 0.1, 0.4, 1 } },
            labelColor = { default={ 1, 1, 1, 1 }, over={ 0.8, 0.8, 0.8, 1 } }
        }
    )
    -- O botão fica fixo no topo (ou no rodapé) para não rolar com os créditos
    btnVoltar.x = display.contentCenterX
    btnVoltar.y = 40
    sceneGroup:insert(btnVoltar)
end

-- show()
function scene:show( event )
    local phase = event.phase

    if ( phase == "will" ) then
        -- Antes da cena aparecer, nós resetamos a posição do texto 
        -- caso o jogador entre nesta tela mais de uma vez
        self.rolagemGroup.y = 0
    elseif ( phase == "did" ) then
        -- Quando a cena aparece completamente, iniciamos a "Mágica do Cinema"
        -- Movemos todo o grupo de textos para cima no Eixo Y (-1500 pixels)
        transition.to( self.rolagemGroup, { 
            y = -2000, -- A distância que o texto vai subir (ajuste conforme necessário) 
            time = 15000, -- O tempo em milissegundos (15 segundos) que a rolagem vai durar
            onComplete = function()
                -- Opcional: Se quiser que volte pro menu sozinho ao terminar a rolagem
                -- composer.gotoScene( "menu", { time=500, effect="crossFade" } )
            end
        } )
    end
end

-- hide()
function scene:hide( event )
    local phase = event.phase
    if ( phase == "will" ) then
        -- Cancela a transição caso a cena saia da tela
        transition.cancel( self.rolagemGroup )
    end
end

-- destroy()
function scene:destroy( event )
    -- Limpezas (se necessário)
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene