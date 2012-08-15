# Configure RequireJS to load jQuery from a common URL.
requirejs.config({
    paths: {
        'jquery': 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'
    }
})# if false # Psyche!

require ['jquery', 'game', 'loader', 'map', 'demo'],
  ($, game, loader, map, demo) ->
    $ ->
        # Force jQuery to grab fresh data in its Ajax requests.
        $.ajaxSetup cache: false
        
        # This is where the game code starts.
        loader_scene = new loader.LoaderScene {
                maps:
                    demo: { name: 'demo', script: demo }
                sprites:
                    player: 'player'
                sounds: {}
            }, (loaded) ->
                demo.setPlayerSprite loaded.sprites.player
                demo_scene = new map.MapScene loaded.maps.demo
                game.switchScene demo_scene
                return
        
        game.init 320, 240, 1 / 60, 1 / 20, loader_scene
        game.run()
        return
    return

