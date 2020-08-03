function getKeyForNamespace (namespace) {
  return `coco.tracker.pageUnloadRetries.${namespace}`;
}

function getNamespaceData (namespace) {
  const namespaceKey = getKeyForNamespace(namespace)
  const namespaceRetriesJson = window.sessionStorage.getItem(namespaceKey)

  return JSON.parse(namespaceRetriesJson || '[]')
}

function setNamespaceData(namespace, data) {
  const namespaceKey = getKeyForNamespace(namespace)
  window.sessionStorage.setItem(namespaceKey, JSON.stringify(data || []))
}

function deleteNamespaceData(namespace) {
  const namespaceKey = getKeyForNamespace(namespace)
  window.sessionStorage.removeItem(namespaceKey)
}

function runAfterPageLoad (namespace, identifier, args) {
  const namespaceRetries = getNamespaceData(namespace)

  namespaceRetries.push({
    identifier,
    args,
    at: new Date().getTime()
  })

  setNamespaceData(namespace, namespaceRetries)
}

export async function watchForPageUnload (timeout = 500) {
  let unloadCallback;
  const unloadPromise = new Promise((resolve, reject) => {
    unloadCallback = () => reject('unload')
    window.addEventListener('beforeunload', unloadCallback)
  })

  const timeoutPromise = new Promise((resolve) => setTimeout(resolve, timeout));

  try {
    await Promise.race([ unloadPromise, timeoutPromise ])
  } finally {
    window.removeEventListener('beforeunload', unloadCallback)
  }
}

/**
 * Monitors the page for unload events for a specified timeout after calling the supplied function.
 * If the page unloads before the timeout expires the function call is recorded in session storage and
 * can be loaded with `getPageUnloadRetriesForNamespace`.  The function is not automatically rerun,
 * it is the responsibility of the consumer to check for retries and to call the function again.
 *
 * This is useful for situations where an ongoing process (like a network call) may be interrupted by
 * a reload.  For example, a tracking network call that is fired after successful login, right before
 * the user is redirected to the dashboard.
 */
export async function retryOnPageUnload (namespace, identifier, args, func, timeout = 500) {
  const unloadPromise = watchForPageUnload(timeout)

  func()

  try {
    await unloadPromise
  } catch (e) {
    if (e !== 'unload') {
      throw e
    }

    runAfterPageLoad(namespace, identifier, args)
  }
}

export async function getPageUnloadRetriesForNamespace (namespace, timeout = 15000) {
  const namespaceRetries = getNamespaceData(namespace) || []

  deleteNamespaceData(namespace)
  return namespaceRetries
    .filter(retry => new Date().getTime() - retry.at < timeout)
}
