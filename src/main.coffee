# Configure RequireJS to load jQuery from a common URL.
requirejs.config({
    paths: {
        'jquery': 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'
    }
})

require ['jquery', 'game', 'loader', 'map', 'test'],
  ($, game, loader, map, test) ->
    $ ->
        # Force jQuery to grab fresh data in its Ajax requests.
        $.ajaxSetup cache: false
        
        # This is where the game code starts.
        loader_scene = new loader.LoaderScene {
                maps:
                    test: { name: 'test', script: test }
                sprites:
                    test: 'test_sprite'
                sounds:
                    test: 'sounds/jump.wav'
            }, ((loaded) ->
                test.setTestSprite loaded.sprites.test
                test.setTestSound loaded.sounds.test
                game.switchScene new map.MapScene loaded.maps.test
                return)
        
        game.init 320, 240, 1 / 60, 1 / 20, loader_scene
        game.run()
        return
    return

