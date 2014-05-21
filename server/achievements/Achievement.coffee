mongoose = require('mongoose')
plugins = require('../plugins/plugins')
jsonschema = require('../../app/schemas/models/achievement')

# `pre` and `post` are not called for update operations executed directly on the database,
# including `Model.update`,`.findByIdAndUpdate`,`.findOneAndUpdate`, `.findOneAndRemove`,and `.findByIdAndRemove`.order
# to utilize `pre` or `post` middleware, you should `find()` the document, and call the `init`, `validate`, `save`,
# or `remove` functions on the document. See [explanation](http://github.com/LearnBoost/mongoose/issues/964).

AchievementSchema = new mongoose.Schema({
  query: Object
}, {strict: false})

AchievementSchema.plugin(plugins.SearchablePlugin, {searchable: ['name']})
AchievementSchema.plugin(plugins.NamedPlugin)

module.exports = Achievement = mongoose.model('Achievement', AchievementSchema)