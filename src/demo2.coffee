define ['./cg', './ui'],
  (cg, ui) ->
    {input, audio, util, game, geometry, entity, physics, map} = cg

    fadeIn = (duration, callback) ->
        t_accum = 0.0
        updateGenerator = ->
            while t_accum < duration
                dt = yield undefined
                t_accum += dt
            callback?()
        drawGenerator = ->
            while t_accum < duration
                context = yield undefined
                alpha = 1.0 - (Math.min t_accum / duration, 1.0)
                context.fillStyle = "rgba(0,0,0,#{alpha})"
                context.fillRect 0, 0, game.width(), game.height()

        util.prepareCoroutineSet updateGenerator, drawGenerator

    class DemoScene extends map.MapScene
        start: ->
            super
            game.state = 'fx'
            game.invoke fadeIn 0.5, ->
                game.state = 'world'

    class Character extends entity.Entity
        constructor: (x, y, shape, @sprite) ->
            super x, y, shape
            @sprite.startAnimation 'look down'

        draw: (context, offx, offy) ->
            @sprite.draw context, @x + offx, @y + offy, @facing_left
            return

    class PlayerCharacter extends Character
        constructor: (x, y, shape, sprite) ->
            super x, y, shape, sprite
            @state = 'look down'
            @dir = 'down'
            map = game.currentScene().map
            player = this
            ent_layer = map.getLayerByName 'Entities'

            @activation_point_check = new entity.Entity x, y + 2 * @shape.bounds_offsets[3], new geometry.Point
            @activation_point_check.collides = util.constructBitmask [0]
            @activation_point_check.onCollide = (ent, info) ->
                if game.state is 'world' and input.jump.pressed
                    if not ent.onActivate?
                        ent.onActivate = map.tryGettingCallbackForName ent.properties?.onActivate
                    ent.onActivate ent
                return
            ent_layer.addEntity @activation_point_check
            
            map.camera.post_update = (dt) ->
                @x = player.x
                @y = player.y
                return

        update: (dt) ->
            sprite = @sprite
            state = @state
            switchStateTo = (name) ->
                if state isnt name
                    sprite.startAnimation name
                    state = name
                return

            if game.state is 'world'
                vxc = 0.0
                vyc = 0.0

                if input.left.state and not input.right.state
                    @facing_left = true
                    vxc = -1.0
                    @dir = 'right'
                else if input.right.state and not input.left.state
                    @facing_left = false
                    vxc = 1.0
                    @dir = 'right'

                if input.up.state and not input.down.state
                    vyc = -1.0
                    @dir = 'up'
                else if input.down.state and not input.up.state
                    vyc = 1.0
                    @dir = 'down'

                if vyc == 0.0
                    if vxc == 0.0
                        switchStateTo 'look ' + @dir
                    else
                        switchStateTo 'go right'
                else if vyc < 0.0
                    switchStateTo 'go up'
                else if vyc > 0.0
                    switchStateTo 'go down'

                @state = state
                @velocity = [64.0 * vxc, 64.0 * vyc]
                physics.integrate this, dt

                # TODO: make this better
                if @dir is 'right'
                    if @facing_left
                        @activation_point_check.x = @x + 2 * @shape.bounds_offsets[0]
                        @activation_point_check.y = @y
                    else
                        @activation_point_check.x = @x + 2 * @shape.bounds_offsets[1]
                        @activation_point_check.y = @y
                else if @dir is 'up'
                    @activation_point_check.x = @x
                    @activation_point_check.y = @y + 2 * @shape.bounds_offsets[2]
                else if @dir is 'down'
                    @activation_point_check.x = @x
                    @activation_point_check.y = @y + 2 * @shape.bounds_offsets[3]

            sprite.update dt
            return

    player = null
    player_shape = null
    player_sprite = null

    setPlayerMetadata: (shape, sprite) ->
        player_shape = shape
        player_sprite = sprite
        return

    handlePlayerStart: (obj) ->
        player = new PlayerCharacter obj.x, obj.y, player_shape, player_sprite, obj.map.camera
        player.obstructs = util.constructBitmask [0]
        obj.layer.addEntity player
        return

    handleChest1Start: (obj) ->
        return

    tryOpeningChest1: (obj) ->
        tx = (obj.x / obj.map.tilewidth) | 0
        ty = (obj.y / obj.map.tileheight) | 0
        layer = obj.map.getLayerByName('Ground')
        td = layer.data[tx][ty][..]
        td[0]++
        layer.setTile tx, ty, td
        ui.textBoxDialog 'Do not go gentle into that good night,
Old age should burn and rave at close of day;
Rage, rage against the dying of the light.

Though wise men at their end know dark is right,
Because their words had forked no lightning they
Do not go gentle into that good night.

Good men, the last wave by, crying how bright
Their frail deeds might have danced in a green bay,
Rage, rage against the dying of the light.

Wild men who caught and sang the sun in flight,
And learn, too late, they grieved it on its way,
Do not go gentle into that good night.

Grave men, near death, who see with blinding sight
Blind eyes could blaze like meteors and be gay,
Rage, rage against the dying of the light.

And you, my father, there on the sad height,
Curse, bless, me now with your fierce tears, I pray.
Do not go gentle into that good night.
Rage, rage against the dying of the light.', 0, 0, 160, 44, 10.0, null, null, ->
            game.state = 'world'
        return

    DemoScene: DemoScene
