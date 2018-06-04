Grid = require 'gridfs-stream'
fs = require 'fs'
request = require 'request'
mongoose = require 'mongoose'
errors = require '../commons/errors'
config = require '../../server_config'
co = require 'co'
wrap = require 'co-express'
Promise = require 'bluebird'

module.exports.setup = (app) ->
  app.get '/file*', fileGet
  app.post '/file*', filePost
  app.delete '/file*', fileDelete
  app.all '/files*', (req, res) ->
    errors.badMethod(res, ['GET', 'POST', 'DELETE'])

fileDelete = (req, res) ->
  return errors.forbidden(res) unless req.user

  if req.body._id
    query = { _id: mongoose.Types.ObjectId(req.body._id) }
  else
    query = parsePathIntoQuery(req.path)
    return errors.badInput(res) if not query.filename

  Grid.gfs.collection('media').findOne query, (err, filedata) =>
    return errors.notFound(res) if not filedata
    return errors.forbidden(res) unless userCanEditFile(req.user, filedata)
    Grid.gfs.remove {_id: filedata._id, root: 'media'}, (err) ->
      return errors.serverError(res) if err
      return res.end()

fileGet = (req, res) ->
  query = parsePathIntoQuery(req.path)

  if not query.filename # it's a folder, return folder contents
    Grid.gfs.collection('media').find query, (err, cursor) ->
      return errors.serverError(res) if err
      results = cursor.toArray (err, results) ->
        return errors.serverError(res) if err
        res.setHeader('Content-Type', 'text/json')
        res.send(results)
        res.end()

  else # it's a single file
    # TODO: remove all files that start with db/user. This is a soft stop to make sure it doesn't affect anything.
    if _.startsWith(query['metadata.path'], 'db/user')
      res.status(404)
      return res.end()

    Grid.gfs.collection('media').findOne query, (err, filedata) =>
      return errors.notFound(res) if not filedata
      readstream = Grid.gfs.createReadStream({_id: filedata._id, root: 'media'})
      if req.headers['if-modified-since'] is filedata.uploadDate
        res.status(304)
        return res.end()

      res.setHeader('Content-Type', filedata.contentType)
      res.setHeader('Last-Modified', filedata.uploadDate.toUTCString())
      res.setHeader('Cache-Control', 'public')
      readstream.pipe(res)
      handleStreamEnd(res, res)

parsePathIntoQuery = (path) ->
  path = path[6..]
  path = decodeURI path
  try
    objectId = mongoose.Types.ObjectId(path)
    query = objectId
  catch e
    path = path.split('/')
    filename = path[path.length-1]
    path = path[...path.length-1].join('/')
    query =
      'metadata.path': path
    query.filename = filename if filename

  query

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

filePost = wrap (req, res) ->
  return errors.forbidden(res) unless req.user
  options = req.body
  tv4 = require('tv4').tv4
  valid = tv4.validate(options, postFileSchema)
  hasSource = options.url or options.postName or options.b64png
  # TODO : give tv4.error  to badInput
  unless req.user?.hasPermission('artisan')
    throw new errors.UnprocessableEntity("Bad file path: #{req.user.id}")
  return errors.badInput(res) if (not valid) or (not hasSource)
  return yield saveURL(req, res) if options.url
  return savePNG(req, res) if options.b64png

saveURL = co.wrap (req, res) ->
  options = createPostOptions(req)
  unless _.str.startsWith(req.body.url, 'https://www.filepicker.io/api/file/')
    throw new errors.UnprocessableEntity('Only files uploaded through filepicker are allowed.')
  [filePickerResponse] = yield request.getAsync(req.body.url + '/metadata', {json: true})
  unless filePickerResponse.statusCode is 200
    throw new errors.NotFound("Could not find filepicker metadata.")
  unless req.user?.hasPermission('artisan')
    unless /^image\/.*$/.test(filePickerResponse.body.mimetype)
      throw new errors.UnprocessableEntity("Unsupported image mimetype: #{req.body.mimetype}")
    if filePickerResponse.body.size > Math.pow(2, 10*2) # one megabyte
      throw new errors.UnprocessableEntity("File too large: #{filePickerResponse.body.size} bytes")
  try
    yield Promise.promisify(checkExistence)(options, req, res, req.body.force)
  catch err
    return errors.serverError(res)
  writestream = Grid.gfs.createWriteStream(options)
  request(req.body.url).pipe(writestream)
  handleStreamEnd(res, writestream)

savePNG = (req, res) ->
  options = createPostOptions(req)
  unless /^image\/png$/.test(req.body.mimetype)
    throw new errors.UnprocessableEntity("Only image/png mimetype allowed with base64 encoding.")
  if req.body.b64png.length > Math.pow(2, 10 * 10*2) # ten megabytes
    throw new errors.UnprocessableEntity("File too large: #{filePickerResponse.body.size} bytes")
  checkExistence options, req, res, req.body.force, (err) ->
    return if err
    writestream = Grid.gfs.createWriteStream(options)
    img = new Buffer(req.body.b64png, 'base64')
    streamBuffers = require 'stream-buffers'
    myReadableStreamBuffer = new streamBuffers.ReadableStreamBuffer({frequency: 10, chunkSize: 2048})
    myReadableStreamBuffer.put(img)
    myReadableStreamBuffer.pipe(writestream)
    handleStreamEnd(res, writestream)

userCanEditFile = (user=null, file=null) ->
  # no user means 'anyone'. No file means 'any file'
  return false unless user
  return true if user.isAdmin() or user.isArtisan()
  return false unless file
  return true if file.metadata.creator is user.id
  return false

checkExistence = (options, req, res, force, done) ->
  q = {
    filename: options.filename
    'metadata.path': options.metadata.path
  }
  Grid.gfs.collection('media').find(q).toArray (err, files) ->
    file = files[0]
    if file and ((not userCanEditFile(req.user, file) or (not force)))
      errors.conflict(res, {canForce: userCanEditFile(req.user, file)})
      done(true)
    else if file
      fullPath = "/file/#{options.metadata.path}/#{options.filename}"
      clearCloudFlareCacheForFile(fullPath)
      q = { _id: file._id }
      q.root = 'media'
      Grid.gfs.remove q, (err) ->
        if err
          errors.serverError(res)
          return done(true)
        done()
    else
      done()

handleStreamEnd = (res, stream) ->
  stream.on 'close', (f) ->
    res.send(f)
    res.end()

  stream.on 'error', ->
    return errors.serverError(res)

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

clearCloudFlareCacheForFile = (path='/file') ->
  unless config.cloudflare.token or config.cloudflare.email
    console.log 'skipping clearing cloud cache, not configured'
    return

  request = require 'request'

  cloudflareAPIV4 = "https://api.cloudflare.com/client/v4"
  cloudflareZoneIdentifier = "2288a1f5dc397aac278e76f657a3c5ec"
  cloudflareAPIURL = "#{cloudflareAPIV4}/zones/#{cloudflareZoneIdentifier}/purge_cache"
  options =
    url: cloudflareAPIURL,
    json: true
    body:
      "files": ["http://codecombat.com#{path}"]
    headers:
      'X-Auth-Email': config.cloudflare.email
      'X-Auth-Key': config.cloudflare.token
      'Content-Type': 'application/json'
  request.post options, (err, httpResponse, body) ->
    if (err)
      console.error('CloudFlare file cache clear failed:', body)
