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

module.exports = {
  pay
}
