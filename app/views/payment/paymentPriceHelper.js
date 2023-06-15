import { handleCheckoutSessionHelper } from "../../lib/stripeUtil";

function getDisplayUnitPrice(unitAmount) {
  return unitAmount / 100;
}

function getDisplayCurrency(currency) {
  return currency === 'usd' ? '$' : currency;
}

async function handleCheckoutSession(options) {
  return handleCheckoutSessionHelper(options)
}

module.exports = {
  getDisplayUnitPrice,
  getDisplayCurrency,
  handleCheckoutSession,
};
