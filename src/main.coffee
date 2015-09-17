# Configure RequireJS to load jQuery from a common URL.
requirejs.config \
    paths:
        jquery: 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'
        screenfull: '../libs/screenfull'

require ['jquery', 'screenfull', './cg', './demo', './demo2', './ui'],
  ($, __void__, cg, demo, demo2, ui) ->
    {game, loader, map} = cg

    setupScreenfull = (game) ->
        if screenfull?.enabled
            fs_btn_container = (document.getElementById 'fs-btn') or document.body
            fs_button = $('<button/>').text('Fullscreen').click ->
                game_canvas = game.canvas()
                screenfull.request game_canvas
                $(game_canvas).focus()
                return
            fs_btn_container.appendChild fs_button[0]

    $ ->
        # Force jQuery to grab fresh data in its Ajax requests.
        $.ajaxSetup cache: false
        
        # This is where the game code starts.
        loader_scene = new loader.LoaderScene {
                maps:
                    demo: { name: 'demo', script: demo }
                    demo2: { name: 'demo2', script: demo2 }
                sprites:
                    player: 'player'
                    demo2player: 'demo2player'
                    joanna: 'joanna'
                    shaun: 'shaun'
                sounds: {}
            }, (loaded) ->
                demo.setPlayerSprite loaded.sprites.player
                demo_scene = new map.MapScene loaded.maps.demo

                demo2.setPlayerMetadata new cg.geometry.Aabb([4, 4]), loaded.sprites.shaun
                demo_scene2 = new demo2.DemoScene loaded.maps.demo2

                game.switchScene demo_scene2
                return

        game.init 320, 240, 1 / 60, 1 / 20, loader_scene
        setupScreenfull game
        $(window).resize game.resizeCanvasToAspectRatio
        $(game.canvas()).attr 'dir', if ui.isRightToLeft() then 'rtl' else 'ltr'
        game.run()
        return
    return

