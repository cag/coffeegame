define ['jquery', './util'], ($, util) ->
    # Similar to the map module, sprites are loaded via JSON from
    # a directory with a name.
    url_prefix = 'sprites/'
    url_suffix = '.json'
    
    Sprite: class
        constructor: (@name, onload) ->
            @loaded = false
            cb_target = this
            $.getJSON url_prefix + @name + url_suffix,
                ((data) -> cb_target.load(data, onload); return)
            return
        
        # The sprite JSON format is as follows:
        #
        #     {
        #       "spritesheet": FILENAME,
        #       "frames": [
        #         {
        #           "pos": [X, Y],
        #           "size": [W, H],
        #           "offset": [OFFX, OFFY]
        #         },
        #         ...
        #       ],
        #       "animations": {
        #         NAME: {
        #           "frames": [[INDEX, DURATION], ...],
        #           "loop": LOOP
        #         },
        #         ...
        #       }
        #     }
        #
        # Note: `FILENAME` is a string containing the name of the
        # image to be used as the spritesheet, `[X, Y]` gives the
        # top-left corner of the frame described in the spritesheet,
        # `[W, H]` is the size of the frame, `[OFFX, OFFY]` is the
        # offset of the top left corner of the frame from the position
        # of the sprite (around which drawing flipped versions will
        # be based), `NAME` is a string naming an animation, `INDEX`
        # refers to the index of a frame, `DURATION` is how long that
        # frame should stay onscreen in seconds, and `LOOP` is true
        # or false depending on whether the animation should loop.
        load: (json_data, onload) ->
            {frames, animations} = json_data
            
            for name, animation of animations
                duration = 0
                for frame in animation.frames
                    duration += frame[1]
                animations[name].duration = duration
            
            @animations = animations
            sprite = this
            
            image = new Image()
            image.onload = ->
                sprite.setupFrames image, frames
                @loaded = true
                onload?()
            image.src = url_prefix + json_data.spritesheet
            return
        
        setupFrames: (img, frames) ->
            grabFrame = (frame) ->
                fw = frame.size[0]
                fh = frame.size[1]
                fcanvas = document.createElement 'canvas'
                fcanvas.width = fw
                fcanvas.height = fh
                fctx = fcanvas.getContext '2d'
                fctx.drawImage img, frame.pos[0], frame.pos[1],
                    fw, fh, 0, 0, fw, fh
                
                return fcanvas
            
            @frames = (grabFrame frame for frame in frames)
            @frame_offsets = (frame.offset for frame in frames)
            return
        
        startAnimation: (anim_name) ->
            @current_animation = @animations[anim_name]
            @animation_start_time = util.time()
            return
        
        draw: (context, x, y, flip_h) ->
            cur_anim = @current_animation
            cur_anim_dur = cur_anim.duration
            frame_index = -1
            anim_time = util.time() - @animation_start_time
            
            if cur_anim.loop
                anim_time %= cur_anim_dur
            else if anim_time > cur_anim_dur
                anim_time = cur_anim_dur
            
            for frame in cur_anim.frames
                anim_time -= frame[1]
                if anim_time <= 0
                    frame_index = frame[0]
                    break
            
            frame_img = @frames[frame_index]
            frame_offset = @frame_offsets[frame_index]
            
            context.save()
            
            context.translate (x + .5) | 0,
                (y + .5) | 0
            context.transform -1, 0, 0, 1, 0, 0 if flip_h
            context.drawImage frame_img,
                frame_offset[0], frame_offset[1]
            
            context.restore()
            
            return

