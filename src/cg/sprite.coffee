define ['jquery'], ($) ->
    # Similar to the map module, sprites are loaded via JSON from
    # a url constructed from @name.
    url_prefix = 'assets/'
    url_suffix = '.json'
    
    Sprite: class
        constructor: (@name, onload) ->
            @loaded = false
            cb_target = this
            $.getJSON url_prefix + @name + url_suffix, (data) ->
                try
                    cb_target.load(data, onload)
                catch e
                    throw 'could not load sprite ' +
                        url_prefix + cb_target.name + url_suffix
                return
            return
        
        # The sprite JSON format is as follows:
        #
        #     {
        #       "spritesheet": FILENAME,
        #       "offset": [SOFFX, SOFFY],
        #       "frames": [
        #         {
        #           "pos": [X, Y],
        #           "size": [W, H],
        #           "offset": [FOFFX, FOFFY]
        #         },
        #         ...
        #       ],
        #       "animations": {
        #         NAME: {
        #           "frames": [[INDEX, DURATION(, HFLIPPED)], ...],
        #           "loop": LOOP
        #         },
        #         ...
        #       }
        #     }
        #
        # Note: `FILENAME` is a string containing the name of the
        # image which contains the spritesheet, `[SOFFX, SOFFY]` is
        # the offset of the spritesheet in the image, `[X, Y]` is the
        # top-left corner of the frame described in the spritesheet,
        # `[W, H]` is the size of the frame, `[FOFFX, FOFFY]` is the
        # offset of the top left corner of the frame from the position
        # of the sprite (around which drawing flipped versions will
        # be based), `NAME` is a string naming an animation, `INDEX`
        # refers to the index of a frame, `DURATION` is how long that
        # frame should stay onscreen in seconds, and `LOOP` is true
        # or false depending on whether the animation should loop.
        load: (json_data, onload) ->
            {offset, frames, animations} = json_data
            
            for name, animation of animations
                duration = 0
                for frame in animation.frames
                    duration += frame[1]
                animations[name].duration = duration
            
            @animations = animations
            sprite = this
            
            image = new Image()
            image.onload = ->
                sprite.setupFrames image, offset, frames
                @loaded = true
                onload?()
                return
            image.src = url_prefix + json_data.spritesheet
            return
        
        setupFrames: (img, offset, frames) ->
            grabFrame = (frame) ->
                fw = frame.size[0]
                fh = frame.size[1]
                fcanvas = document.createElement 'canvas'
                fcanvas.width = fw
                fcanvas.height = fh
                fctx = fcanvas.getContext '2d'
                fctx.drawImage img,
                    offset[0] + frame.pos[0],
                    offset[1] + frame.pos[1],
                    fw, fh, 0, 0, fw, fh
                
                return fcanvas
            
            @frames = (grabFrame frame for frame in frames)
            @frame_offsets = (frame.offset for frame in frames)
            return
        
        startAnimation: (anim_name, anim_speed = 1) ->
            @current_animation = @animations[anim_name]
            @animation_time = 0
            @animation_speed = anim_speed
            return
        
        update: (dt) ->
            @animation_time += dt * @animation_speed
            return
        
        draw: (context, x, y, flip_h) ->
            cur_anim = @current_animation
            cur_anim_dur = cur_anim.duration
            frame_index = -1
            anim_time = @animation_time
            
            if cur_anim.loop
                anim_time %= cur_anim_dur
            else if anim_time > cur_anim_dur
                anim_time = cur_anim_dur
            
            for frame in cur_anim.frames
                anim_time -= frame[1]
                if anim_time <= 0
                    frame_index = frame[0]
                    frame_hflipped = !!frame[2]
                    break
            
            frame_img = @frames[frame_index]
            frame_offset = @frame_offsets[frame_index]
            
            context.save()
            
            context.translate Math.round(x), Math.round(y)
            context.transform -1, 0, 0, 1, 0, 0 if !!flip_h != frame_hflipped
            context.drawImage frame_img, frame_offset[0], frame_offset[1]
            
            context.restore()
            
            return

