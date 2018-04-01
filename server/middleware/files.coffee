utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
Grid = require 'gridfs-stream'
Promise = require 'bluebird'
database = require '../commons/database'
textToSpeech = require '../lib/text-to-speech'

module.exports =
  files: (Model, options={}) -> wrap (req, res) ->
    doc = yield database.getDocFromHandle(req, Model)
    if not doc
      throw new errors.NotFound('Document not found.')
    module = options.module or req.path[4..].split('/')[0]
    query = { 'metadata.path': "db/#{module}/#{doc.id}" }

    c = Grid.gfs.collection('media')
    c.findAsync = Promise.promisify(c.find)
    cursor = yield c.findAsync(query)
    cursor.toArrayAsync = Promise.promisify(cursor.toArray)
    files = yield cursor.toArrayAsync()
    res.status(200).send(files)

  # TODO: put this somewhere else, maybe?
  textToSpeech: wrap (req, res) ->
    language = req.params.language ? req.user.get 'preferredLanguage'
    text = req.params.text
    audioEncoding = text.match(/\.(mp3|ogg)/i)?[1]?.toUpperCase() ? 'MP3'
    text = text.replace /\.(mp3|ogg)$/i, ''
    #console.log 'Going to synthesize text to speech:', text, 'with language', language, 'and encoding', audioEncoding
    # TODO: save and cache some of these commonly used files ourselves, maybe?
    audio = yield textToSpeech.synthesize text, language: language, audioEncoding: audioEncoding
    unless audio
      return res.status(404).send()
    res.set 'Content-Type', {MP3: 'audio/mpeg', OGG: 'audio/ogg'}[audioEncoding]
    res.status(200).send(audio)
