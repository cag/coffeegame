define ['jquery', './game', './entity', './geometry', './util'],
  ($, game, entity, geometry, util) ->
    # A prefix and suffix applied to names passed into map constructors
    # so that it loads from the right place.
    url_prefix = 'assets/'
    url_suffix = '.json'
    
    # If `layers_cached` is true, then tiles will be cached in blocks
    # of `layer_cache_factor` square and the blocks will be drawn
    # instead of tiles.
    layers_cached = true
    layer_cache_factor = 16
    
    # Comparison helper functions for sorting entities.
    byLeftBound = (ent_a, ent_b) ->
        return ent_a.x + ent_a.shape.bounds_offsets[0] -
            ent_b.x - ent_b.shape.bounds_offsets[0]
    
    byBottomBound = (ent_a, ent_b) ->
        return ent_a.y + ent_a.shape.bounds_offsets[3] -
            ent_b.y - ent_b.shape.bounds_offsets[3]
    
    # This module expects maps created in [Tiled](http://www.mapeditor.org/)
    # and exported using the JSON option.
    # Refer to the [TMX Map Format](https://github.com/bjorn/tiled/wiki/TMX-Map-Format)
    # for information on how the map format works.
    class TileSet
        constructor: (json_data, onload) ->
            @name = json_data.name
            @first_gid = json_data.firstgid
            @tile_width = json_data.tilewidth
            @tile_height = json_data.tileheight
            @margin = json_data.margin
            @spacing = json_data.spacing
            @properties = json_data.properties
            
            tileset = this
            @image = new Image()
            @image.onload = ->
                iw = @naturalWidth
                ih = @naturalHeight
                if iw isnt json_data.imagewidth or
                   ih isnt json_data.imageheight
                    throw 'tileset ' + tileset.name +
                        ' dimension mismatch (' +
                        iw + 'x' + ih + ' vs ' +
                        @naturalWidth + 'x' + @naturalHeight + ')'
                
                tileset.setupTileMapping()
                onload?()
            @image.src = url_prefix + json_data.image
            return
        
        setupTileMapping: ->
            img = @image
            iw = img.naturalWidth
            ih = img.naturalHeight
            tw = @tile_width
            th = @tile_height
            
            margin = @margin
            twps = tw + @spacing
            thps = th + @spacing
            
            numtx = ((iw - margin) / twps) | 0
            numty = ((ih - margin) / thps) | 0
            @num_tiles = numt = numtx * numty
            
            grabTile = (xiter, yiter) ->
                tcanvas = document.createElement 'canvas'
                tcanvas.width = tw
                tcanvas.height = th
                
                sx = margin + xiter * twps
                sy = margin + yiter * thps
                
                tctx = tcanvas.getContext '2d'
                tctx.drawImage img, sx, sy, tw, th, 0, 0, tw, th
                
                return tcanvas
            
            @tiles = (grabTile i % numtx, (i / numtx) | 0 \
                for i in [0...numt])
            
            return
        
        hasGID: (gid) -> @first_gid <= gid < @first_gid + @num_tiles
        
        drawTile: (context, gid, flip_h, flip_v, flip_d, x, y) ->
            idx = gid - @first_gid
            tw = @tile_width
            th = @tile_height
            
            context.save()
            
            context.translate x, y
            context.transform -1, 0, 0, 1, tw, 0 if flip_h
            context.transform 1, 0, 0, -1, 0, th if flip_v
            context.transform 0, 1, 1, 0, 0, 0 if flip_d
            
            context.drawImage @tiles[idx], 0, 0
            
            context.restore()
            return
    
    class Layer
        constructor: (json_data, @map) ->
            @name = json_data.name
            @type = json_data.type
            @properties = json_data.properties
            @visible = json_data.visible
            @opacity = json_data.opacity
            @x = json_data.x
            @y = json_data.y
            @width = json_data.width
            @height = json_data.height
            return
    
    class TileLayer extends Layer
        constructor: (json_data, map) ->
            super json_data, map
            
            unless @type is 'tilelayer'
                throw "can't construct TileLayer from #{@type} layer"
            
            parseGID = (gid) ->
                flip_h = false
                # Javascript uses 32-bit signed bitwise ops, but
                # values are written to json unsigned in Tiled.
                if gid > 2147483648
                    flip_h = true
                    gid -= 2147483648
                flip_v = if gid & 1073741824 then true else false
                flip_d = if gid & 536870912 then true else false
                gid &= ~1610612736
                [gid, flip_h, flip_v, flip_d]
            
            width = @width
            height = @height
            @data = (parseGID(json_data.data[i + j * width]) \
                for j in [0...height] for i in [0...width])
            
            # Parallax can be set in tile layer properties in Tiled.
            if @properties?.parallax?
                @parallax = +@properties.parallax
            else
                @parallax = 1
            
            return
        
        buildCache: ->
            layer = this
            lcf = layer_cache_factor
            w = @width
            h = @height
            tw = @map.tilewidth
            th = @map.tileheight
            @cache_width = cw = Math.ceil(w / lcf)
            @cache_height = ch = Math.ceil(h / lcf)
            
            cacheBlock = (bi, bj) ->
                nbx = Math.min lcf, w - bi
                nby = Math.min lcf, h - bj
                
                canvas = document.createElement 'canvas'
                canvas.width = tw * nbx
                canvas.height = th * nby
                
                context = canvas.getContext '2d'
                layer.drawRaw context, bi, bi + nbx, bj, bj + nby, 0, 0
                
                return canvas
            
            @cache = (cacheBlock i * lcf, j * lcf \
                for j in [0...ch] by 1 \
                    for i in [0...cw] by 1)
            
            return
        
        setTile: (txi, tyi, td) ->
            @data[txi][tyi] = td
            if layers_cached
                map = @map
                lcf = layer_cache_factor
                ci = (txi / lcf) | 0
                cj = (tyi / lcf) | 0
                block = @cache[ci][cj]
                bxo = (txi % lcf) * map.tilewidth
                byo = (tyi % lcf) * map.tileheight
                context = block.getContext '2d'
                map.drawTile context,
                    td[0], td[1], td[2], td[3],
                    bxo, byo
            return

        drawRaw: (context, lowtx, hightx, lowty, highty, dx, dy) ->
            map = @map
            tw = map.tilewidth
            th = map.tileheight
            data = @data
            for i in [lowtx...hightx] by 1
                for j in [lowty...highty] by 1
                    datum = data[i][j]
                    map.drawTile context,
                        datum[0], datum[1], datum[2], datum[3],
                        dx + (i - lowtx) * tw,
                        dy + (j - lowty) * th
            return
        
        draw: (context, targx, targy) ->
            map = @map
            cam = map.camera
            cambounds = cam.shape.bounds_offsets
            
            tw = map.tilewidth
            th = map.tileheight
            
            mlcamxwp = cam.x * @parallax - @x * tw
            mlcamywp = cam.y * @parallax - @y * th
            
            w = cambounds[1] - cambounds[0]
            h = cambounds[3] - cambounds[2]
            
            destx = targx - mlcamxwp
            desty = targy - mlcamywp
            
            mlsx = mlcamxwp + cambounds[0]
            mlsy = mlcamywp + cambounds[2]
            
            context.save()
            
            context.beginPath()
            cam.shapeSubpath context, targx - cam.x, targy - cam.y
            context.clip()
            
            context.globalAlpha *= @opacity
            
            if layers_cached
                cache = @cache
                lcf = layer_cache_factor
                bw = tw * lcf
                bh = th * lcf
                lowbx = Math.max 0, (mlsx / bw) | 0
                highbx = Math.min @cache_width,
                    Math.ceil((mlsx + w) / bw)
                lowby = Math.max 0, (mlsy / bh) | 0
                highby = Math.min @cache_height,
                    Math.ceil((mlsy + h) / bh)
                
                for i in [lowbx...highbx] by 1
                    for j in [lowby...highby] by 1
                        context.drawImage cache[i][j],
                            Math.round(destx + i * bw),
                            Math.round(desty + j * bh)
            else
                lowtx = Math.max 0, (mlsx / tw) | 0
                hightx = Math.min @width, Math.ceil((mlsx + w) / tw)
                lowty = Math.max 0, (mlsy / th) | 0
                highty = Math.min @height, Math.ceil((mlsy + h) / th)
                
                @drawRaw context, lowtx, hightx, lowty, highty,
                    Math.round(destx + lowtx * tw),
                    Math.round(desty + lowty * th)
                
            context.restore()
            return
    
    class ObjectLayer extends Layer
        constructor: (json_data, map) ->
            # Bitmasks are created from a comma-separated list of
            # integers from 0-31. They are used to determine collision
            # groups for zones and obstruction groups.
            tryMakingBitmaskFromString = (bitmask_str) ->
                if bitmask_str?
                    return constructBitmask bitmask_str.split ','
                return 0
            
            tryGettingCallbackForName = (name) ->
                if name?
                    callback = map.script[name]
                    if callback?
                        return callback
                    else
                        throw "missing callback #{name}!"
                return null
            
            {Point, Aabb, Polyline, Polygon} = geometry
            {Entity} = entity
            {constructBitmask} = util
            
            super json_data, map
            
            unless @type is 'objectgroup'
                throw "can't construct ObjectLayer from #{@type} layer"
            
            objects = json_data.objects
            @entities = []
            mapents = map.entities
            
            l_collides = tryMakingBitmaskFromString \
                @properties?.collides
            l_onCollide = tryGettingCallbackForName \
                @properties?.onCollide
            
            l_obstructs = tryMakingBitmaskFromString \
                @properties?.obstructs
            l_onObstruct = tryGettingCallbackForName \
                @properties?.onObstruct
            
            setupEntityWithProperties = (ent, object) ->
                ent.onStart = tryGettingCallbackForName \
                    object.properties?.onStart
                
                # Object level callbacks take precedence over layer
                # level callbacks.
                
                obj_onCollide = tryGettingCallbackForName \
                    object.properties?.onCollide
                
                if obj_onCollide?
                    ent.onCollide = obj_onCollide
                else
                    ent.onCollide = l_onCollide
                
                obj_onObstruct = tryGettingCallbackForName \
                    object.properties?.onObstruct
                
                if obj_onObstruct?
                    ent.onObstruct = obj_onObstruct
                else
                    ent.onObstruct = l_onObstruct
                
                # These objects are assumed not to move, so they
                # may act as static obstructions/zones.
                ent.static = true
                
                # Bitmasks from the object and layer are combined.
                obj_collides = tryMakingBitmaskFromString \
                    object.properties?.collides
                ent.collides = l_collides | obj_collides
                
                obj_obstructs = tryMakingBitmaskFromString \
                    object.properties?.obstructs
                ent.obstructs = l_obstructs | obj_obstructs
                
                return
            
            for object in objects
                objx = object.x
                objy = object.y
                objw = object.width
                objh = object.height
                
                if object.polygon?
                    ent = new Entity objx, objy,
                        new Polygon ([point.x, point.y] \
                            for point in object.polygon)
                else if object.polyline?
                    # Polylines are modeled as multiple polygons.
                    for i in [0...object.polyline.length - 1] by 1
                        point_a = object.polyline[i]
                        point_b = object.polyline[i + 1]
                        ent = new Entity objx, objy,
                            new Polygon [[point_a.x, point_a.y],
                                [point_b.x, point_b.y]]
                        
                        setupEntityWithProperties ent, object
                        @addEntity ent
                    continue
                else if objw is 0 and objh is 0
                    ent = new Entity objx, objy, new Point
                else
                    objhwx = .5 * objw
                    objhwy = .5 * objh
                    ent = new Entity objx + objhwx, objy + objhwy,
                        new Aabb [objhwx, objhwy]
                
                setupEntityWithProperties ent, object
                @addEntity ent
            
            @entities.sort byBottomBound
            @onStart = tryGettingCallbackForName @properties?.onStart
            return
        
        addEntity: (ent) ->
            ent.layer = this
            ent.map = @map
            @entities.push ent
            @map.entities.push ent
        
        draw: (context, targx, targy) ->
            map = @map
            cam = map.camera
            
            xoff = targx - cam.x - @x * map.tilewidth
            yoff = targy - cam.y - @y * map.tileheight
            
            ents = @entities
            util.persistentSort ents, byBottomBound
            for ent in ents
                ent.draw? context, xoff, yoff
            return
        
        debugDraw: (context, targx, targy) ->
            map = @map
            cam = map.camera
            cambounds = cam.shape.bounds_offsets
            camlx = cam.x + cambounds[0]
            camly = cam.y + cambounds[2]
            w = cambounds[1] - cambounds[0]
            h = cambounds[3] - cambounds[2]
            destx = targx + cambounds[0]
            desty = targy + cambounds[2]
            
            xoff = destx - camlx - @x * @map.tilewidth
            yoff = desty - camly - @y * @map.tileheight
            
            context.save()
            context.beginPath()
            context.globalAlpha *= .75
            
            for ent in @entities
                if ent.boundsIntersects cam
                    ent.shapeSubpath context, xoff, yoff
            
            context.stroke()
            
            context.restore()
            return
    
    # Maps are loaded from a URL containing `@name` and callbacks are
    # searched for inside of the `@script` passed.
    Map: class
        constructor: (@name, @script, onload) ->
            @loaded = false
            @entities = []
            cb_target = this
            $.getJSON url_prefix + @name + url_suffix,
                ((data) -> cb_target.load(data, onload); return)
            return
        
        load: (json_data, onload) ->
            unless json_data.orientation is 'orthogonal'
                throw "orientation #{orientation} not supported"
            
            @width = json_data.width
            @height = json_data.height
            @tilewidth = json_data.tilewidth
            @tileheight = json_data.tileheight
            @orientation = json_data.orientation
            @properties = json_data.properties
            
            map = this
            
            createLayer = (data) ->
                {type} = data
                if type is 'tilelayer'
                    new TileLayer data, map
                else if type is 'objectgroup'
                    new ObjectLayer data, map
                else
                    console.warn "unknown layer type #{type} requested"
                    new Layer data, map
            
            @layers = (createLayer l for l in json_data.layers)
            
            {tilesets} = json_data
            tileset_load_total = tilesets.length
            tileset_load_count = 0
            ts_load_cb = ->
                if ++tileset_load_count >= tileset_load_total
                    map.buildLayerCaches() if layers_cached
                    map.loaded = true
                    onload?()
                return
            
            @tilesets = (new TileSet ts, ts_load_cb for ts in tilesets)
            
            @entities.sort byLeftBound
            return
        
        buildLayerCaches: ->
            for layer in @layers when layer.type is 'tilelayer'
                layer.buildCache()
            return
        
        drawTile: (context, gid, flip_h, flip_v, flip_d, x, y) ->
            for tileset in @tilesets
                if tileset.hasGID gid
                    tileset.drawTile context,
                        gid, flip_h, flip_v, flip_d, x, y
                    break
            return
        
        doCollisions: ->
            ents = @entities
            util.persistentSort ents, byLeftBound
            j = 0
            for i in [1...ents.length] by 1
                enti = @entities[i]
                
                while j < i and
                  ents[j].x + ents[j].shape.bounds_offsets[1] <
                  enti.x + enti.shape.bounds_offsets[0]
                    ++j
                
                for k in [j...i] by 1
                    @doCollision enti, @entities[k]
            
            return
        
        doCollision: (ent_a, ent_b) ->
            return if ent_a.static and ent_b.static
            
            can_collide = (ent_a.collides & ent_b.collides)
            can_obstruct = (ent_a.obstructs & ent_b.obstructs)
            
            return unless can_collide or can_obstruct
            
            collision_info = ent_a.intersects ent_b
            
            if collision_info
                [pen_amt, pen_dir] = collision_info
                
                neg_collision_info = 
                    [pen_amt, [-pen_dir[0], -pen_dir[1]]]
                
                ent_a.onCollide? ent_b, collision_info
                ent_b.onCollide? ent_a, neg_collision_info
                
                if can_obstruct
                    proj_x = pen_amt * pen_dir[0]
                    proj_y = pen_amt * pen_dir[1]
                    if ent_a.static
                        ent_b.x += proj_x
                        ent_b.y += proj_y
                    else if ent_b.static
                        ent_a.x -= proj_x
                        ent_a.y -= proj_y
                    else
                        # For now, splits the resolution 50-50 between
                        # dynamic objects.
                        rat = .5
                        notrat = 1 - rat
                        
                        ent_a.x -= rat * proj_x
                        ent_a.y -= rat * proj_y
                        ent_b.x += notrat * proj_x
                        ent_b.y += notrat * proj_y
                    
                    ent_a.onObstruct? ent_b, collision_info
                    ent_b.onObstruct? ent_a, neg_collision_info
            return

        # Gets a layer by name. Returns null if the layer is not found.
        getLayerByName: (name) ->
            for layer in @layers
                return layer if layer.name is name
            return null
        
        start: ->
            for layer in @layers
                layer.onStart? layer
            for ent in @entities
                ent.onStart? ent
            return
        
        update: (dt) ->
            for ent in @entities
                ent.update? dt
            @doCollisions()
            @camera.post_update? dt
            return
        
        draw: (context, targx, targy) ->
            for layer in @layers
                layer.draw context, targx, targy
            return
        
        debugDraw: (context, targx, targy) ->
            cam = @camera
            xoff = targx - cam.x
            yoff = targy - cam.y
            
            found_first = false
            for i in [0...@entities.length] by 1
                ent = @entities[i]
                if ent.boundsIntersects cam
                    ent.shapeSubpath context, xoff, yoff
                    found_first = true
                else if found_first and cam.boundsLeftOf ent
                    break
            
            for layer in @layers when layer.type is 'objectgroup'
                layer.debugDraw context, targx, targy
            
            return
    
    # A scene for running a map.
    MapScene: class
        constructor: (@map) ->
            return
        
        start: ->
            throw "#{@map.name} not loaded!" unless @map.loaded
            {Entity} = entity
            {Aabb} = geometry
            
            # Camera is initially positioned at the origin.
            @map.camera = new Entity 0, 0,
                new Aabb [.5 * game.width(), .5 * game.height()]
            
            @map.entities.push @map.camera
            
            @map.start()
            return
        
        end: ->
        
        update: (dt) ->
            @map.update dt
            return
        
        draw: (context) ->
            gw = game.width()
            gh = game.height()
            hgw = .5 * gw
            hgh = .5 * gh
            
            context.clearRect 0, 0, gw, gh
            context.beginPath()
            
            @map.draw context, hgw, hgh
            # @map.debugDraw context, hgw, hgh
            
            return

