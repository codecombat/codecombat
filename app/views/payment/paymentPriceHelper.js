function getDisplayUnitPrice(unitAmount) {
  return unitAmount / 100;
}

function getDisplayCurrency(currency) {
  return currency === 'usd' ? '$' : currency;
}

module.exports = {
  getDisplayUnitPrice,
  getDisplayCurrency,
};
