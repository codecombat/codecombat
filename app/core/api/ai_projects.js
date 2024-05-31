const fetchJson = require('./fetch-json')

module.exports = {
  fetchForClassroomMembers (classroomID, options) {
    return fetchJson(`/db/classroom/${classroomID}/member-ai-projects`, _.merge({}, options, {
      method: 'GET'
    }))
  },
}
