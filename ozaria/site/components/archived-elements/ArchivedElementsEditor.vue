<template>
  <div>
    <div id="type-select">
      <label>
      </label>

      <div class="form-group">
        <label>Show archived</label>
        <div class="radio-inline">
          <label>
            Only unarchived
            <input
                type="radio"
                name="displayArchived"
                value="none"
                :checked="displayArchived === 'none'"
                @change="setDisplayArchived('none')"
            />
          </label>
          <label>
            Both
            <input
                type="radio"
                name="displayArchived"
                value="both"
                :checked="displayArchived === 'both'"
                @change="setDisplayArchived('both')"
            />
          </label>
          <label>
            Only archived
            <input
                type="radio"
                name="displayArchived"
                value="only"
                :checked="displayArchived === 'only'"
                @change="setDisplayArchived('only')"
            />
          </label>
        </div>
      </div>

      <button @click="changeType('ThangType')" :class="elementType === 'ThangType' ? 'selected' : ''">ThangTypes</button>
      <button @click="changeType('Level')" :class="elementType === 'Level' ? 'selected' : ''">Levels</button>
      <button @click="changeType('LevelComponent')" :class="elementType === 'LevelComponent' ? 'selected' : ''">Components</button>
    </div>
    <div id="controls">
      <input id="search" placeholder="Search" v-model:value="searchingFor" v-on:keyup.enter="setSearchTerm(searchingFor)">
    </div>
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
      },
      // updateDisplayArchived (displayArchived) {
      //   this.setDisplayArchived(displayArchived)
      // }
    }
  }
</script>

<style lang="sass" scoped>
  #type-select
    padding: 2% 25% 2% 25%
    display: flex
    /*align-items: center*/
    justify-content: space-between
    button.selected
      color: white
      background-color: rgb(45, 88, 89)

</style>
