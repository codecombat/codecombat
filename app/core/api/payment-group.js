const fetchJson = require('./fetch-json');

const getPaymentGroup	= slug => fetchJson(`/db/payments/payment.groups/${slug}`);

const getPaymentGroupFromProduct = (productId, couponId) => {
	if (couponId) {
		return fetchJson(`/db/payments/payment.groups/products/${productId}/?couponId=${couponId}`)
	} else {
		return fetchJson(`/db/payments/payment.groups/products/${productId}`)
	}
}

module.exports = {
	getPaymentGroup,
	getPaymentGroupFromProduct
}
