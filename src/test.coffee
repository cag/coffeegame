define ['./util', './input', './game', './geometry', './entity', './physics'],
  (util, input, game, geometry, entity, physics) ->
    test_sprite = null
    test_sound = null
    
    handleLayerObs = (other, info) ->
        return
    
    setTestSprite: (sprite) ->
        test_sprite = sprite
        return
    
    setTestSound: (sound) ->
        test_sound = sound
        return
    
    handlePlayerStart: (player) ->
        {Entity} = entity
        {Aabb, dotProduct} = geometry
        {constructBitmask} = util
        
        testPlayer = new Entity player.x, player.y,
            new Aabb [4, 4]
        
        testPlayer.obstructs = constructBitmask [0]
        testPlayer.collides = constructBitmask [0]
        
        testPlayer.damping = .99
        
        testPlayer.last_x = testPlayer.x
        testPlayer.last_y = testPlayer.y
        
        testPlayer.update = (dt) ->
            accel = [0, 0]
            
            if @grounded
                if input.jump.pressed
                    @damping = .995
                    h_accel = 100
                    
                    v = physics.getVelocity(this, dt)
                    v[1] = -200
                    physics.setVelocity(this, v, dt)
                    
                    @grounded = false
                    
                    test_sound.play()
                else
                    @damping = .5
                    h_accel = 2000
            else
                if @last_y > @y and input.jump.released
                    @last_y = .5 * (@last_y - @y) + @y
                @damping = .995
                h_accel = 100
            
            if input.left.state
                accel[0] -= h_accel
            if input.right.state
                accel[0] += h_accel
            
            if @grounded and
              (dotProduct @ground_normal, accel) < 0
                accel[1] -= accel[0] * @ground_normal[0] /
                    @ground_normal[1]
            
            if not @grounded or accel[0] isnt 0 or
              Math.abs(@last_x - @x) >= 1
                accel[1] += 400
                @grounded = false
            
            @acceleration = accel
            physics.integrate this, dt
            return
        
        testPlayer.onObstruct = (other, info) ->
            normal = info[1]
            if normal[1] >= Math.abs normal[0]
                @grounded = true
                @ground_normal = normal
            return
        
        test_sprite.startAnimation 'walk'
        testPlayer.sprite = test_sprite
        
        testPlayer.draw = (context, xoff, yoff) ->
            @sprite.draw(context, @x + xoff, @y + yoff, true)
            return
        
        player.layer.addEntity testPlayer
        player.map.camera.update = (dt) ->
            @x = testPlayer.x
            @y = testPlayer.y
            return
        return
    
    handleLayerObs: handleLayerObs
    
    handleObs1: (other, info) ->
        handleLayerObs other, info
        return
    
    handleZoneCollide: (other, info) ->
        return
    
    handleZone1Collide: (other, info) ->
        return
    
    handleLayerStart: (layer) ->
        return

