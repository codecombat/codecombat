export function getRequestAQuoteGroup (user) {
  const bucket = user.get('testGroupNumber') % 10

  if (bucket < 5) {
    return 'request-a-quote-control'
  } else {
    return 'request-a-quote-header'
  }
}

export function getOzariaEncouragementModalGroup (user) {
  const bucket = user.get('testGroupNumber') % 10

  if (bucket < 5) {
    return 'ozaria-encouragement-modal-show'
  } else {
    return 'ozaria-encouragement-modal-no-show'
  }
}
