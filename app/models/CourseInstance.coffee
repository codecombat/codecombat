CocoModel = require './CocoModel'
schema = require 'schemas/models/course_instance.schema'

module.exports = class CourseInstance extends CocoModel
  @className: 'CourseInstance'
  @schema: schema
  urlRoot: '/db/course_instance'

  upsertForHOC: (opts) ->
    options = {
      url: _.result(@, 'url') + '/~/create-for-hoc'
      type: 'POST'
    }
    _.extend options, opts
    @fetch(options)

  firstLevelURL: ->
    "/play/level/course-dungeons-of-kithgard?course=#{@get('courseID')}&course-instance=#{@id}"