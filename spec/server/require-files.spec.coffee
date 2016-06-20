fs = require 'fs'

walkFiles = (path, cb) ->
  list = fs.readdirSync(path)
  for item in list
    subPath = path + '/' + item
    stat = fs.lstatSync(subPath)
    if stat.isFile()
      cb(subPath)
    else if stat.isDirectory()
      walkFiles(subPath, cb)

describe 'each file in /server', ->
  it 'can be required', ->
    walkFiles 'server', (path) ->
      # TODO: These two files should not break on require in testing or dev
      if _.str.endsWith(path, 'LockManager.coffee')
        return
      if _.str.endsWith(path, 'picoctf.coffee')
        return
      if _.str.endsWith(path, '.coffee')
        requirePath = '../../'+path.slice(0, path.length-7)
        res = require(requirePath)
