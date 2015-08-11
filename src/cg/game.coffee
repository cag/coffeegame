define ['./util', './input', './audio'], (util, input, audio) ->
    canvas = null
    context = null
    canvas_w = 0
    canvas_h = 0
    
    current_scene = null
    
    # Stores the last delta time
    last_dt = null
    
    # If delta time is fixed, this is set
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
    
    # Update call.
    update = (dt) ->
        input.update()
        current_scene.update dt
        return
    
    # Draw call.
    draw = ->
        current_scene.draw context
        return
    
    # Canvas instance.
    canvas: -> canvas
    
    # Canvas dimensions.
    width: -> canvas_w
    height: -> canvas_h
    
    # Last delta time.
    lastDt: -> last_dt
    
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
            last_dt = fdt
        else if dtc?
            dt_clamp = dtc
            last_dt = dtc
        else
            last_dt = 1 / 60
        
        container = (document.getElementById 'game') or document.body
        canvas = document.createElement 'canvas'
        
        canvas.width = canvas_w = width
        canvas.height = canvas_h = height
        
        container.appendChild canvas
        
        context = canvas.getContext '2d'
        
        container.tabIndex = 0
        container.focus()
        
        input.init()
        
        container.addEventListener 'keydown', handleKeyDown, false
        container.addEventListener 'keyup', handleKeyUp, false
        
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
            draw()
        
        current_scene.start()
        gameLoop()
        return
