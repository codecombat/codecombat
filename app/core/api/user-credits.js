const fetchJson = require('./fetch-json')

const getCredits = (action) => fetchJson(`/db/credits/${action}`)

const redeemCredits = ({ operation, id }) => fetchJson('/db/user-credits/redeem', {
  method: 'POST',
  json: {
    operation,
    id
  }
})

module.exports = {
  getCredits,
  redeemCredits
}
