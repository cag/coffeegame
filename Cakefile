fs = require 'fs'

{print} = require 'util'
{spawn} = require 'child_process'

outdir = 'js'

writeProcessData = (proc) ->
    proc.stderr.on 'data', (data) ->
        process.stderr.write data.toString()
    proc.stdout.on 'data', (data) ->
        print data.toString()
    return

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
    files = fs.readdirSync 'src'
    params = ('src/' + file for file in files when pattern.test file)
        
    docco = spawn 'docco', params
    writeProcessData docco
    docco.on 'exit', (code) ->
        callback?() if code is 0
    return

task 'build', "Build #{outdir} from src/", ->
    buildCoffee buildRequireJS buildDocco
    return

task 'watch', 'Watch src/ for changes', ->
    coffee = spawn 'coffee', ['-w', '-c', '-o', outdir, 'src']
    writeProcessData coffee
    return

