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
      // Sometimes flexsearch returns duplicates breaking unique key invariant in UI.
      return _.unique(this.flexsearch.search({ query: this.inputVal, suggest: true }) || [], '_id')
    },

    subNetworkSuggestions () {
      const subNetworks = this.filteredSuggestions.filter(({kind}) => kind === 'school-subnetwork')
      subNetworks.sort(({memberCount: a}, {memberCount: b}) => b - a)
      return subNetworks
    },

    schoolSuggestions () {
      const schoolSuggestions = this.filteredSuggestions.filter(({kind}) => kind === "school")
      schoolSuggestions.sort(({memberCount: a}, {memberCount: b}) => b - a)
      return schoolSuggestions
    }
  },

  methods: {
    handleFocusInput() {
      this.suggestions = this.childClans
    },

    clearInput () {
      this.suggestions = []
      this.inputVal = ""
    },

    handleBlurInput () {
      // Needs to take some time in case the user has clicked a suggestion in the dropdown.
      setTimeout(() => {
        this.suggestions = []
      }, 150)
    },

    navigateToTeamLeaguePage (clanSlug) {
      application.router.navigate(`/league/${clanSlug}`, { trigger: true })
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
    <div class="input-group">
      <span class="input-group-addon">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-search" viewBox="0 0 16 16">
          <path d="M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001c.03.04.062.078.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1.007 1.007 0 0 0-.115-.1zM12 6.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0z"/>
        </svg>
      </span>
      <input class="form-control" v-model="inputVal" name="child-clan-search" autocomplete="off" :placeholder="label || 'Search School teams'" @focus="handleFocusInput" @blur="handleBlurInput"/>
      <div v-if="this.inputVal !== ''" class="input-group-btn input-group-addon" style="cursor: pointer;" @click="clearInput">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-x" viewBox="0 0 16 16">
          <path d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708z"/>
        </svg>
      </div>
      <span v-else class="input-group-addon">
        {{`${childClans.length} teams`}}
      </span>
    </div>

    <div class="suggestion-wrapper">
      <div class="list-group">
        <div v-if="subNetworkSuggestions.length > 0"
          class="list-group-heading school-subnetwork">
          <p>Subnetwork Teams</p>
        </div>
        <div
          v-for="child in subNetworkSuggestions"
          :key="child._id"
          class="list-group-item school-subnetwork"
          @click="() => navigateToTeamLeaguePage(child.slug)"
        >
          <div class="name-style"><span>{{ child.displayName }}</span></div>
          <div class="member-counts">
            <span>{{child.memberCount}}</span>
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-people" viewBox="0 0 16 16">
              <path d="M15 14s1 0 1-1-1-4-5-4-5 3-5 4 1 1 1 1h8zm-7.978-1A.261.261 0 0 1 7 12.996c.001-.264.167-1.03.76-1.72C8.312 10.629 9.282 10 11 10c1.717 0 2.687.63 3.24 1.276.593.69.758 1.457.76 1.72l-.008.002a.274.274 0 0 1-.014.002H7.022zM11 7a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm3-2a3 3 0 1 1-6 0 3 3 0 0 1 6 0zM6.936 9.28a5.88 5.88 0 0 0-1.23-.247A7.35 7.35 0 0 0 5 9c-4 0-5 3-5 4 0 .667.333 1 1 1h4.216A2.238 2.238 0 0 1 5 13c0-1.01.377-2.042 1.09-2.904.243-.294.526-.569.846-.816zM4.92 10A5.493 5.493 0 0 0 4 13H1c0-.26.164-1.03.76-1.724.545-.636 1.492-1.256 3.16-1.275zM1.5 5.5a3 3 0 1 1 6 0 3 3 0 0 1-6 0zm3-2a2 2 0 1 0 0 4 2 2 0 0 0 0-4z"/>
            </svg>
          </div>
          
        </div>
        <div
          v-if="schoolSuggestions.length > 0"
          class="list-group-heading school">
          <p>School Teams</p>
        </div>
        <div
          v-for="child in schoolSuggestions"
          :key="child._id"
          class="list-group-item school"
          @click="() => navigateToTeamLeaguePage(child.slug)"
        >
          <div class="name-style"><span>{{ child.displayName }}</span></div>
          <div class="member-counts">
            <span>{{child.memberCount}}</span>
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-people" viewBox="0 0 16 16">
                <path d="M15 14s1 0 1-1-1-4-5-4-5 3-5 4 1 1 1 1h8zm-7.978-1A.261.261 0 0 1 7 12.996c.001-.264.167-1.03.76-1.72C8.312 10.629 9.282 10 11 10c1.717 0 2.687.63 3.24 1.276.593.69.758 1.457.76 1.72l-.008.002a.274.274 0 0 1-.014.002H7.022zM11 7a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm3-2a3 3 0 1 1-6 0 3 3 0 0 1 6 0zM6.936 9.28a5.88 5.88 0 0 0-1.23-.247A7.35 7.35 0 0 0 5 9c-4 0-5 3-5 4 0 .667.333 1 1 1h4.216A2.238 2.238 0 0 1 5 13c0-1.01.377-2.042 1.09-2.904.243-.294.526-.569.846-.816zM4.92 10A5.493 5.493 0 0 0 4 13H1c0-.26.164-1.03.76-1.724.545-.636 1.492-1.256 3.16-1.275zM1.5 5.5a3 3 0 1 1 6 0 3 3 0 0 1-6 0zm3-2a2 2 0 1 0 0 4 2 2 0 0 0 0-4z"/>
              </svg>
          </div>
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

.list-group-heading, .list-group-item {
  height: 34px;
  background-color: white;
}

.list-group-heading {
  display: flex;
  justify-content: flex-start;
  align-items: center;
  padding-left: 20px;
  background-color: #eee;
  cursor: default;

  p {
    margin: 0;
  }

  &.school-subnetwork {
    border-left: 12px solid #1D8F7E;
  }

  &.school {
    border-left: 12px solid #8F205D;
  }
}

.list-group-item {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;

  cursor: pointer;

  &.school-subnetwork {
    border-left: 12px solid #30efd3;
    padding-left: 52px;
  }

  &.school {
    border-left: 12px solid #ff39a6;
    padding-left: 52px;
  }

  &:hover {
    background-color: #dedede;
  }
}

.member-counts {
  display: flex;
  align-items: center;
  justify-content: space-around;

  svg {
    margin-left: 12px;
  }
}

.name-style {
  flex: 2;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  text-align: left;
}

.list-group {
  position: absolute;
  width: 100%;
  max-height: 70vh;
  overflow-y: scroll;
  z-index: 10;
}
</style>
