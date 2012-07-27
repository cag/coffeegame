define ->
    time_offset = 0
    time_seen = 0
    
    # An implementation of insertion sort
    insertionSort = (ary, cmp = (a, b) ->
                    if a < b then -1 else if a == b then 0 else 1) ->
        for i in [1...ary.length]
            tmp = ary[i]
            j = i
            while j > 0 and (cmp ary[j - 1], tmp) > 0
                ary[j] = ary[j - 1]
                --j
            ary[j] = tmp
        return
    
    # requestAnimationFrame polyfill by Erik Möller
    # with fixes from Paul Irish and Tino Zijdel.
    #
    # CoffeeScript port by Jacob Rus
    do ->
        w = window
        for vendor in ['ms', 'moz', 'webkit', 'o']
            break if w.requestAnimationFrame
            w.requestAnimationFrame = w[vendor +
                'RequestAnimationFrame']
            w.cancelAnimationFrame = (w[vendor +
                'CancelAnimationFrame'] or
                w["#{vendor}CancelRequestAnimationFrame"])

        # Deal with the case where rAF is built in but cAF is not.
        if w.requestAnimationFrame
            return if w.cancelAnimationFrame
            browserRaf = w.requestAnimationFrame
            canceled = {}
            w.requestAnimationFrame = (callback) ->
                id = browserRaf (time) ->
                    if id of canceled then delete canceled[id]
                    else callback time
            w.cancelAnimationFrame = (id) -> canceled[id] = true

        # Handle legacy browsers which don’t implement rAF.
        else
            targetTime = 0
            w.requestAnimationFrame = (callback) ->
                targetTime = Math.max targetTime + 16, currentTime = +new Date
                w.setTimeout (-> callback +new Date), targetTime - currentTime

            w.cancelAnimationFrame = (id) -> clearTimeout id
        
        return
    
    # An epsilon for things involving real numbers and convergence.
    EPSILON: 1 / (Math.pow 2, 50)
    
    # A monotonic but slightly inaccurate timer in seconds.
    # Referenced Kevin Reid's implementation.
    time: ->
        t = Date.now()
        time_offset += time_seen - t if t < time_seen
        time_seen = t
        return .001 * (t + time_offset)
    
    # Insertion sort is used as a sort for arrays which don't change
    # order much between frames.
    persistentSort: insertionSort
    
    # Constructs a 32-bit bitmask from an array of values ranging from
    # 0 to 31 inclusive.
    constructBitmask: (group_array) ->
        mask = 0
        for group in group_array
            mask |= 1 << group
        return mask
    
    # Turns an RGB tuple into a web-friendly hex representation.
    rgbToHex: (r, g, b) ->
        toTwoDigitHex = (v) -> "00#{
            (Math.min (Math.max (Math.round v * 256), 0), 255).
                toString 16}".substr(-2)
        "##{toTwoDigitHex r}#{toTwoDigitHex g}#{toTwoDigitHex b}"

