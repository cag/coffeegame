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
        ui.textBoxDialog 'T͕̜͘ò ̮͎̣i̧̭͉n͉̠̣̖vo̪̖k̢͕̫e͟ ҉͈̲t̞͈͖͚͔̀h̝e̱̥̩̣̪ ͟h̤͔̩̣̻̦͉͜i̝̩͉̜̞͔v̘͔̤͙͕e͏̻-̬͘mi̬̫̪̝̠̝͉n̳̳̼̖d͖̖̠ ̷̫̝̪r̖̯̙̮̼͠ͅe̫͖͎̲͚p͓̫r͕̜̺e̠̣̲s̥͈̻e̹͖̝̻n̵̠͖̤̦̮͈̫t̯̗i̴͓̬͈̱̪̜n̗̹̯͍͇͠g҉̰ c̩͡ͅha͉o͓̦͔̖̦͢s҉̠̣̮.̴͇̮̮ ̜̮I̴̭̣̼͍̗n͇̤̪͇̺̭̼v̪̗o̬̩̳k͏̬̫̲̣̗̙i̫͍̳̠n̸̟g͔͘ t̨ḩ̰͈̬e͔̩̮̱ ̬͈̳̟͕̼̤͝f̤͎̹̼̻̤̭e̛̲̫̙̲̦̞ͅe̩̗̝̥̣l͎͙͙͉͡i͡n̼͉̥g̙ ̥o͙̳̞f̻͠ c̦̫̤͇̬̼h̴͕̻̱͉̼ͅḁ̷̪̣o͕͓̗̦s̫̫̠.͉̱̞̳ ̪̝͔̗̙̹̀ͅW͜it͍̭̻̱̞̞h́ ̴̮̲̣̲̠̮o̠̖̯ut̴̺̦̙̙̞ ̫̜̻̫̼̖͠o̯̭̖͢ŗ̤̙̙̺̰d̫e̢̬̘r̪͜.͚̖̠̝͔͞ ͏͖̙̩T̝̤̱̭̫̭h̦é̞͚ ̠͓̖̫͢N̦̲̭e͍̦̹̼̪̪͟ͅz͟p̨̺̞͓̠̲ͅe͔͓͕͇͓̯͝r̳̯̝͈d̟i̶͎͈͉͉͚̜̭a͏̯͇̰̗̘̰͍n̙ ̫͔͉h͙̦͖͠i̴̙͚͕v̯̰͕͔̼e̦̯̗͝-̤̠͔͞m͍̙i̧n͙͙̥͖͈̫ͅd̪͇͉ ̷̠̤͎͔ͅo͏̘f ̭͚̤c͘h̢̺ͅa̢̬̪̱̳̗̝̱o̜͚̱̟̩͟ͅs̗ͅ.̤̱̯̥̻̬̝ Z̼̠̥͓̥͔ͅa̲l̦̲̭͖̗̣͜g҉͔͖̭̣̻o͖̗͇̺̣̫̥.҉͓͎͙̖̭̖ ͏̜̜̗H̺͉̯͖̭e͏͈ ͇̱̯̜w̛̤͚͎͍h͇o͔͖̱̭̻̱̱ ́W͎̙̠̬͢a̩̬̯̬̫̫̦i̡͉ț̛̭s̝͚̲̦ ̢̭̥̯B̮͚̙̝͔̙͙e̹͈ẖ̩i̷̦̙̝n̙̞̙̼̪d͠ ̝T͞h̲̜e͏̳̺̠͉̮ͅ ̛W͎͙̭̰͜a̴̩̱͎̗̰l͜l̮̖.̹̯̕ ̲͚̜Z̲̳͓͍͞A̺Ḽ̷̤̙̫̭G͖O͓̬̹͇̰͘!̪͉͇͉̤̥ͅ', 0, 0, 160, 44, 10.0, null, null, ->
            game.state = 'world'
        return

    DemoScene: DemoScene
