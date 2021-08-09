const getMsTime = () => ((window.performance || {}).now() || Date.now())

/**
 * Tries to send a log to our DataDog log service.
 * @param {string} action - logging action
 * @param {object} options - object to include with the logging action
 * @param {string} status - status of the log, values can be 'debug', 'info', 'warn', 'error'
 */
export const log = (action, options = {}, status = 'info') => {
  if (typeof ((window.DD_LOGS || {}).logger || {}).log !== 'function') {
    if(me.useDataDog()){
      console.debug('DD_LOGS not available. Log: ', action)
    }
    return
  }

  try {
    if (window.application && !window.application.isProduction() || window.location.hostname === 'localhost') {
      window.DD_LOGS.logger.setHandler('console')
    }
  
    window.DD_LOGS.logger.log(
      action,
      options,
      status
    )
  } catch (e) {
    console.warning('Error while sending datadog log', e)
  }
}

/**
 * Adds a global key value pair to include in all logs.
 * @param {string} key
 * @param {string} value
 */
export const addLoggerGlobalContext = (key, value) => {
  if (!key || !value) { return }

  window.DD_LOGS && DD_LOGS.addLoggerGlobalContext(key, value)
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
