import { getPaymentGroupFromProduct } from '../core/api/payment-group'
import { handleCheckoutSession } from '../views/payment/paymentPriceHelper'

async function handleHomeSubscription(product, couponId) {
  const productId = product.get('_id')
  const paymentGroupResp = await getPaymentGroupFromProduct(productId, couponId)
  const paymentGroup = paymentGroupResp.data
  const homeSubDetails = {
    productId
  }
  const options = {
    stripePriceId: paymentGroup.priceInfo.id,
    paymentGroupId: paymentGroup._id,
    numberOfLicenses: 1,
    email: me.get('email'),
    userId: me.get('_id'),
    totalAmount: paymentGroup.priceInfo.unit_amount,
    homeSubDetails
  }
  return handleCheckoutSession(options)
}

module.exports = {
  handleHomeSubscription
}
