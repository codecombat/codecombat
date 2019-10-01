<template lang="pug">
div.leveleditor
  .titlerow
    div
      h4.title {{ edited.name }}
        a.editLink(:href="levelEditorUrl") [e]
      select(v-model="edited.kind")
        option(
          v-for="kind in kinds"
          v-bind:value="kind"
          v-bind:key="kind"
        ) {{ kind }}
      span {{ levelTypeString }}
    button.btn.btn-primary.save(v-if="dirty" v-on:click="doSave") Save
  .editrow
    label Primary Concepts:
    array-input.grow(
      v-model="edited.primaryConcepts"
      v-bind:enumList="concepts"
    )
  .editrow
    label Description:
    input.grow(v-model="edited.description")

</template>

<script lang="coffee">
levelSchema = require('schemas/models/level')
concepts = require('schemas/concepts')

ArrayInput = require('./ArrayInput.vue').default
module.exports = Vue.extend({
  components: { ArrayInput }
  props:
    level: { type: Object, default: {} }
  data: ->
    kinds: levelSchema.properties.kind.enum
    edited: {}
    saved: false
  computed:
    dirty: ->
      for key in _.keys(@edited)
        return true unless _.isEqual(@edited[key], @level[key])
      false
    concepts: -> _.filter(concepts, (c) -> !c.deprecated).map((c) => c.concept)
    levelEditorUrl: -> "/editor/level/#{@level.slug}"
    levelTypeString: ->
      return '(concept)' if @edited.assessment == true
      return '(combo)' if @edited.assessment == 'cumulative'
      return '(practice)' if @edited.practice == true
      return '(arena)' if @edited.type?.search('ladder') > -1
      ''
    practiceString: -> if @edited.practice then '(practice level)' else ''
  created: ->
    @edited = _.cloneDeep(@level)
  beforeUpdate: ->
    if @saved and (not @level.commitMessage)
      @saved = false
      @edited = _.cloneDeep(@level)
  methods:
    doSave: ->
      if @dirty
        @$emit('save', _.cloneDeep(@edited))
        @saved = true

})

</script>

<style lang="sass">
  .leveleditor
    width: 100%
    min-height: 100px
    box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24)
    margin-bottom: 10px
    padding: 5px
    display: flex
    flex-direction: column

    div
      width: 100%
      display: flex
      align-items: center
      & > *
        margin-right: 4px
      & > *:last-child
        margin-right: 0

    .titlerow
      justify-content: space-between
      margin-bottom: 10px

    .editrow
      margin-bottom: 6px

    label
      margin: 0
      min-width: 170px

    .title
      font-weight: bold
      min-width: 300px
      margin-right: 5px
      .editLink
        font-size: 70%

    button.save
      height: 35px

    .grow
      flex-grow: 1

</style>
