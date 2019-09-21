const getMsTime = () => ((window.performance || {}).now() || Date.now())

/**
 * Tries to send a log to our DataDog log service.
 * @param {string} action - logging action
 * @param {object} options - object to include with the logging action
 */
export const log = (action, options) => {
  if (typeof ((window.DD_LOGS || {}).logger || {}).log !== 'function') {
    console.debug('DD_LOGS not available. Log: ', action)
    return
  }

  if (window.application && !window.application.isProduction()) {
    window.DD_LOGS.logger.setHandler('console')
  }

  window.DD_LOGS.logger.log(
    action,
    options
  )
}

/**
 * Returns a function that can be called again to find the time since the
 * function was instantiated.
 *
 * Example:
 * ```js
 * let timer = startTimer()
 * // undefined
 * timer()
 * // 15779.185
 * ```
 *
 * Returns -1 if browser didn't support performance API or Date API.
 */
export const startTimer = () => {
  let startingTime

  try {
    startingTime = getMsTime()
  } catch (e) {
    return () => -1
  }

  return () => getMsTime() - startingTime
}
