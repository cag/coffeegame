define ->
    # A map of button names to key code values.
    buttons:
        left: 37,
        up: 38,
        right: 39,
        down: 40,
        run: 16,
        jump: 90,
        debug: 192
    
    init: ->
        for button of @buttons
            this[button] = {}
    
    update: ->
        # Each button's pressed and released states stay true for only
        # up to one frame per press.
        updateInputHash = (hash) ->
            if hash.state
                if hash.last_state
                    hash.pressed = false
                else
                    hash.pressed = true
            else
                if hash.last_state
                    hash.released = true
                else
                    hash.released = false
            
            hash.last_state = hash.state
            return
        
        for button of @buttons
            updateInputHash this[button]
        
        return
    
    handleKeyDown: (keyCode) ->
        for button, bcode of @buttons when keyCode is bcode
            this[button].state = true
        return
    
    handleKeyUp: (keyCode) ->
        for button, bcode of @buttons when keyCode is bcode
            this[button].state = false
        return

