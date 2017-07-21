module.exports = CompletenessInfo = Vue.extend
  id: 'completeness-info'
  template: require('templates/courses/components/completeness-info')()
  props: ['earliestIncompleteLevel', 'latestCompleteLevel']
  components:
    'long-level-name': require('views/courses/components/LongLevelName')
    'inline-user-list': require('views/courses/components/InlineUserList')
