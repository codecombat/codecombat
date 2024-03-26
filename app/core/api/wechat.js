const fetchJson = require('./fetch-json')

const pay = async (plan) => {
  const response = await fetchJson('/db/payments/wechat-pay/payment', {
    method: 'POST',
    json: {
      plan
    }
  })

  return response
}

const querySession = async (sessionId) => {
  const response = await fetchJson(`/db/payments/wechat-pay/session/${sessionId}`)

  return response
}

module.exports = {
  pay,
  querySession
}
