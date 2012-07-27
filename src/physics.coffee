define ['./game'], (game) ->
    # Thanks to Jonathan "lonesock" Dummer for information on
    # [Time-Corrected Verlet integration](http://lonesock.net/article/verlet.html).
    #
    # The integration step is:
    #
    # `next_x = x + (x - last_x) * (dt / last_dt) + a * dt^2`
    #
    # Last acceleration is stored in order to determine velocity.
    integrate: (obj, dt) ->
        inv_last_dt = game.invLastDt()
        
        last_x = obj.last_x or obj.x
        last_y = obj.last_y or obj.y
        
        a = obj.acceleration or [0, 0]
        damping = obj.damping or 1
        
        obj.last_x = obj.x
        obj.last_y = obj.y
        
        obj.x = obj.x +
            (obj.x - last_x) * dt * inv_last_dt * damping +
            a[0] * dt * dt
        obj.y = obj.y +
            (obj.y - last_y) * dt * inv_last_dt * damping +
            a[1] * dt * dt
        
        obj.last_acceleration = a
        return
    
    # Velocity has to be inferred from the derivation. In particular:
    #
    # `x - last_x = (v - .5 * last_a * last_dt) * last_dt`
    #
    # Therefore
    #
    # `v = (x - last_x) / last_dt + .5 * last_a * last_dt`
    getVelocity: (obj, dt) ->
        last_dt = game.lastDt()
        inv_last_dt = game.invLastDt()
        
        last_x = obj.last_x or obj.x
        last_y = obj.last_y or obj.y
        
        last_a = obj.last_acceleration or [0, 0]
        
        return [
            (obj.x - last_x) * inv_last_dt + .5 * last_a[0] * last_dt,
            (obj.y - last_y) * inv_last_dt + .5 * last_a[1] * last_dt
        ]
    
    # Furthermore, in order to set velocity, `last_x` is the parameter
    # which needs to be changed, and so
    #
    # `last_x = x - (v - .5 * last_a * last_dt) * last_dt`
    setVelocity: (obj, v, dt) ->
        last_dt = game.lastDt()
        last_a = obj.last_acceleration or [0, 0]
        
        obj.last_x = obj.x -
            (v[0] - .5 * last_a[0] * last_dt) * last_dt
        obj.last_y = obj.y -
            (v[1] - .5 * last_a[1] * last_dt) * last_dt
        return

