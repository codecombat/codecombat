<script>
export default {
  data: (() => ({
    searchString: '',
    autoComplete: [],
    lostFocusBuffer: []
  })),

  props: {
    maxWidth: {
      type: Number,
      default: 0
    }
  },

  methods: {
    debounceInput: _.debounce(async function (e) {
      const fuzzyString = e.target.value
      if (fuzzyString === '') {
        this.autoComplete = []
        return
      }
      const res = await fetch(`/db/clan?project=slug,name,displayName&term=${fuzzyString}&limit=10`)
      const json = await res.json()
      if (res.status !== 200) {
        noty({
          text: json.message,
          layout: 'topCenter',
          type: 'error',
          timeout: 5000
        })
        return
      }

      this.autoComplete = json
      this.lostFocusBuffer = json
    }, 500),

    navigateToTeamLeaguePage (clanSlug) {
      application.router.navigate(`/league/${clanSlug}`, { trigger: true })
    },

    handleFocusInput() {
      this.autoComplete = this.lostFocusBuffer
    },

    clearInput () {
      this.autoComplete = []
      this.lostFocusBuffer = []
      this.searchString = ""
    },

    handleBlurInput () {
      setTimeout(() => {
        this.lostFocusBuffer = this.autoComplete
        this.autoComplete = []
      }, 150)
    }
  }
}
</script>

<template>
  <div class="form-group input-clan-search" :style="maxWidth ? `max-width: ${maxWidth}px;` : null">
    <div class="input-group">
      <span class="input-group-addon">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-search" viewBox="0 0 16 16">
          <path d="M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001c.03.04.062.078.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1.007 1.007 0 0 0-.115-.1zM12 6.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0z"/>
        </svg>
      </span>
      <input @input="debounceInput" id="clan-search" class="form-control" v-model="searchString" autocomplete="off" :placeholder="'Search teams'" @blur="handleBlurInput" @focus="handleFocusInput"/>
      <div v-if="this.searchString !== ''" class="input-group-btn input-group-addon" style="cursor: pointer;" @click="clearInput">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-x" viewBox="0 0 16 16">
          <path d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708z"/>
        </svg>
      </div>
    </div>
    <div class="suggestion-wrapper">
      <div class="list-group">
        <div v-for="{ slug, name, displayName } in autoComplete" :key="slug" class="list-group-item" @click="() => navigateToTeamLeaguePage(slug)" :title="displayName || name">
          <p>{{ displayName || name }}</p>
        </div>
      </div>
    </div>
  </div>
</template>


<style lang="scss" scoped>
.input-clan-search {
  margin: 0 auto;
}

.form-control {
  color: black;
}

.suggestion-wrapper {
  color: black;
  position: relative;
}

.list-group-item {
  height: 34px;
  background-color: white;
  display: flex;
  align-items: center;
  flex-direction: row;
  align-items: center;

  cursor: pointer;

  &:hover {
    background-color: #dedede;
  }

  p {
    margin: 0;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
}

.list-group {
  position: absolute;
  width: 100%;
  max-height: 70vh;
  overflow-y: auto;
  z-index: 10;
  padding: 0;
}
</style>
