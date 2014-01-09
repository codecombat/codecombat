winston = require 'winston'
Grid = require 'gridfs-stream'
fs = require 'fs'
request = require 'request'
mongoose = require('mongoose')

module.exports.setupRoutes = (app) ->
  app.all '/file*', (req, res) ->
    return fileGet(req, res) if req.route.method is 'get'
    return filePost(req, res) if req.route.method is 'post'
    return returnBadMethod(res)


fileGet = (req, res) ->
  path = req.path[6..]
  isFolder = false
  try
    objectId = mongoose.Types.ObjectId(path)
    query = objectId
  catch e
    path = path.split('/')    
    filename = path[path.length-1]
    path = path[...path.length-1].join('/')
    query =
      'metadata.path': path
    if filename then query.filename = filename else isFolder = true

  if isFolder
    Grid.gfs.collection('media').find query, (err, cursor) ->
      return returnServerError(res) if err
      results = cursor.toArray (err, results) ->
        return returnServerError(res) if err
        res.setHeader('Content-Type', 'text/json')
        res.send(results)
        res.end()
        
  else
    Grid.gfs.collection('media').findOne query, (err, filedata) =>
      return returnNotFound(req, res) if not filedata
      readstream = Grid.gfs.createReadStream({_id: filedata._id, root:'media'})
      if req.headers['if-modified-since'] is filedata.uploadDate
        res.status(304)
        return res.end()
  
      res.setHeader('Content-Type', filedata.contentType)
      res.setHeader('Last-Modified', filedata.uploadDate)
      res.setHeader('Cache-Control', 'public')
      readstream.pipe(res)
      handleStreamEnd(res, res)

postFileSchema =
  type: 'object'
  properties:
    # source
    url: { type: 'string', description: 'The url to download the file from.' }
    postName: { type: 'string', description: 'The input field this file was sent on.' }
    b64png: { type: 'string', description: 'Raw png data to upload.' }

    # options
    force: { type: 'string', 'default': '', description: 'Whether to overwrite existing files (as opposed to throwing an error).' }

    # metadata
    filename: { type: 'string', description: 'What the file will be named in the system.' }
    mimetype: { type: 'string' }
    name: { type: 'string', description: 'Human readable and searchable string.' }
    description: { type: 'string' }
    path: { type: 'string', description: 'What "folder" this file goes into.' }

  required: ['filename', 'mimetype', 'path']

filePost = (req, res) ->
  return returnNotAllowed(req, res) unless req.user.isAdmin()
  options = req.body
  tv4 = require('tv4').tv4
  valid = tv4.validate(options, postFileSchema)
  hasSource = options.url or options.postName or options.b64png
  return returnBadInput(res) if (not valid) or (not hasSource)
  return saveURL(req, res) if options.url
  return saveFile(req, res) if options.postName
  return savePNG(req, res) if options.b64png

saveURL = (req, res) ->
  options = createPostOptions(req)
  checkExistence options, res, req.body.force, (err) ->
    return returnServerError(res) if err
    writestream = Grid.gfs.createWriteStream(options)
    request(req.body.url).pipe(writestream)
    handleStreamEnd(res, writestream)

saveFile = (req, res) ->
  options = createPostOptions(req)
  checkExistence options, res, req.body.force, (err) ->
    return if err
    writestream = Grid.gfs.createWriteStream(options)
    f = req.files[req.body.postName]
    fileStream = fs.createReadStream(f.path)
    fileStream.pipe(writestream)
    handleStreamEnd(res, writestream)

savePNG = (req, res) ->
  options = createPostOptions(req)
  checkExistence options, res, req.body.force, (err) ->
    return returnServerError(res) if err
    writestream = Grid.gfs.createWriteStream(options)
    img = new Buffer(req.body.b64png, 'base64')
    streamBuffers = require 'stream-buffers'
    myReadableStreamBuffer = new streamBuffers.ReadableStreamBuffer({frequency: 10,chunkSize: 2048})
    myReadableStreamBuffer.put(img)
    myReadableStreamBuffer.pipe(writestream)
    handleStreamEnd(res, writestream)

checkExistence = (options, res, force, done) ->
  q = {
    filename: options.filename
    'metadata.path': options.metadata.path
  }
  Grid.gfs.collection('media').find(q).toArray (err, files) ->
    if files.length and not force
      returnConflict(res)
      done(true)
    else if files.length
      q = { _id: files[0]._id }
      q.root = 'media'
      Grid.gfs.remove q, (err) ->
        return returnServerError(res) if err
        done()
    else
      done()

handleStreamEnd = (res, stream) ->
  stream.on 'close', (f) ->
    res.send(f)
    res.end()

  stream.on 'error', ->
    return returnServerError(res)

CHUNK_SIZE = 1024*256

createPostOptions = (req) ->
  unless req.body.name
    name = req.body.filename.split('.')[0]
    req.body.name = _.str.humanize(name)
  
  path = req.body.path or ''
  path = path[1...] if path and path[0] is '/'
  path = path[...path.length-2] if path and path[path.length-1] is '/'
  
  options =
    mode: 'w'
    filename: req.body.filename
    chunk_size: CHUNK_SIZE
    root: 'media'
    content_type: req.body.mimetype
    metadata:
      name: req.body.name
      path: path
      creator: ''+req.user._id
  options.metadata.description = req.body.description if req.body.description? 

  options

returnNotAllowed = (req, res, message) ->
  res.status(403)
  message = "Can't do that, Dave." unless message
  res.write(message)
  res.end()
  
returnNotFound = (req, res, message) ->
  res.status(404)
  message = "Route #{req.path} not found." unless message
  res.write(message)
  res.end()

returnBadMethod = (res) ->
  res.status(405)
  res.send('Method not allowed.')
  res.end()

returnBadInput = (res) ->
  res.status(422)
  res.send('Bad post input.')
  res.end()

returnConflict = (res) ->
  res.status(409)
  res.send('File exists.')
  res.end()

returnServerError = (res) ->
  res.status(500)
  res.send('Server error.')
  res.end()