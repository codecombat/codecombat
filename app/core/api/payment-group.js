const fetchJson = require('./fetch-json');

const getPaymentGroup	= slug => fetchJson(`/db/payments/payment.groups/${slug}`);

module.exports = {
	getPaymentGroup
}
