import fetchJson from './fetch-json';

const createPaymentSession = (options) => {
	return fetchJson('/db/payments/payment.sessions', {
		method: 'POST',
		json: options
	})
}

export default {
	createPaymentSession
};
