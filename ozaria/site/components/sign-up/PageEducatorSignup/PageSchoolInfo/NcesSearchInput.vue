
<script>
  import algolia from 'core/services/algolia'

  export default {
    props: {
      displayKey: {
        type: String,
        default: ''
      },
      initialValue: {
        type: String,
        default: ''
      },
      name: {
        type: String,
        default: ''
      },
      placeholder: {
        type: String,
        default: ''
      },
      isOptional: {
        type: Boolean,
        default: false
      },
      showRequired: {
        type: Boolean,
        default: false
      },
      label: {
        type: String,
        default: ''
      }
    },
    data: () => {
      return {
        mouseOnSuggestion: false,
        suggestions: [],
        suggestionIndex: 0,
        filledSuggestion: '',
        value: ''
      }
    },

    watch: {
      initialValue (value) {
        this.value = value
      }
    },

    mounted () {
      this.value = this.initialValue
    },

    methods: {
      onInput () {
        const value = event.target.value
        this.$emit('updateValue', this.name, value)
        this.searchNces(value)
      },

      searchNces (term) {
        this.suggestions = []
        this.filledSuggestion = ''
        algolia.schoolsIndex.search(term, { hitsPerPage: 5, aroundLatLngViaIP: false })
          .then(({ hits }) => {
            if (this.value !== term) {
              return
            }
            this.suggestions = hits
            this.suggestionIndex = 0
          })
      },

      navSearchUp () {
        this.suggestionIndex = Math.max(0, this.suggestionIndex - 1)
      },

      navSearchDown () {
        this.suggestionIndex = Math.min(this.suggestions.length, this.suggestionIndex + 1)
      },

      navSearchChoose () {
        const suggestion = this.suggestions[this.suggestionIndex]
        if (!suggestion) {
          return
        }
        this.navSearchClear()
        this.$emit('navSearchChoose', this.displayKey, suggestion)
      },

      onBlur () {
        this.navSearchClear()
      },

      navSearchClear () {
        this.suggestions = []
      },

      suggestionHover (index) {
        this.suggestionIndex = index
      }
    }
  }
</script>

<template>
  <div
    class="nces-search-input-component"
    :class="{ 'has-error': showRequired && !value }"
  >
    <span
      class="control-label"
    > {{ label }}
      <strong v-if="showRequired && !value"> {{ $t("common.required_field") }} </strong>
    </span>
    <span
      v-if="isOptional"
      class="control-label optional-text"
    >  ({{ $t("signup.optional") }}) </span>
    <input
      v-model="value"
      class="form-control"
      autocomplete="off"
      :name="name"
      :placeholder="placeholder"
      @keyup.up="navSearchUp"
      @keyup.down="navSearchDown"
      @keyup.enter="navSearchChoose"
      @keyup.esc.stop="navSearchClear"
      @blur="onBlur"
      @input="onInput"
    >
    <div class="suggestion-wrapper">
      <div
        class="list-group"
        :class="{ 'show-border': suggestions.length > 0 }"
      >
        <div
          v-for="(suggestion, index) in suggestions"
          :key="index"
          class="list-group-item"
          :class="{ active: index === suggestionIndex }"
          @mouseover="suggestionHover(index)"
          @click="navSearchChoose"
          @mousedown.prevent=""
        >
          <div
            v-if="displayKey === 'name'"
            class="school"
            v-html="suggestion._highlightResult.name.value"
          />
          <div
            class="district"
            :class="{ 'small-text': displayKey === 'name'}"
          >
            <span v-html="suggestion._highlightResult.district.value" />
            <div class="city-state">
              <span v-if="suggestion._highlightResult.city" v-html="suggestion._highlightResult.city.value" />
              <span> , </span>
              <span v-html="suggestion._highlightResult.state.value" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.suggestion-wrapper {
  position: relative;
  .list-group {
    position: absolute;
    z-index: 1;
    width: 100%;
    .list-group-item.active {
      background: #F2F2F2;
    }
    .school {
      @include font-p-3-small-button-text-black;
      font-weight: normal;
      text-align: left;
    }
    .district {
      @include font-p-3-small-button-text-black;
      font-weight: normal;
      display: flex;
      justify-content: space-between;
    }
    .small-text {
      font-size: 14px;
      line-height: 18px;
      margin-top: 5px;
    }
  }
  .show-border {
    border: 1px solid $dusk;
    border-radius: 2px;
  }
}
.optional-text {
  font-size: 12px;
}
</style>
