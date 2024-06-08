const moment = require('moment')
function isMarkedDone (user) {
  const actions = [...(user.actions || [])]
  actions.reverse()
  for (const action of actions) {
    if (action.name === 'undo-done') {
      return false
    } else if (action.name === 'done') {
      return moment(action.date).isAfter(moment().subtract(1, 'month'))
    }
  }
  return false
}

module.exports = {
  isMarkedDone
}
