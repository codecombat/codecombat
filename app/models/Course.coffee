CocoModel = require './CocoModel'
schema = require 'schemas/models/course.schema'
utils = require 'core/utils'

module.exports = class Course extends CocoModel
  @className: 'Course'
  @schema: schema
  urlRoot: '/db/course'

  fetchForCourseInstance: (courseInstanceID, opts) ->
    options = {
      url: "/db/course_instance/#{courseInstanceID}/course"
    }
    _.extend options, opts
    @fetch options

  acronym: ->
    # TODO: i18n (optional parameter so we can still get English acronym, too)
    acronym = switch
      when /game-dev/.test(@get('slug')) then 'GD'
      when /web-dev/.test(@get('slug')) then 'WD'
      else 'CS'
    number = @get('slug')?.match(/(\d+)$/)?[1] or '1'
    acronym + number
