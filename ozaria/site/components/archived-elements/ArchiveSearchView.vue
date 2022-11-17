<template>
  <div class="search-view">
    <table class="table">
      <tr>
        <th :colspan="rows.length">
          <span>Results: {{documents.length}}</span>
        </th>
      </tr>

      <tr>
        <th v-for="el in rows">{{el}}</th>
      </tr>

      <h4 v-if="collection && documents.length === 0">
        Loading...
      </h4>
      <tr v-for="doc in documents" :class="classForDoc(doc)">
        <td v-for="el in rows" :title="doc.attributes.name">
          <input v-if="el === 'Archived'" type="checkbox" :checked="doc.attributes.archived" @change="checkChanged(doc)">
          <a v-else-if="el === 'Name'" :href="pathForDoc(doc)">{{doc.attributes.name}}</a>
          <span v-else-if="el === 'Version'">{{`${doc.attributes.version.major}.${doc.attributes.version.minor}`}}</span>
          <span v-else-if="el === 'Description'">{{doc.attributes.description}}</span>
        </td>
      </tr>
    </table>
  </div>
</template>

<script>
  import { mapGetters } from 'vuex'
  import { archivedElements } from 'core/api'
  import SearchCollection from './SearchCollection'

  export default {
    name: 'ArchiveSearchView',

    props: {
      modelName: {
        type: String, // Like 'Level'
        required: true
      },
      model: {
        type: Function, // Like Level
        required: true
      },
      modelURL: {
        type: String, // Like '/db/level'
        required: true,
      },
      projection: {
        type: Array, // Like ['slug', 'name', 'description', 'version', 'creator', 'archived']
        required: true
      },
      rows: {
        type: Array, // Like ['Archived', 'Name', 'Description', 'Version']
        required: true,
        default: []
      },
      displayArchived: {
        type: String, // none, only, both
        required: true
      }
    },

    mounted () {
      this.$nextTick(() => {
        this.search('')
      })
    },

    data: () => ({
      collection: null,
      documents: []
    }),

    watch: {
      searchTerm () {
        this.$nextTick(() => {
          this.search(this.searchTerm)
        })
      },
      // Any prop change and we start over
      model () {
        this.documents = []
        this.$nextTick(() => {
          this.search('')
        })
      },
      displayArchived () {
        this.documents = []
        this.$nextTick(() => {
          this.search(this.searchTerm)
        })
      }
    },

    computed: mapGetters('archivedElements', ['searchTerm']),

    methods: {
      search (searchTerm) {
        if (this.collection) {
          this.collection.off()
          this.collection = null
        }

        this.collection = new SearchCollection(this.modelURL, this.model, searchTerm, this.projection)
        this.collection.term = searchTerm // needed?
        if (this.displayArchived === 'none') {
          this.collection.url += '&archived=false'
        } else if (this.displayArchived === 'only') {
          this.collection.url += '&archived=true'
        }
        this.collection.fetch({
          success: () => {
            this.collection.sort()
            this.documents = this.collection.models
          }
        })
      },
      classForDoc (doc) {
        return doc.get('creator') == me.id ? 'mine' : ''
      },

      pathForDoc (doc) {
        const editorPathName = this.modelName === 'ThangType' ? 'thang' : this.modelName.toLowerCase()
        return `/editor/${editorPathName}/${doc.attributes.slug || doc.attributes._id}`
      },

      checkChanged (doc) {
        const { _id, archived } = doc.attributes
        if (archived) {
          archivedElements.unarchiveElement(_id, this.modelName)
        } else {
          archivedElements.archiveElement(_id, this.modelName)
        }

        doc.attributes.archived = !archived
      }
    }
  }
</script>

<style lang="sass" scoped>
  .search-view
    #controls
      display: flex
      padding: 0 25% 0 25%
      justify-content: space-between

    input#search
      width: 190px
      height: 30px
      padding-left: 5px

    table.table
      padding: 0 5px 0 5px
      .body-row
        max-width: 600px
        white-space: nowrap
        overflow: hidden
        text-overflow: ellipsis
      .name-row
        @extend .body-row
        max-width: 300px
      .description-row
        @extend .body-row
        max-width: 520px
      .small-name-row
        @extend .body-row
        max-width: 200px

      .watch-row
        @extend .body-row
        max-width: 80px
        text-align: center
        &.watching
          opacity: 1.0
        &.not-watching
          opacity: 0.5

      tr.mine
        background-color: #f8ecaa
</style>
