SimpleVueComponent = Vue.extend
  name: 'SimpleVueComponent'
  props: ['label']
  data: ->
    checked: false
  template: require('templates/core/simple-vue-component')()

module.exports = SimpleVueComponent
