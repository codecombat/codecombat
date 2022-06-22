const fetchJson = require('./fetch-json')


module.exports = {
  getNew: () => fetchJson('/db/user/announcements/new'),
  getList: () => fetchJson('/db/user/announcements'),
  read: (options) => {
    return fetchJson('/db/user/announcement/read', {
      method: 'POST',
      json: options
    })
  }
}
