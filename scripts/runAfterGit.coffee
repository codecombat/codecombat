# This is written in coffeescript. Run this using coffee, not node.           (Line to yield nice warnings on node. :))
return console.log '------------------------------------------------- \n

Commandline utility written in Coffeescript to run all updates, download latest database and install it after you git pushed. \n
Params: \n
\t--skipupdates skips npm and bower update \n
\t--dldb: download the latest database (Over 300 mb!) \n
\t--resetdb: to reset the database and load dump from tmp. Will need a downloaded database or --dbdownload specified \n
\t--mongopath <.path/to/mongo>: to specify mongodb folder if not set in PATH. \n
\t--help: Yo fund this one already. \n
\n
May need an initial npm install upfront if newly checked out. \n

' if '--help' in process.argv

#TODO: MD5 Verification, using http://23.21.59.137/dump.md5 using digest stream https://github.com/jeffbski/digest-stream
dbDump = 'http://23.21.59.137/dump.tar.gz' # Don't change this unless you know what you're doing
dbLocalPath = '../temp'

fs = require 'fs'
tar = require 'tar'
spawn = require('child_process').spawn
http = require 'http'
fs = require 'fs'
zlib = require 'zlib'
Deferred = require 'JQDeferred'

#TODO: Could kill current coco server here.

mongopath = ''
useNext = false
for path in process.argv
  if useNext
    mongopath = path
    break
  useNext = path is '--mongopath'
mongopath += '/bin/' if mongopath.length
mongopath += 'mongodb' # mongodb is in path.

run = (proc, args) ->
  deferred = Deferred()
  spawned = spawn proc, args
  spawned.stdout.on 'data', (data) -> process.stdout.write data
  spawned.stderr.on 'data', (data) -> process.stderr.write data
  spawned.on 'exit', (code) ->
    console.log proc + ' exited with code ' + code
    # unless code is null doesn't seem to work
    #  deferred.reject()
    deferred.resolve code
  spawned.on 'error', (code, error) ->
    console.error proc + ' failed!'
    deferred.reject()
  deferred.promise()

removeDir = (path) ->
  if fs.existsSync(path)
    fs.readdirSync(path).forEach (file) ->
      current = path + '/' + file
      if fs.lstatSync(current).isDirectory() # recurse
        removeDir current
      else # delete file
        fs.unlinkSync current
    fs.rmdirSync path

resetDB = ->
  deferred = Deferred()
  console.log 'Dropping Database'
  mongodrop = run 'mongo', ['coco', '--eval', 'db.dropDatabase()']
  mongodrop.fail -> console.error 'Error occurred while dropping mongo. Make sure CoCo\'s MongoDB is running.'
  mongodrop.done ->
    console.log 'Restoring from dump.'
    mongorestore = run 'mongorestore', [dbLocalPath]
    mongorestore.always = deferred.resolve()
  deferred.promise()

downloadDB = ->
  deferred = Deferred()
  #mongoose = require 'mongoose'
  # TODO: What if mongo is not running?
  console.log 'Downloading Database dump. It\'s big. This may take a while...'
  request = http.get dbDump, (response)->
    unzip = response.pipe(zlib.createGunzip()).pipe(tar.Extract(path: dbLocalPath))
    # Log download
    currentChunk = 0
    cur = 0
    len = parseInt(response.headers['content-length'], 10)
    total = len / 1048576 #1048576 - bytes in  1Megabyte
    response.on 'data', (chunk) ->
      cur += chunk.length
      console.log 'DB dump download received chunk ' + currentChunk++ + ', '  + (100.0 * cur / len).toFixed(2) + '% finished of ' + total.toFixed(0) + ' mb'
    unzip.on('data', -> console.log 'Unpacking zip...')
    unzip.on('error', (err) -> console.log 'An error occurred while downloading DB Dump: ' + err)
    unzip.on 'end', ->
      console.log 'Finished downloading.'
      deferred.resolve()
    deferred.promise()

installUpdates = ->
  deferred = Deferred()
  npm = if process.platform is 'win32' then 'npm.cmd' else 'npm'
  npminstall = run npm, ['update']
  npminstall.done ->
    bowerinstall = run 'bower', ['update']
    deferred.resolve()
  deferred.promise()

cleanUpTmp = ->
  removeDir dbLocalPath

unless '--skipupdates' in process.argv
  installUpdates()

if '--resetdb' in process.argv
  if '--dldb' in process.argv
    downloadDB().done ->
        resetDB().done ->
          cleanUpTmp() if '--cleanup' in process.argv
  else
    resetDB().done ->
      cleanUpTmp() if '--cleanup' in process.argv
else if '--dldb' in process.argv
  downloadDB()

# TODO: Could advice to start SCOCODE.bat et al. here
