define ['./cg'],
  (cg) ->
    {input, audio, util, game, geometry, entity, physics} = cg

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
                if input.jump.pressed
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
            sprite.update dt

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
        return