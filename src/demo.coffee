define ['./cg'],
  (cg) ->
    {input, audio, util, game, geometry, entity, physics} = cg
    player_sprite = null
    
    setupSky: (layer) ->
        layer.draw = (context, targx, targy) ->
            cam = @map.camera
            
            context.beginPath()
            cam.shapeSubpath context, targx - cam.x, targy - cam.y
            context.fillStyle = '#A5DFEA'
            context.fill()
            return
        return
    
    setPlayerSprite: (sprite) ->
        player_sprite = sprite
        return
    
    handlePlayerStart: (obj) ->
        actx = audio.getAudioContext()
        if actx?
            osc = actx.createOscillator()
            osc.type = osc.TRIANGLE
            
            gain = actx.createGain()
            gain.gain.value = .25
            
            osc.connect gain
            gain.connect actx.destination
            
            time_ptr = actx.currentTime
            note_dur = .25
            for tuning_factor in audio.ptolemy_tuning_factors
                osc.frequency.setValueAtTime \
                    1.0 * audio.ptolemy_c4 * tuning_factor,
                    time_ptr
                time_ptr += note_dur
            
            osc.frequency.setValueAtTime \
                audio.ptolemy_c4 * .25,
                time_ptr
            
            time_ptr += note_dur
            osc.start actx.currentTime
            osc.stop time_ptr
        
        player = new entity.Entity obj.x, obj.y,
            new geometry.Aabb [2, 11]
        
        player_sprite.startAnimation 'idle'
        player.sprite = player_sprite
        
        player.obstructs = util.constructBitmask [0]
        
        walk_vel_threshold = 2
        walk_accel = 640
        walk_anim_speed_factor = .125
        run_vel_threshold = 16
        run_accel = 2560
        run_anim_speed_factor = .125 / 3
        grounded_damping = .25
        jump_vel = -160
        jump_release_factor = .5
        aerial_move_accel = 32
        aerial_damping = .984375
        wall_slide_damping = .875
        wall_jump_angle = .25 * Math.PI
        wall_jump_speed = -160
        gravity = 160
        
        cos_wja = Math.cos wall_jump_angle
        sin_wja = Math.sin wall_jump_angle
        
        player.update = (dt) ->
            v = @velocity or [0, 0]
            a = [0, 0]
            
            x_spd = Math.abs(@x - (@last_x or @x)) / game.lastDt()
            
            sprite = @sprite
            state = @state
            switchStateTo = (name) ->
                if state isnt name
                    sprite.startAnimation name
                    state = name
                return
            
            if input.left.state and not input.right.state
                @facing_left = true
            else if input.right.state and not input.left.state
                @facing_left = false
            
            moving_forward = @facing_left and
                v[0] < -walk_vel_threshold or
                not @facing_left and v[0] > walk_vel_threshold

            running_forward = moving_forward and Math.abs(v[0]) > run_vel_threshold
            
            console.log running_forward if input.debug.pressed

            if @grounded
                if not moving_forward or @against_wall
                    switchStateTo 'idle'
                else if running_forward
                    switchStateTo 'run'
                    sprite.animation_speed = x_spd * run_anim_speed_factor
                else
                    switchStateTo 'walk'
                    sprite.animation_speed = x_spd * walk_anim_speed_factor
                
                if input.jump.pressed
                    switchStateTo 'jump'
                    v[1] = jump_vel
                    @damping = aerial_damping
                else
                    move_accel = if input.run.state then run_accel else walk_accel
                    if input.left.state and not input.right.state
                        a[0] -= move_accel * @ground_normal[1]
                        a[1] += move_accel * @ground_normal[0]
                    else if input.right.state and not input.left.state
                        a[0] += move_accel * @ground_normal[1]
                        a[1] -= move_accel * @ground_normal[0]

                    @damping = grounded_damping
            else
                if input.left.state
                    a[0] -= aerial_move_accel
                if input.right.state
                    a[0] += aerial_move_accel
                a[1] += gravity
                if v[1] < 0 and input.jump.released
                    v[1] *= jump_release_factor
                else
                    @damping = aerial_damping
                    if @sliding and input.jump.pressed
                        if @wall_normal[0] > 0
                            v[0] = wall_jump_speed *
                                geometry.dotProduct @wall_normal,
                                [cos_wja, -sin_wja]
                            v[1] = wall_jump_speed *
                                geometry.dotProduct @wall_normal,
                                [sin_wja, cos_wja]
                        else if @wall_normal[0] < 0
                            v[0] = wall_jump_speed *
                                geometry.dotProduct @wall_normal,
                                [cos_wja, sin_wja]
                            v[1] = wall_jump_speed *
                                geometry.dotProduct @wall_normal,
                                [-sin_wja, cos_wja]
                        else
                            console.warn 'wall jump strangeness'
                        switchStateTo 'wall jump'
                    else if @against_wall and v[1] > 0
                        @damping = wall_slide_damping
                        switchStateTo 'wall slide'
                        @facing_left = @wall_normal[0] > 0
                    else if @sliding
                        switchStateTo 'slide'
                        @facing_left = @wall_normal[0] > 0
                    else if v[1] > 0
                        switchStateTo 'fall'
            
            if @grounded and
              (a[0] isnt 0 or v[1] < 0)
                a[1] += gravity
                @grounded = false
            
            @sliding = false
            @against_wall = false
            
            @acceleration = a
            @velocity = v
            @last_x = @x
            physics.integrate this, dt
            
            @state = state
            sprite.update dt
            return
        
        player.onCollide = (other, info) ->
            [pen_amt, pen_dir] = info
            console.log pen_dir if input.debug.pressed
            if pen_dir[1] >= Math.abs pen_dir[0]
                @grounded = true
                @ground_normal = pen_dir
            else if pen_dir[1] >= 0
                @sliding = true
                @wall_normal = pen_dir
                if (input.left.state and
                  pen_dir[0] < -Math.abs pen_dir[1]) or
                  (input.right.state and
                  pen_dir[0] > Math.abs pen_dir[1])
                    @against_wall = true
            return
        
        player.draw = (context, offx, offy) ->
            @sprite.draw context, @x + offx, @y + offy, @facing_left
            return
        
        obj.layer.addEntity player
        
        obj.map.camera.post_update = (dt) ->
            @x = player.x
            @y = player.y
            return
        
        return

