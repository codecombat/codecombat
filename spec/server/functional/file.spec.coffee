#require '../common'
#
## Doesn't work on Travis. Need to figure out why, probably by having the
## url not depend on some external resource.
#mongoose = require 'mongoose'
#request = require '../request'
#
#xdescribe '/file', ->
#  url = getURL('/file')
#  files = []
#  options = {
#    uri: url
#    json: {
#      # url: 'http://scotterickson.info/images/where-are-you.jpg'
#      url: 'http://fc07.deviantart.net/fs37/f/2008/283/5/1/Chu_Chu_Pikachu_by_angelishi.gif'
#      filename: 'where-are-you.jpg'
#      mimetype: 'image/jpeg'
#      description: 'None!'
#    }
#  }
#  filepath = 'tmp/file' # TODO Warning hard coded path !!!
#
#  jsonOptions= {
#    path: 'my_path'
#    postName: 'my_buffer'
#    filename: 'ittybitty.data'
#    mimetype: 'application/octet-stream'
#    description: 'rando-info'
#    # my_buffer_url: 'http://scotterickson.info/images/where-are-you.jpg'
#    my_buffer_url: 'http://fc07.deviantart.net/fs37/f/2008/283/5/1/Chu_Chu_Pikachu_by_angelishi.gif'
#  }
#
#  allowHeader = 'GET, POST'
#
#  it 'preparing test : deletes all the files first', (done) ->
#    dropGridFS ->
#      done()
#
#  it 'can\'t be created if invalid (property path is required)', (done) ->
#    func = (err, res, body) ->
#      expect(res.statusCode).toBe(422)
#      done()
#
#    loginAdmin  ->
#      request.post(options, func)
#
#  it 'can be created by an admin', (done) ->
#    func = (err, res, body) ->
#      expect(res.statusCode).toBe(200)
#      expect(body._id).toBeDefined()
#      expect(body.filename).toBe(options.json.filename)
#      expect(body.contentType).toBe(options.json.mimetype)
#      expect(body.length).toBeDefined()
#      expect(body.uploadDate).toBeDefined()
#      expect(body.metadata).toBeDefined()
#      expect(body.metadata.name).toBeDefined()
#      expect(body.metadata.path).toBe(options.json.path)
#      expect(body.metadata.creator).toBeDefined()
#      expect(body.metadata.description).toBe(options.json.description)
#      expect(body.md5).toBeDefined()
#      files.push(body)
#      done()
#
#    options.json.path = filepath
#    request.post(options, func)
#
#  it 'can be read by an admin.', (done) ->
#    request.get {uri: url+'/'+files[0]._id}, (err, res) ->
#      expect(res.statusCode).toBe(200)
#      expect(res.headers['content-type']).toBe(files[0].contentType)
#      done()
#
#  it 'returns 404 for missing files', (done) ->
#    id = '000000000000000000000000'
#    request.get {uri: url+'/'+id}, (err, res) ->
#      expect(res.statusCode).toBe(404)
#      done()
#
#  it 'returns 404 for invalid ids', (done) ->
#    request.get {uri: url+'/thiswillnotwork'}, (err, res) ->
#      expect(res.statusCode).toBe(404)
#      done()
#
#  it 'can be created directly with form parameters', (done) ->
#    options2 = {
#      uri: url
#    }
#
#    func = (err, res, body) ->
#      expect(res.statusCode).toBe(200)
#      body = JSON.parse(body)
#      expect(body._id).toBeDefined()
#      expect(body.filename).toBe(jsonOptions.filename)
#      expect(body.contentType).toBe(jsonOptions.mimetype)
#      expect(body.length).toBeDefined()
#      expect(body.uploadDate).toBeDefined()
#      expect(body.metadata).toBeDefined()
#      expect(body.metadata.name).toBeDefined()
#      expect(body.metadata.path).toBe(jsonOptions.path)
#      expect(body.metadata.creator).toBeDefined()
#      expect(body.metadata.description).toBe(jsonOptions.description)
#      expect(body.md5).toBeDefined()
#      files.push(body)
#      done()
#
#    # the only way I could figure out how to get request to do what I wanted...
#    r = request.post(options2, func)
#    form = r.form()
#    form.append('path', jsonOptions.path)
#    form.append('postName', jsonOptions.postName)
#    form.append('filename', jsonOptions.filename)
#    form.append('mimetype', jsonOptions.mimetype)
#    form.append('description', jsonOptions.description)
#    form.append('my_buffer', request(jsonOptions.my_buffer_url))
#
#  it 'created directly, can be read', (done) ->
#    request.get {uri: url+'/'+files[1]._id}, (err, res) ->
#      expect(res.statusCode).toBe(200)
#      expect(res.headers['content-type']).toBe(files[1].contentType)
#      done()
#
#  it 'does not overwrite existing files', (done) ->
#    options.json.description = 'Face'
#
#    func = (err, res, body) ->
#      expect(res.statusCode).toBe(409)
#      collection = mongoose.connection.db.collection('media.files')
#      collection.find({}).toArray (err, results) ->
#        # ittybitty.data, and just one Where are you.jpg
#        expect(results.length).toBe(2)
#        for f in results
#          expect(f.metadata.description).not.toBe('Face')
#        done()
#
#    request.post(options, func)
#
#  it 'does overwrite existing files if force is true', (done) ->
#    options.json.force = 'true' # TODO ask why it's a string and not a boolean ?
#
#    func = (err, res, body) ->
#      expect(res.statusCode).toBe(200)
#      collection = mongoose.connection.db.collection('media.files')
#      collection.find({}).toArray (err, results) ->
#        # ittybitty.data, and just one Where are you.jpg
#        expect(results.length).toBe(2)
#        hit = false
#        for f in results
#          hit = true if f.metadata.description is 'Face'
#        expect(hit).toBe(true)
#        done()
#
#    request.post(options, func)
#
#  it ' can\'t be requested with HTTP PATCH method', (done) ->
#    request {method: 'patch', uri: url}, (err, res) ->
#      expect(res.statusCode).toBe(405)
#      expect(res.headers.allow).toBe(allowHeader)
#      done()
#
#  it ' can\'t be requested with HTTP PUT method', (done) ->
#    request.put {uri: url}, (err, res) ->
#      expect(res.statusCode).toBe(405)
#      expect(res.headers.allow).toBe(allowHeader)
#      done()
#
#  it ' can\'t be requested with HTTP HEAD method', (done) ->
#    request.head {uri: url}, (err, res) ->
#      expect(res.statusCode).toBe(405)
#      expect(res.headers.allow).toBe(allowHeader)
#      done()
#
#  it ' can\'t be requested with HTTP DEL method', (done) ->
#    request.del {uri: url}, (err, res) ->
#      expect(res.statusCode).toBe(405)
#      expect(res.headers.allow).toBe(allowHeader)
#      done()
#
## TODO: test server errors, see what they do
