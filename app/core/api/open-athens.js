const fetchJson = require('./fetch-json')

const getUserInfo = (options) => {
  return fetchJson('/open-athens/user-info', {
    method: 'POST',
    json: options
  })
}

module.exports = {
  getUserInfo
}
