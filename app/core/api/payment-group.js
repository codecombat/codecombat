const fetchJson = require('./fetch-json');

const getPaymentGroup	= slug => fetchJson(`/db/payments/payment.groups/${slug}`);

const getPaymentGroupFromProduct = productId => fetchJson(`/db/payments/payment.groups/products/${productId}`)

module.exports = {
	getPaymentGroup,
	getPaymentGroupFromProduct
}
