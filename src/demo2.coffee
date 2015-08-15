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
        constructor: (x, y, shape, sprite, camera) ->
            super x, y, shape, sprite
            @state = 'look down'
            @dir = 'down'
            player = this
            camera.post_update = (dt) ->
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
