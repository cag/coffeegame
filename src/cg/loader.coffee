define ['./map', './sprite', './audio'], (map, sprite, audio) ->
    # A scene for loading resources. Pass in an object of the form:
    # 
    #     {
    #         maps:
    #             MAPVAR: { name: MAPNAME, script: MAPSCRIPT },
    #             ...
    #         sprites:
    #             SPRITEVAR: SPRITENAME,
    #             ...
    #         sounds:
    #             SOUNDVAR: SOUNDNAME,
    #             ...
    #     }
    #
    # The resources will load into an object of the form:
    # 
    #     {
    #         maps:
    #             MAPVAR: MAP,
    #             ...
    #         sprites:
    #             SPRITEVAR: SPRITE,
    #             ...
    #         sounds:
    #             SOUNDVAR: SOUND,
    #             ...
    #     }
    # 
    # This object will be passed into the `@onload` callback, which
    # will be a good time for setting up a new scene to switch into.
    LoaderScene: class
        constructor: (@resources, @onload) ->
            @loaded =
                maps: {}
                sprites: {}
                sounds: {}
            
            resource_count = 0
            for type, obj of @resources
                resource_count += (Object.keys obj).length
            @resource_count = resource_count
            
            if resource_count <= 0
                throw "invalid resource count (#{resource_count})"
            return
        
        start: ->
            {Map} = map
            {Sprite} = sprite
            {Sound} = audio
            
            load_count = 0
            loader = this
            @progress = 0
            @finished = false
            
            callback = ->
                ++load_count
                loader.progress = load_count / loader.resource_count
                if load_count is loader.resource_count
                    loader.finished = true
                    loader.onload? loader.loaded
                return
            
            for type, obj of @resources
                target = @loaded[type]
                
                if type is 'maps'
                    for key, res of obj
                        target[key] = new Map res.name, res.script,
                            callback
                else if type is 'sprites'
                    for key, res of obj
                        target[key] = new Sprite res, callback
                else if type is 'sounds'
                    for key, res of obj
                        target[key] = new Sound res, callback
                else
                    throw "attempting to load unknown type #{type}"
            return
        
        end: ->
            return
        
        update: (dt) ->
            return
        
        draw: (context) ->
            return

