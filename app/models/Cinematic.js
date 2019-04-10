const CocoModel = require('./CocoModel')
const schema = require('schemas/models/cinematic.schema')

class Cinematic extends CocoModel { }

Cinematic.className = 'Cinematic'
Cinematic.schema = schema
Cinematic.urlRoot = '/db/cinematic'

module.exports = Cinematic
