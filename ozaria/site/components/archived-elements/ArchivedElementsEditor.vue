<template>
  <div>
    <div id="type-select">
      <button
        :class="elementType === 'ThangType' ? 'selected' : ''"
        @click="changeType('ThangType')"
      >
        ThangTypes
      </button>
      <button
        :class="elementType === 'Level' ? 'selected' : ''"
        @click="changeType('Level')"
      >
        Levels
      </button>
      <button
        :class="elementType === 'LevelComponent' ? 'selected' : ''"
        @click="changeType('LevelComponent')"
      >
        Components
      </button>
    </div>

    <div id="controls">
      <input
        id="search"
        v-model:value="searchingFor"
        placeholder="Search"
        @keyup.enter="setSearchTerm(searchingFor)"
      >
    </div>

    <form class="radio-group">
      <div class="form-group">
        <label>Only unarchived </label>
        <input
          type="radio"
          name="displayArchived"
          value="none"
          :checked="displayArchived === 'none'"
          @change="setDisplayArchived('none')"
        >
      </div>
      <div class="form-group">
        <label>Both</label>
        <input
          type="radio"
          name="displayArchived"
          value="both"
          :checked="displayArchived === 'both'"
          @change="setDisplayArchived('both')"
        >
      </div>
      <div class="form-group">
        <label>Only archived</label>
        <input
          type="radio"
          name="displayArchived"
          value="only"
          :checked="displayArchived === 'only'"
          @change="setDisplayArchived('only')"
        >
      </div>
    </form>

    <ArchiveSearchView
      :model="viewMap[elementType].model"
      :model-name="viewMap[elementType].modelName"
      :model-u-r-l="viewMap[elementType].modelURL"
      :projection="viewMap[elementType].projection"
      :rows="viewMap[elementType].rows"
      :display-archived="displayArchived"
    />
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex'
import ThangType from 'models/ThangType'
import Level from 'models/Level'
import LevelComponent from 'models/LevelComponent'
import ArchiveSearchView from './ArchiveSearchView'

export default {
  name: 'ArchivedElementsEditor',
  components: {
    ArchiveSearchView
  },
  data: () => ({
    searchingFor: '', // Disconnect from state to trigger on enter
    viewMap: {
      ThangType: {
        model: ThangType,
        modelName: 'ThangType',
        modelURL: '/db/thang.type',
        projection: ['slug', 'name', 'description', 'version', 'creator', 'archived'],
        rows: ['Archived', 'Name', 'Description', 'Version']
      },
      Level: {
        model: Level,
        modelName: 'Level',
        modelURL: '/db/level',
        projection: ['slug', 'name', 'description', 'version', 'creator', 'archived'],
        rows: ['Archived', 'Name', 'Description', 'Version']
      },
      LevelComponent: {
        model: LevelComponent,
        modelName: 'LevelComponent',
        modelURL: '/db/level.component',
        projection: ['slug', 'name', 'description', 'version', 'creator', 'archived'],
        rows: ['Archived', 'Name', 'Description', 'Version']
      }
    }
  }),
  computed: mapState('archivedElements', {
    elementType: (s) => s.elementType,
    displayArchived: (s) => s.displayArchived
  }),
  methods: {
    ...mapActions('archivedElements', ['setSearchTerm', 'setElementType', 'setDisplayArchived']),
    changeType (elementType) {
      this.searchingFor = ''
      this.setElementType(elementType)
    }
  }
}
</script>

<style lang="sass" scoped>
  .radio-group
    float: left
    padding: 5px

  .form-group
    display: flex
    align-items: center
    flex-direction: row
    justify-content: space-between

    label
      margin-bottom: 0
      font-weight: 400
      font-size: 18px
      letter-spacing: 0.2px
      line-height: 24px
      padding-right: 5px

  #type-select
    padding: 2% 25% 2% 25%
    display: flex
    /*align-items: center*/
    justify-content: space-between
    button.selected
      color: white
      background-color: rgb(45, 88, 89)

</style>
