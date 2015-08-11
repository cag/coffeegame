define ->
    # These constants determine how debug drawing is rendered when
    # shape subpaths are being created.
    POINT_RADIUS = 2
    NORMAL_OFFSET = 4
    NORMAL_LENGTH = 2
    
    # This is currently the epsilon used to detect small differences
    # in normals.
    EPSILON = Math.pow 2, -50
    
    # Some basic linear algebra.
    dotProduct = (u, v) ->
        return u[0] * v[0] + u[1] * v[1]
    
    normalize = (v) ->
        invnorm = 1 / Math.sqrt (dotProduct v, v)
        return [invnorm * v[0], invnorm * v[1]]
    
    # Axis is assumed to be normalized so only a dot product is used
    # in the projection.
    projectShapeOntoAxis = (shape, axis) ->
        min = Number.POSITIVE_INFINITY
        max = Number.NEGATIVE_INFINITY
        
        stype = shape.type
        
        if stype == 'Point'
            min = 0
            max = 0
        else if stype == 'Aabb'
            hw_proj = dotProduct shape.halfwidth, axis
            if hw_proj < 0
                min = Math.min min, hw_proj
                max = Math.max max, -hw_proj
            else
                min = Math.min min, -hw_proj
                max = Math.max max, hw_proj
            
            hw_proj = dotProduct [
                    shape.halfwidth[0], -shape.halfwidth[1]
                ], axis
            if hw_proj < 0
                min = Math.min min, hw_proj
                max = Math.max max, -hw_proj
            else
                min = Math.min min, -hw_proj
                max = Math.max max, hw_proj
            
        else if stype == 'Polygon'
            pts = shape.points
            for point in pts
                pt_proj = dotProduct point, axis
                min = Math.min min, pt_proj
                max = Math.max max, pt_proj
        
        return [min, max]
    
    # This returns how much interval `b` should be displaced to render
    # the intervals disjoint (except maybe at a point).
    intervalsIntersect = (a, b) ->
        return false if a[1] < b[0] or b[1] < a[0]
        
        aoff = b[1] - a[0]
        boff = a[1] - b[0]
        
        return -aoff if aoff < boff
        return boff
    
    # Figures out how much shape is penetrating polygon. A penetration
    # amount and direction may be passed in order to continue a test
    # with data from prior analysis.
    calcShapePolygonMinimumPenetrationVector = (s, sx, sy, p, px, py,
      pen_amt = Number.POSITIVE_INFINITY,
      pen_dir,
      negate = false) ->
        for i in [0...p.normals.length] by 1
            normal = p.normals[i]
            p_bounds = p.bounds_on_normals[i]
            
            proj_s_pos = dotProduct [sx, sy], normal
            proj_p_pos = dotProduct [px, py], normal
            
            s_bounds = projectShapeOntoAxis s, normal
            
            intersects = intervalsIntersect [
                s_bounds[0] + proj_s_pos, s_bounds[1] + proj_s_pos], [
                p_bounds[0] + proj_p_pos, p_bounds[1] + proj_p_pos]
            
            return false unless intersects
            
            abs_intersects = Math.abs intersects
            
            if abs_intersects < pen_amt
                pen_amt = abs_intersects
                if negate is (intersects < 0)
                    pen_dir = normal
                else
                    pen_dir = [-normal[0], -normal[1]]
        
        return [pen_amt, pen_dir]
    
    # Finds bounds of the polygon. Equivalent to concatenating the
    # results of a polygon projection onto [1, 0] and [0, 1].
    calcPolyBounds = (points) ->
            minx = points[0][0]
            maxx = points[0][0]
            miny = points[0][1]
            maxy = points[0][1]
            for point in points
                minx = Math.min minx, point[0]
                maxx = Math.max maxx, point[0]
                miny = Math.min miny, point[1]
                maxy = Math.max maxy, point[1]
            return [minx, maxx, miny, maxy]
    
    # A whole bunch of individual types of shape intersection tests.
    # Polygons are assumed to be convex and use the hyperplane
    # separation theorem. Points and AABBs are simply special cases.
    testPointPointIntersection = (p1, p1x, p1y, p2, p2x, p2y) ->
        return [0, [1, 0]]
    
    testPointAabbIntersection = (p, px, py, a, ax, ay) ->
        pen_amt = ax + a.halfwidth[0] - px
        pen_dir = [-1, 0]
        
        next_proj = ay + a.halfwidth[1] - py
        if next_proj < pen_amt
            pen_amt = next_proj
            pen_dir = [0, -1]
        
        next_proj = px - (ax - a.halfwidth[0])
        if next_proj < pen_amt
            pen_amt = next_proj
            pen_dir = [1, 0]
        
        next_proj = py - (ay - a.halfwidth[1])
        if next_proj < pen_amt
            pen_amt = next_proj
            pen_dir = [0, 1]
        
        return [pen_amt, pen_dir]
    
    testPointPolygonIntersection = (p1, p1x, p1y, p2, p2x, p2y) ->
        return calcShapePolygonMinimumPenetrationVector \
            p1, p1x, p1y,
            p2, p2x, p2y
    
    testAabbAabbIntersection = (a1, a1x, a1y, a2, a2x, a2y) ->
        pen_amt = a2x + a2.halfwidth[0] - (a1x - a1.halfwidth[0])
        pen_dir = [-1, 0]
        
        next_proj = a2y + a2.halfwidth[1] - (a1y - a1.halfwidth[1])
        if next_proj < pen_amt
            pen_amt = next_proj
            pen_dir = [0, -1]
        
        next_proj = a1x + a1.halfwidth[0] - (a2x - a2.halfwidth[0])
        if next_proj < pen_amt
            pen_amt = next_proj
            pen_dir = [1, 0]
        
        next_proj = a1y + a1.halfwidth[1] - (a2y - a2.halfwidth[1])
        if next_proj < pen_amt
            pen_amt = next_proj
            pen_dir = [0, 1]
        
        return [pen_amt, pen_dir]
    
    testAabbPolygonIntersection = (a, ax, ay, p, px, py) ->
        intersects = intervalsIntersect [
            ax + a.bounds_offsets[0], ax + a.bounds_offsets[1]], [
            px + p.bounds_offsets[0], px + p.bounds_offsets[1]]
        
        if intersects < 0
            pen_amt = -intersects
            pen_dir = [-1, 0]
        else
            pen_amt = intersects
            pen_dir = [1, 0]
        
        intersects = intervalsIntersect [
            ay + a.bounds_offsets[2], ay + a.bounds_offsets[3]], [
            py + p.bounds_offsets[2], py + p.bounds_offsets[3]]
        
        if intersects < 0
            pen_amt = -intersects
            pen_dir = [0, -1]
        else
            pen_amt = intersects
            pen_dir = [0, 1]
        
        return calcShapePolygonMinimumPenetrationVector \
            a, ax, ay,
            p, px, py,
            pen_amt, pen_dir
    
    testPolygonPolygonIntersection = (p1, p1x, p1y, p2, p2x, p2y) ->
        ret = calcShapePolygonMinimumPenetrationVector \
            p1, p1x, p1y,
            p2, p2x, p2y
        
        if ret
            [pen_amt, pen_dir] = ret
        else
            return false
        
        return calcShapePolygonMinimumPenetrationVector \
            p2, p2x, p2y,
            p1, p1x, p1y,
            pen_amt, pen_dir, true
    
    # A mapping from pairs of shape types to the appropriate hit test.
    intersection_test_map =
        Point:
            Point: testPointPointIntersection
            Aabb: testPointAabbIntersection
            Polygon: testPointPolygonIntersection
        Aabb:
            Aabb: testAabbAabbIntersection
            Polygon: testAabbPolygonIntersection
        Polygon:
            Polygon: testPolygonPolygonIntersection
    
    dotProduct: dotProduct
    
    # A point.
    Point: class
        constructor: () ->
            @type = 'Point'
            @bounds_offsets = [0, 0, 0, 0]
            
        subpath: (context, offx, offy) ->
            context.moveTo offx + POINT_RADIUS, offy
            context.arc offx, offy, POINT_RADIUS, 0, 2 * Math.PI
            return
    
    # An axis-aligned bounding box.
    Aabb: class
        constructor: (@halfwidth) ->
            @type = 'Aabb'
            hw = @halfwidth
            @bounds_offsets = [-hw[0], hw[0], -hw[1], hw[1]]
            return
        
        subpath: (context, offx, offy) ->
            hw = @halfwidth
            context.rect offx - hw[0], offy - hw[1],
                2 * hw[0], 2 * hw[1]
            return
    
    # A *convex* polygon.
    Polygon: class
        constructor: (points) ->
            @type = 'Polygon'
            @bounds_offsets = calcPolyBounds points
            
            sumx = 0
            sumy = 0
            num_vertices = points.length
            for pt in points
                sumx += pt[0]
                sumy += pt[1]
            @center_offset = [sumx / num_vertices, sumy / num_vertices]
            
            ccw = null
            ptslen = points.length
            for i in [0...ptslen] by 1
                j = (i + 1) % ptslen
                k = (i + 2) % ptslen
                edge1 = [points[j][0] - points[i][0],
                    points[j][1] - points[i][1]]
                edge2 = [points[k][0] - points[j][0],
                    points[k][1] - points[j][1]]
                cross = edge1[0] * edge2[1] - edge2[0] * edge1[1]
                
                if ccw?
                    if ccw and cross > 0 or not ccw and cross < 0
                        throw 'tried to construct non-convex polygon'
                else
                    ccw = cross < 0
            
            if ccw
                @points = points.reverse()
            else
                @points = points
            
            normals = []
            bounds_on_normals = []
            for i in [0...ptslen] by 1
                j = (i + 1) % ptslen
                normal = normalize [@points[i][1] - @points[j][1],
                    @points[j][0] - @points[i][0]]
                
                skip = false
                for other in normals
                    if Math.abs(dotProduct normal, other) > 1 - EPSILON
                        skip = true
                        continue
                
                continue if skip
                
                bounds_on_normal = projectShapeOntoAxis this, normal
                
                normals.push normal
                bounds_on_normals.push bounds_on_normal
            
            @normals = normals
            @bounds_on_normals = bounds_on_normals
            
            return
        
        subpath: (context, offx, offy) ->
            pts = @points
            context.moveTo pts[0][0] + offx, pts[0][1] + offy
            for i in [1...pts.length] by 1
                context.lineTo pts[i][0] + offx, pts[i][1] + offy
            context.closePath()
            
            coffx = offx + @center_offset[0]
            coffy = offy + @center_offset[1]
            context.moveTo coffx + POINT_RADIUS, coffy
            context.arc coffx, coffy, POINT_RADIUS, 0, 2 * Math.PI
            
            for normal in @normals
                context.moveTo coffx + NORMAL_OFFSET * normal[0],
                    coffy + NORMAL_OFFSET * normal[1]
                context.lineTo coffx +
                    (NORMAL_LENGTH + NORMAL_OFFSET) * normal[0],
                    coffy + (NORMAL_LENGTH + NORMAL_OFFSET) * normal[1]
            
            return
    
    intersects: (x_a, x_b, y_a, y_b, shape_a, shape_b) ->
        test = intersection_test_map[shape_a.type]?[shape_b.type]
        
        if test?
            return test shape_a, x_a, y_a, shape_b, x_b, y_b
        else
            test = intersection_test_map[shape_b.type]?[shape_a.type]
            if test?
                result = test shape_b, x_b, y_b, shape_a, x_a, y_a
                if result
                    return [result[0], [-result[1][0], -result[1][1]]]
                else
                    return false
        
        throw "can't test #{shape_a.type} against #{shape_b.type}"
        return false

