import { getPaymentGroupFromProduct } from '../core/api/payment-group'
import { handleCheckoutSession } from '../views/payment/paymentPriceHelper'
const storage = require('core/storage')
const TEMPORARY_PREMIUM_KEY = 'temporary-premium-access'

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

function setTemporaryPremiumAccess() {
  storage.save(`${TEMPORARY_PREMIUM_KEY}-${me.get('_id')}`, true, 3)
}

function hasTemporaryPremiumAccess() {
  return storage.load(`${TEMPORARY_PREMIUM_KEY}-${me.get('_id')}`)
}

module.exports = {
  handleHomeSubscription,
  setTemporaryPremiumAccess,
  hasTemporaryPremiumAccess
}
