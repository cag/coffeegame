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
            @dir = 'down'
            @state = 'look ' + @dir
            map = game.currentScene().map
            player = this
            ent_layer = map.getLayerByName 'Entities'

            @activation_point_check = new entity.Entity x, y + 2 * @shape.bounds_offsets[3], new geometry.Point
            @activation_point_check.collides = util.constructBitmask [0]
            @activation_point_check.onCollide = (ent, info) ->
                if game.state is 'world' and input.jump.pressed
                    if not ent.onActivate?
                        ent.onActivate = map.tryGettingCallbackForName ent.properties?.onActivate
                    player.sprite.startAnimation 'look ' + player.dir
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
                    vxc = -1.0
                else if input.right.state and not input.left.state
                    vxc = 1.0

                if input.up.state and not input.down.state
                    vyc = -1.0
                else if input.down.state and not input.up.state
                    vyc = 1.0

                if vxc < 0.0
                    if vyc < 0.0
                        @dir = 'up-left'
                    else if vyc > 0.0
                        @dir = 'down-left'
                    else
                        @dir = 'left'
                else if vxc > 0.0
                    if vyc < 0.0
                        @dir = 'up-right'
                    else if vyc > 0.0
                        @dir = 'down-right'
                    else
                        @dir = 'right'
                else
                    if vyc < 0.0
                        @dir = 'up'
                    else if vyc > 0.0
                        @dir = 'down'

                if vyc == 0.0 and vxc == 0.0
                    switchStateTo 'look ' + @dir
                else
                    switchStateTo 'go ' + @dir

                @state = state
                inv_spd_c = if vxc == 0.0 and vyc == 0.0 then 1.0 else 1.0/Math.sqrt(vxc*vxc+vyc*vyc)
                @velocity = [48.0 * vxc * inv_spd_c, 48.0 * vyc * inv_spd_c]
                physics.integrate this, dt

                if @dir is 'left'
                    @activation_point_check.x = @x + 2 * @shape.bounds_offsets[0]
                    @activation_point_check.y = @y
                else if @dir is 'right'
                    @activation_point_check.x = @x + 2 * @shape.bounds_offsets[1]
                    @activation_point_check.y = @y
                else if @dir is 'up'
                    @activation_point_check.x = @x
                    @activation_point_check.y = @y + 2 * @shape.bounds_offsets[2]
                else if @dir is 'down'
                    @activation_point_check.x = @x
                    @activation_point_check.y = @y + 2 * @shape.bounds_offsets[3]
                else if @dir is 'up-left'
                    @activation_point_check.x = @x + Math.sqrt(2) * @shape.bounds_offsets[0]
                    @activation_point_check.y = @y + Math.sqrt(2) * @shape.bounds_offsets[2]
                else if @dir is 'up-right'
                    @activation_point_check.x = @x + Math.sqrt(2) * @shape.bounds_offsets[1]
                    @activation_point_check.y = @y + Math.sqrt(2) * @shape.bounds_offsets[2]
                else if @dir is 'down-left'
                    @activation_point_check.x = @x + Math.sqrt(2) * @shape.bounds_offsets[0]
                    @activation_point_check.y = @y + Math.sqrt(2) * @shape.bounds_offsets[3]
                else if @dir is 'down-right'
                    @activation_point_check.x = @x + Math.sqrt(2) * @shape.bounds_offsets[1]
                    @activation_point_check.y = @y + Math.sqrt(2) * @shape.bounds_offsets[3]

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
        ui.textBoxDialog 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 0, 0, 160, 44, 10.0, null, null, ->
            game.state = 'world'
        return

    DemoScene: DemoScene
