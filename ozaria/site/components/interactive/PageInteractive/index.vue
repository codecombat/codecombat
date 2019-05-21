<script>

import interactiveApi from '../../../api/interactive'
import draggableOrderingComponent from './draggableOrdering'
import insertCodeComponent from './insertCode'
import draggableStatementCompletionComponent from './draggableStatementCompletion'

module.exports = Vue.extend({
  props: {
    interactiveIdOrSlug: {
      type: String,
      required: true,
      default: ''
    },
    introLevelId: {
      type: String,
      required: true,
      default: ''
    },
    courseInstanceId: {
      type: String
    }
  },
  data: () => ({
    interactive: {},
    interactiveSession: {},
    interactiveType: ''
  }),
  components: {
    'draggable-ordering': draggableOrderingComponent,
    'insert-code': insertCodeComponent,
    'draggable-statement-completion': draggableStatementCompletionComponent
  },
  async created() {
    if (!me.hasInteractiveAccess()) {
      alert('You must be logged in as an admin to use this page.')
      return application.router.navigate('/', { trigger: true })
    }
    try {
      this.interactive = await interactiveApi.getInteractive(this.interactiveIdOrSlug)
      this.interactiveType = this.interactive.interactiveType
      if (!this.interactiveType) {
        console.error("Interactive type is not set for the interactive", this.interactiveIdOrSlug)
        noty({ text: 'Interactive type is not set for the interactive', type: 'error', timeout: '2000' })
        return
      }
      this.interactiveSession = await interactiveApi.getSession(this.interactiveIdOrSlug, {introLevelId: this.introLevelId, courseInstanceId: this.courseInstanceId} )
    } catch (err) {
      console.error("Error:", err)
      noty({ text: 'Error occured in getting interactives data.', type: 'error', timeout: '2000' })
    }
  },
  methods: {
    onCompleted() {
      this.$emit('completed')
    }
  }
})
</script>

<template>
  <draggable-ordering
    v-if="interactiveType == 'draggable-ordering'"
    :interactive="interactive"
    :introLevelId="introLevelId"
    :interactiveSession="interactiveSession"
    :courseInstanceId="courseInstanceId"
    v-on:completed="onCompleted">
  </draggable-ordering>
  <insert-code
    v-else-if="interactiveType == 'insert-code'"
    :interactive="interactive"
    :introLevelId="introLevelId"
    :interactiveSession="interactiveSession"
    :courseInstanceId="courseInstanceId"
    v-on:completed="onCompleted">
  </insert-code>
  <draggable-statement-completion
    v-else-if="interactiveType == 'draggable-statement-completion'"
    :interactive="interactive"
    :introLevelId="introLevelId"
    :interactiveSession="interactiveSession"
    :courseInstanceId="courseInstanceId"
    v-on:completed="onCompleted">
  </draggable-statement-completion>
</template>

<style scoped>

</style>


