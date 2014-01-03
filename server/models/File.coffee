mongoose = require('mongoose')
plugins = require('./plugins')

FileSchema = new mongoose.Schema()

FileSchema.plugin(plugins.SearchablePlugin, {searchable: ['metadata.description', 'metadata.name']})

module.exports = mongoose.model('media.files', FileSchema)
