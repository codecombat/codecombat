User = require 'models/User'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Users extends CocoCollection
  model: User
  url: '/db/user'

  fetchForClassroom: (classroom, options) ->
    classroom = classroom.id or classroom
    options = _.extend({
      url: "/db/classroom/#{classroom}/members"
    }, options)
    @fetch(options)
    
