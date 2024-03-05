const fetchJson = require('./fetch-json')

const getCredits = (action) => fetchJson(`/db/credits/${action}`)

const redeemCredits = ({ operation, id }) => fetchJson('/db/user-credits/redeem', {
  method: 'POST',
  json: {
    operation,
    id
  }
})

const updateCreditUid = ({ operation, uid, newId }) => fetchJson('/db/user-credits/update-uid', {
  method: 'PUT',
  json: {
    operation,
    uid,
    newId
  }
})

module.exports = {
  getCredits,
  redeemCredits,
  updateCreditUid
}
