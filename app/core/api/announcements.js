const fetchJson = require('./fetch-json')


module.exports = {
  getNew: () => fetchJson('/db/user/announcements/new'),
  getList: () => fetchJson('/db/user/announcements')
}
