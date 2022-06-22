const fetchJson = require('./fetch-json')


module.exports = {
  getNew: () => fetchJson('/db/user/announcements/new'),
  getList: (options) => {
    let url = '/db/user/announcements';
    if(options && options.startDate && options.endDate) {
      url += `?startDate=${options.startDate}&endDate=${options.endDate}`
    }
    return fetchJson(url)
  },
  read: (options) => {
    return fetchJson('/db/user/announcement/read', {
      method: 'POST',
      json: options
    })
  }
}
