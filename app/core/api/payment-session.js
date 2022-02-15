const fetchJson = require('./fetch-json');

const createPaymentSession = (options) => {
	return fetchJson('/db/payments/payment.sessions', {
		method: 'POST',
		json: options
	})
}

module.exports = {
	createPaymentSession
};
