define ['./geometry'], (geometry) ->
    # An entity which may be placed in a map and scripted with
    # update, draw, onCollide, and onObstruct callbacks.
    Entity: class
        constructor: (@x, @y, @shape) ->
        
        # Puts a subpath of its underlying collision primitive onto
        # the drawing context.
        shapeSubpath: (context, xoff, yoff) ->
            @shape.subpath context, @x + xoff, @y + yoff
            return
        
        # Detects if entity bounds are left of another's bounds.
        boundsLeftOf: (other) ->
            return @x + @shape.bounds_offsets[1] <
                other.x + other.shape.bounds_offsets[0]
    
        # Tests whether entity box bounds intersect.
        # This is useful for collision and drawing culling.
        boundsIntersects: (other) ->
            bounds_a = @shape.bounds_offsets
            bounds_b = other.shape.bounds_offsets
            
            return @x + bounds_a[0] <= other.x + bounds_b[1] and
                @x + bounds_a[1] >= other.x + bounds_b[0] and
                @y + bounds_a[2] <= other.y + bounds_b[3] and
                @y + bounds_a[3] >= other.y + bounds_b[2]
        
        # Tests whether entity intersects another entity.
        # Used when collision manager updates.
        intersects: (other) ->
            if @boundsIntersects other
                return geometry.intersects @x, other.x, @y, other.y,
                    @shape, other.shape
            return false

