/**
 * @param {string} action - The action name we are tracking
 * @param {string} props - Extra properties to track
 */
export const cutsceneEvent = (action, props = {}) => {
  if (!(window.tracker && window.tracker.trackEvent)) { return }
  props.category = 'Cutscene'
  window.tracker.trackEvent(
    action,
    props,
    ['Google Analytics']
  )
}
