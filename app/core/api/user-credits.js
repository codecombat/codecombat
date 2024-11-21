const fetchJson = require('./fetch-json')

const getCredits = (action) => fetchJson(`/db/credits/${action}`)
const getStudentCredits = (action, student) => fetchJson(`/db/user-credits/${action}?student=${student}`)

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

const addCredits = ({ operation, credits, endDate, userId }) => fetchJson('/db/user-credits/extra-credits', {
  method: 'POST',
  json: {
    operation,
    credits,
    endDate,
    userId
  }
})

module.exports = {
  getCredits,
  getStudentCredits,
  redeemCredits,
  updateCreditUid,
  addCredits
}
