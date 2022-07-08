function logInWithClever() {
  let cleverClientId, redirectTo, districtId
  if (['next.ozaria.com', 'localhost'].indexOf(window.location.hostname) !== -1) {
    cleverClientId = '05e505ed3fa677319057'
    redirectTo = 'https://next.ozaria.com/auth/login-clever'
    districtId = '5b2ad81a709e300001e2cd7a'  // Clever Library test district
  }
  else {  // prod
    cleverClientId = '88a2cfdb5893c16b4c0a'
    redirectTo = 'https://www.ozaria.com/auth/login-clever'
  }
  let url = `https://clever.com/oauth/authorize?response_type=code&redirect_uri=${encodeURIComponent(redirectTo)}&client_id=${cleverClientId}`
  if (districtId) {
    url += '&district_id=' + districtId
  }
  window.open(url, '_blank')
}

module.exports = {
  logInWithClever
}
