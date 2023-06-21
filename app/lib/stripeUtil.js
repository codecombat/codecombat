import { loadStripe } from '@stripe/stripe-js'
import { getPaymentGroupFromProduct } from '../core/api/payment-group'
import { createPaymentSession } from '../core/api/payment-session'

async function getStripeLib() {
  const isProd = document.location.href.includes('codecombat.com')
  const STRIPE_PUBLISHABLE_KEY = isProd ? 'pk_live_27jQZozjDGN1HSUTnSuM578g' : 'pk_test_BqKtc6bIKPn6FeSA4GhuRrwT'
  return loadStripe(STRIPE_PUBLISHABLE_KEY);
}

async function handleHomeSubscription (product, couponId, { purchasingForId = null } = {}) {
  const productId = product.get('_id')
  const paymentGroupResp = await getPaymentGroupFromProduct(productId, couponId)
  const paymentGroup = paymentGroupResp.data
  const homeSubDetails = {
    productId,
    purchasingForId
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
  if (product.get('name').includes('corrily')) {
    options.corrilyPriceKey = product.get('planID')
  }
  return handleCheckoutSessionHelper(options)
}

async function handleCheckoutSessionHelper (options) {
  const stripe = await getStripeLib()
  const sessionOptions = { ...options }
  try {
    window.tracker.trackEvent('Checkout initiated', sessionOptions)
    const session = await createPaymentSession(sessionOptions);
    const sessionId = session.data.sessionId;
    const result = await stripe.redirectToCheckout({ sessionId });
    if (result.error) {
      console.error('resErr', result.error);
    }
    return {
      result
    }
  } catch (err) {
    console.error('paymentSession creation failed', err);
    return {
      errMsg: err?.message || 'Payment session creation failed'
    }
  }
}

module.exports = {
  getStripeLib,
  handleHomeSubscription,
  handleCheckoutSessionHelper
};
