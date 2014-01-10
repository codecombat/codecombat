require './common'

describe '/file', ->
  url = getURL('/file')
  files = []
  
  it 'deletes all the files first', (done) ->
    dropGridFS ->
      done()


  it 'no admin users can\'t post files', (done) ->
    options = {
      uri:url
      json: {
        url: 'http://scotterickson.info/images/where-are-you.jpg'
        filename: 'where-are-you.jpg'
        mimetype: 'image/jpeg'
        description: 'None!'
      }
    }

    func = (err, res, body) ->
      expect(res.statusCode).toBe(403)
      expect(body.metadata).toBeUndefined()
      done()

    request.post(options, func)

# FIXME fatal error
  xit 'posts good', (done) ->
    options = {
      uri:url
      json: {
        url: 'http://scotterickson.info/images/where-are-you.jpg'
        filename: 'where-are-you.jpg'
        mimetype: 'image/jpeg'
        description: 'None!'
      }
    }

    func = (err, res, body) ->
      expect(res.statusCode).toBe(200)
      expect(body.metadata.description).toBe('None!')
      files.push(body)

      collection = mongoose.connection.db.collection('media.files')
      collection.findOne {}, (err, result) ->
        expect(result.metadata.name).toBe('Where are you')
        expect(result.metadata.createdFor+'').toBe([]+'')
        done()

    request.post(options, func)
    
  it 'gets good', (done) ->
    request.get {uri:url+'/'+files[0]._id}, (err, res) ->
      expect(res.statusCode).toBe(200)
      expect(res.headers['content-type']).toBe('image/jpeg')
      done()
    
      
  it 'returns 404 for missing files', (done) ->
    id = '000000000000000000000000'
    request.get {uri:url+'/'+id}, (err, res) ->
      expect(res.statusCode).toBe(404)
      done()
    
  it 'returns 404 for invalid ids', (done) ->
    request.get {uri:url+'/thiswillnotwork'}, (err, res) ->
      expect(res.statusCode).toBe(404)
      done()

# FIXME fatal error
  xit 'posts data directly', (done) ->
    options = {
      uri:url
    }


    func = (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)

      expect(body.metadata.description).toBe('rando-info')
      files.push(body)

      collection = mongoose.connection.db.collection('media.files')
      collection.find({_id:mongoose.Types.ObjectId(body._id)}).toArray (err, results) ->
        expect(results[0].metadata.name).toBe('Ittybitty')
        done()

    # the only way I could figure out how to get request to do what I wanted...
    r = request.post(options, func)
    form = r.form()
    form.append('postName', 'my_buffer')
    form.append('filename', 'ittybitty.data')
    form.append('mimetype', 'application/octet-stream')
    form.append('description', 'rando-info')
    form.append('my_buffer', request('http://scotterickson.info/images/where-are-you.jpg'))
    
  it 'does not overwrite existing files', (done) ->
    options = {
      uri:url
      json: {
        url: 'http://scotterickson.info/images/scott.jpg'
        filename: 'where-are-you.jpg'
        mimetype: 'image/jpeg'
        description: 'Face'
      }
    }

    func = (err, res, body) ->
      expect(res.statusCode).toBe(409)
      collection = mongoose.connection.db.collection('media.files')
      collection.find({}).toArray (err, results) ->
        # ittybitty.data, and just one Where are you.jpg
        expect(results.length).toBe(2)
        for f in results
          expect(f.metadata.description).not.toBe('Face')
        done()

    request.post(options, func)

  it 'does overwrite existing files if force is true', (done) ->
    options = {
      uri:url
      json: {
        url: 'http://scotterickson.info/images/scott.jpg'
        filename: 'where-are-you.jpg'
        mimetype: 'image/jpeg'
        description: 'Face'
        force: true
      }
    }

    func = (err, res, body) ->
      expect(res.statusCode).toBe(200)
      collection = mongoose.connection.db.collection('media.files')
      collection.find({}).toArray (err, results) ->
        # ittybitty.data, and just one Where are you.jpg
        expect(results.length).toBe(2)
        hit = false
        for f in results
          hit = true if f.metadata.description is 'Face'
        expect(hit).toBe(true)
        done()

    request.post(options, func)
    
  
  # TODO: test server errors, see what they do