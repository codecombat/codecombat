/**
 * Returns a promise that will resolve after an approximate number of milliseconds.
 * The benefit of using this over setTimeout is that this works better when
 * users tab away or lose focus of the page. setTimeouts won't wait when the
 * user has tabbed away.
 *
 * @param {number} ms Time in milliseconds to wait.
 */
export function sleep (ms) {
  return new Promise((resolve, reject) => {
    let totalTime = 0
    const update = () => {
      if (totalTime > ms) return resolve()
      window.requestAnimationFrame(update)
      totalTime += 16.66 // 1 frame at 60 fps
    }
    window.requestAnimationFrame(update)
  })
}

/**
 * Returns a promise that will resolve after the given milliseconds.
 * @param {number} ms number of milliseconds before promise resolves
 */
export function sleepTimeout (ms) {
  return new Promise((resolve, reject) => {
    setTimeout(resolve, ms)
  })
}
