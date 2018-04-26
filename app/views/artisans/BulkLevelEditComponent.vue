<template lang="jade">
div.container
  h1 Bulk Level Editor
  .campaign(v-if="campaignHandle")
    h2 Campaign: {{ campaignHandle }} ({{ numLevels }} levels)
    p {{ campaign.description }}
    span Commit Message:
      input.commit(v-model="commitMessage" ref="commitInput")
    .level(v-for="level in levels")
      bulk-level-editor-component(
        v-bind:level="level"
        v-on:save="saveLevel"
      )
  .campaignPick(v-else)
    label Campaign:
    input(v-model="campaignToLoad")
    button(@click="fetchCampaign(campaignToLoad)") Load
</template>

<script lang="coffee">
co = require('co')
api = require 'core/api'
BulkLevelEditorComponent = require('./BulkLevelEditorComponent').default

module.exports = Vue.extend({
  props: {
    campaignHandle: String
  }
  components: {
    BulkLevelEditorComponent
  }
  data: ->
    campaignToLoad: ''
    campaign: {}
    levels: {}
    commitMessage: ''
  computed:
    numLevels: -> if @campaign?.levels then _.keys(@campaign.levels).length else 0
  created: co.wrap ->
    @fetchCampaign(@campaignHandle) if @campaignHandle
  methods:
    fetchCampaign: co.wrap (campaignHandle) ->
      @campaignHandle = campaignHandle
      @campaign = yield api.campaigns.get({ campaignHandle })
      @campaignToLoad = '' if @campaign
      @fetchLevels()
    fetchLevels: co.wrap ->
      return unless @campaign
      for original, level of @campaign.levels
        levelData = yield api.levels.getByOriginal(original)
        Vue.set(@levels, original, levelData)
    saveLevel: co.wrap (level) ->
      console.log "SAVE LEVEL", level
      unless @commitMessage
        @$refs.commitInput.focus()
        return
      level.commitMessage = @commitMessage
      yield api.levels.save(level)
      levelData = yield api.levels.getByOriginal(level.original)
      Vue.set(@levels, level.original, levelData)
})

</script>

<style lang="sass">

#bulk-level-edit-view
  .commit
    width: 75%
    margin-bottom: 10px
</style>
