define ['./util', './input', './audio'], (util, input, audio) ->
    canvas = null
    context = null
    canvas_w = 0
    canvas_h = 0
    
    current_scene = null
    
    # The last frame's delta time is cached in case variable-time
    # updating is used so the time-corrected Verlet integration works.
    last_dt = null
    inv_last_dt = null
    fixed_dt = null
    
    # A clamp is placed on delta time so tunneling may be avoided with
    # some careful planning by the developer.
    dt_clamp = 50
    paused = true
    
    # Callbacks for keys are delegated to the input module.
    handleKeyDown = (event) ->
        input.handleKeyDown event.keyCode
        return
    
    handleKeyUp = (event) ->
        input.handleKeyUp event.keyCode
        return
    
    # Input state is resolved before each update call on the scene.
    update = (dt) ->
        input.update()
        current_scene.update dt
        return
    
    draw = ->
        current_scene.draw context
        return
    
    # Canvas dimensions.
    width: -> canvas_w
    height: -> canvas_h
    
    lastDt: -> last_dt
    invLastDt: -> inv_last_dt
    
    # Switch scene to new scene.
    switchScene: (new_scene) ->
        throw 'cannot switch to nonexistent scene' unless new_scene?
        current_scene.end()
        current_scene = new_scene
        current_scene.start()
        return
    
    # Initialize the game with the specified parameters. Pass in null
    # for `fdt` (fixed delta-time) in order to initialize in variable
    # delta-time mode. `dtc` clamps the delta time, and `initial_scene`
    # is the first scene to start the game with.
    init: (width, height, fdt, dtc, initial_scene) ->
        current_scene = initial_scene
        
        if fdt?
            fixed_dt = fdt
            last_dt = fixed_dt
            inv_last_dt = 1 / fixed_dt
        else if dtc?
            dt_clamp = dtc
            last_dt = dt_clamp
            inv_last_dt = 1 / dt_clamp
        else
            last_dt = 1 / 60
            inv_last_dt = 60
        
        canvas = document.createElement 'canvas'
        canvas.width = canvas_w = width
        canvas.height = canvas_h = height
        canvas.tabIndex = 1
        
        context = canvas.getContext '2d'
        
        document.body.appendChild canvas
        
        canvas.focus()
        
        input.init()
        
        canvas.addEventListener 'keydown', handleKeyDown, false
        canvas.addEventListener 'keyup', handleKeyUp, false
        
        audio.init()
        return
    
    # Runs the game loop, starting the scene and calling update and
    # draw when appropriate.
    run: () ->
        throw 'no current scene!' unless current_scene?
        
        {requestAnimationFrame} = window
        {time} = util
        
        last_frame = time()
        dt_accumulator = 0
        paused = false
        
        gameLoop = ->
            requestAnimationFrame gameLoop unless paused
            now = time()
            dt = now - last_frame
            dt = if dt > dt_clamp then dt_clamp else dt
            last_frame = now
            if fixed_dt?
                dt_accumulator += dt
                while dt_accumulator > fixed_dt
                    update fixed_dt
                    dt_accumulator -= fixed_dt
            else
                update dt
                last_dt = dt
                inv_last_dt = 1 / dt
            draw()
        
        current_scene.start()
        gameLoop()
        return

