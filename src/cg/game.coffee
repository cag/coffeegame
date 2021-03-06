define ['./util', './input', './audio'], (util, input, audio) ->
    canvas = null
    context = null
    game_w = 0
    game_h = 0
    game_x_offset = 0
    game_y_offset = 0
    
    current_scene = null
    
    # Stores the last delta time
    last_dt = null
    
    # If delta time is fixed, this is set
    fixed_dt = null
    
    # A clamp is placed on delta time so tunneling may be avoided with
    # some careful planning by the developer.
    dt_clamp = 50
    paused = true

    # Lists of coroutines for executing coroutines
    update_coroutines = []
    draw_coroutines = []
    
    # Callbacks for keys are delegated to the input module.
    handleKeyDown = (event) ->
        input.handleKeyDown event.keyCode
        return
    
    handleKeyUp = (event) ->
        input.handleKeyUp event.keyCode
        return
    
    # Advances the execution state of a set of coroutines with a parameter
    advanceCoroutines = (coroutines, arg) ->
        for i in [coroutines.length-1..0] by -1
            coroutine = coroutines[i]
            coroutine.next arg
            if coroutine.done
                coroutines.splice(i, 1)
        return

    # Update call.
    update = (dt) ->
        input.update()
        current_scene.update dt
        advanceCoroutines update_coroutines, dt
        return
    
    # Draw call.
    draw = ->
        context.clearRect 0, 0, canvas.width, canvas.height
        context.save()
        context.translate game_x_offset, game_y_offset
        context.beginPath()
        context.rect 0, 0, game_w, game_h
        context.clip()

        current_scene.draw context
        advanceCoroutines draw_coroutines, context

        context.restore()
        return

    # Canvas resizing callback
    resizeCanvasToAspectRatio = ->
        if game_w / game_h < canvas.clientWidth / canvas.clientHeight
            canvas.width = game_h * canvas.clientWidth / canvas.clientHeight
            canvas.height = game_h
            game_x_offset = (0.5 * (canvas.width - game_w)) | 0
            game_y_offset = 0
        else
            canvas.width = game_w
            canvas.height = game_w * canvas.clientHeight / canvas.clientWidth
            game_x_offset = 0
            game_y_offset = (0.5 * (canvas.height - game_h)) | 0
        return
    resizeCanvasToAspectRatio: resizeCanvasToAspectRatio
    
    # Canvas instance.
    canvas: -> canvas
    
    # Game dimensions.
    width: -> game_w
    height: -> game_h
    
    # Last delta time.
    lastDt: -> last_dt

    # Current scene.
    currentScene: -> current_scene
    
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
        
        game_w = width
        game_h = height

        container.appendChild canvas
        resizeCanvasToAspectRatio()
        
        context = canvas.getContext '2d'
        
        document.body.tabIndex = 0
        document.body.focus()
        
        input.init()
        
        document.body.addEventListener 'keydown', handleKeyDown, false
        document.body.addEventListener 'keyup', handleKeyUp, false
        
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

    # Pushes a coroutine set onto the invocation stack.
    invoke: (coroutine_set) ->
        if coroutine_set.draw?
            draw_coroutines.push coroutine_set.draw
        if coroutine_set.update?
            update_coroutines.push coroutine_set.update
