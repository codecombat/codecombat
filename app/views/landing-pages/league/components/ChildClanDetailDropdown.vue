<script>
const FlexSearch = require('flexsearch')

export default {
  props: {
    childClans: {
      type: Array,
      required: false,
      default: () => ([])
    },

    label: {
      type: String,
      required: false,
      default: 'Search teams'
    }
  },

  data: () => ({
    inputVal: "",
    flexsearch: null,
    suggestions: []
  }),

  watch: {
    childClans (newVal) {
      this.createNewFlexSearch()
      this.flexsearch.add(newVal)
    }
  },

  created () {
    this.createNewFlexSearch()
    this.flexsearch.add(this.childClans)
  },

  computed: {
    filteredSuggestions () {
      if (this.flexsearch === null) {
        return this.suggestions
      }

      if (this.inputVal === '') {
        return this.suggestions
      }

      return this.flexsearch.search({ query: this.inputVal, suggest: true })
    }
  },

  methods: {
    handleFocusInput() {
      this.suggestions = this.childClans
    },

    handleBlurInput () {
      // Needs to take some time in case the user has clicked a suggestion in the dropdown.
      setTimeout(() => {
        this.suggestions = []
      }, 150)
    },

    getClanKindDisplay (clan) {
      if (clan.kind === 'school') {
        return 'School:'
      } else if (clan.kind === 'school-subnetwork') {
        return 'SubNetwork:'
      }
      return ''
    },

    createNewFlexSearch () {
      if (!this.flexsearch) {
        this.flexsearch = new FlexSearch()
      }

      this.flexsearch.destroy().init({
        tokenize: 'full',
        depth: 3,
        doc: {
          id: '_id',
          field: 'displayName'
        }
      })
    }
  }
}
</script>

<template>
  <div class="form-group child-clan-search">
    <input class="form-control" v-model="inputVal" name="child-clan-search" autocomplete="off" :placeholder="label || 'Search School teams'" @focus="handleFocusInput" @blur="handleBlurInput"/>
    <div class="suggestion-wrapper">
      <div class="list-group">
        <div
          v-for="child in filteredSuggestions"
          :key="child._id"
          class="list-group-item"
        >
          <div><a :href="`/league/${child._id}`">{{`${getClanKindDisplay(child)} ${child.displayName}`}}</a></div>
          <div>{{child.memberCount}}</div>
        </div>
      </div>
    </div>
  </div>
</template>


<style lang="scss" scoped>
.child-clan-search {
  margin: 0;
}

.form-control {
  color: black;
}

.control-label {
  color: white;
}

.suggestion-wrapper {
  color: black;
  position: relative;
}

.list-group-item {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;

  &:hover {
    background-color: #dedede;
  }
}

.list-group {
  position: absolute;
  width: 100%;
  max-height: 40vh;
  overflow-y: scroll;
  z-index: 10;
}
</style>
