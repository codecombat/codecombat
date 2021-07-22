import {getStripeLib} from "../../lib/stripeUtil";
import {createPaymentSession} from "../../core/api/payment-session";

function getDisplayUnitPrice(unitAmount) {
  return unitAmount / 100;
}

function getDisplayCurrency(currency) {
  return currency === 'usd' ? '$' : currency;
}

async function handleStudentLicenseCheckoutSession(options) {
  const stripe = await getStripeLib()
  const sessionOptions = { ...options }
  try {
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
      errMsg: err.message
    }
  }
}

module.exports = {
  getDisplayUnitPrice,
  getDisplayCurrency,
  handleStudentLicenseCheckoutSession,
};
