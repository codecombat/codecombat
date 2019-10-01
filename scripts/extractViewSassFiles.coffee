readdirSync = require('recursive-readdir-sync')
fs = require 'fs'
_ = require 'lodash'

sassPaths = readdirSync('./app/styles')
sassMap = {}
usedSassFile = {}
sassPaths.forEach (path) =>
  code = fs.readFileSync(path).toString()
  code.split('\n').forEach (line) =>
    regex = /^#([^\., \(\)]+)/
    if regex.test(line)
      line.split(/ *, */).forEach (subline) =>
        id = subline.match(regex)[1]
        # console.log path, id
        sassMap[id] ?= []
        usedSassFile[path] = false
        if !_.contains(sassMap[id], path)
          sassMap[id].push(path)

          

console.log "this many sass IDs:", Object.keys(sassMap).length

viewPaths = readdirSync('./app/views')
viewPaths.forEach (path) =>
  code = fs.readFileSync(path).toString()
  code.split('\n').forEach (line) =>
    regex = /  id: ['"](.+)['"]/
    if regex.test(line)
      id = line.match(regex)[1]
      (sassMap[id] or []).forEach (sassPath) =>
        usedSassFile[sassPath] = true
        requireLine = "require('#{sassPath}')\n"
        newCode = requireLine + code
        if !_.contains(code, requireLine)
          # fs.writeFileSync(path, newCode)
          console.log "Will add #{sassPath} to #{path}"
          # process.exit()
      
console.log usedSassFile

console.log "These sass files don't have IDs:"
console.log _.difference(sassPaths, Object.keys(usedSassFile)).join('\n')
