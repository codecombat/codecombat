fetchJson = require './fetch-json'

module.exports = {
  get: ({ classroomID }, options={}) ->
    fetchJson("/db/classroom/#{classroomID}", options)

  # TODO: Set this up to allow using classroomID instead
  getMembers: ({classroom}, options) ->
    classroomID = classroom._id
    removeDeleted = options.removeDeleted
    delete options.removeDeleted
    limit = 10
    skip = 0
    size = _.size(classroom.members)
    url = "/db/classroom/#{classroomID}/members"
    options.data ?= {}
    options.data.memberLimit = limit
    options.remove = false
    jqxhrs = []
    while skip < size
      options.data.memberSkip = skip
      jqxhrs.push(fetchJson(url, options))
      skip += limit
    return Promise.all(jqxhrs).then (data) ->
      users = _.flatten(data)
      if removeDeleted
        users = _.filter users, (user) ->
          not user.deleted
      return users

  getCourseLevels: ({classroomID, courseID}, options={}) ->
    fetchJson("/db/classroom/#{classroomID}/courses/#{courseID}/levels", options)

  addMembers: ({classroomID, members}, options={}) ->
    fetchJson("/db/classroom/#{classroomID}/add-members", _.assign({}, options, {
      method: 'POST'
      json: {members}
    }))

  fetchByOwner: (ownerId) ->
    fetchJson("/db/classroom?ownerID=#{ownerId}", {
      method: 'GET'
    })
}
