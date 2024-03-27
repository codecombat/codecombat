const moment = require('moment')
function isMarkedDone (user) {
  const actions = [...(user.actions || [])]
  actions.reverse()
  console.log('actions', actions)
  for (const action of actions) {
    if (action.name === 'undo-done') {
      return false
    } else if (action.name === 'done') {
      console.log('done', action, moment(action.date).isAfter(moment().subtract(1, 'month')))
      return moment(action.date).isAfter(moment().subtract(1, 'month'))
    }
  }
  return false
}

module.exports = {
  isMarkedDone
}
