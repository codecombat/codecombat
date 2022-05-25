import {getStripeLib} from "../../lib/stripeUtil";
import {createPaymentSession} from "../../core/api/payment-session";

function getDisplayUnitPrice(unitAmount) {
  return unitAmount / 100;
}

function getDisplayCurrency(currency) {
  return currency === 'usd' ? '$' : currency;
}

async function handleCheckoutSession(options) {
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
  getDisplayUnitPrice,
  getDisplayCurrency,
  handleCheckoutSession,
};
