fs = require 'fs'

print = console.log
{spawn} = require 'child_process'

outdir = 'js'

writeProcessData = (proc) ->
    proc.stderr.on 'data', (data) ->
        process.stderr.write data.toString()
    proc.stdout.on 'data', (data) ->
        print data.toString()
    return

bootstrapLib = (callback) ->
    cgfiles = fs.readdir 'src/cg', (err, files) ->
        if err?
            process.stderr.write err
        else
            pattern = /\.coffee$/
            sources = (file[..-8] for file in files when pattern.test file)
            srcstr = '# This is an auto-generated source file.\ndefine [' \
                + (("'cg/#{source}'" for source in sources).join ', ') + '], (' \
                + ((source for source in sources).join ', ') + ') ->\n' \
                + (("    #{source}: #{source}\n" for source in sources).reduce (a, b) -> a + b)
            fs.writeFile 'src/cg.coffee', srcstr, (error) ->
                if error
                    process.stderr.write 'Error writing file', error
                else
                    print 'Wrote cg.coffee'
                    callback?()

buildCoffee = (callback) ->
    coffee = spawn 'coffee', ['-c', '-o', outdir, 'src']
    writeProcessData coffee
    coffee.on 'exit', (code) ->
        callback?() if code is 0
    return

buildRequireJS = (callback) ->
    rjs = spawn 'r.js', ['-o', 'build.js']
    writeProcessData rjs
    rjs.on 'exit', (code) ->
        callback?() if code is 0
    return

buildDocco = (callback) ->
    pattern = /\.coffee$/
    srcfiles = fs.readdirSync 'src'
    cgfiles = fs.readdirSync 'src/cg'
    params = ('src/' + file for file in srcfiles when pattern.test file)\
        .concat('src/cg/' + file for file in cgfiles when pattern.test file)
        
    docco = spawn 'docco', params
    writeProcessData docco
    docco.on 'exit', (code) ->
        callback?() if code is 0
    return

task 'build', "Build #{outdir} from src/", ->
    bootstrapLib buildCoffee buildRequireJS buildDocco
    return

task 'watch', 'Watch src/ for changes', ->
    bootstrapLib ->
        coffee = spawn 'coffee', ['-w', '-c', '-o', outdir, 'src']
        writeProcessData coffee
    return

