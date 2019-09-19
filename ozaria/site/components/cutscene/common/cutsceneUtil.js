/**
 * @param {string} action - The action name we are tracking
 */
export const cutsceneEvent = action => {
  if (!(window.tracker && window.tracker.trackEvent)) { return }
  window.tracker.trackEvent(
    action,
    {
      category: 'Cutscene'
    },
    ['Google Analytics']
  )
}
