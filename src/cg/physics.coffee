define ['./game'], (game) ->
    # Using ye old midpoint method
    integrate: (obj, dt) ->
        v = obj.velocity or [0, 0]
        a = obj.acceleration or [0, 0]
        last_a = obj.last_acceleration or a
        
        damping = obj.damping or 1
        
        v[0] *= damping
        v[1] *= damping
        
        obj.x = obj.x + v[0] * dt + a[0] * dt * dt
        obj.y = obj.y + v[1] * dt + a[1] * dt * dt
        
        v[0] = v[0] + a[0] * dt
        v[1] = v[1] + a[1] * dt
        
        obj.velocity = v
        return

