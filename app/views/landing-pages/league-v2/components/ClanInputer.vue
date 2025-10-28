<template>
  <div class="clan-form form-group">
    <!-- Input Group with Button -->
    <div class="input-group input-group-xs">
      <span class="input-group-addon">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="14"
          height="14"
          fill="currentColor"
          class="bi bi-search"
          viewBox="0 0 16 16"
        >
          <path d="M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001c.03.04.062.078.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1.007 1.007 0 0 0-.115-.1zM12 6.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0z" />
        </svg>
      </span>
      <input
        v-model="searchString"
        type="text"
        class="form-control"
        :placeholder="$t('league_v2.search_teams')"
        @input="debounceInput"
        @blur="handleBlurInput"
        @focus="handleFocusInput"
      >
      <div
        v-if="searchString !== ''"
        class="input-group-addon"
        style="cursor: pointer;"
        @click="clearInput"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="14"
          height="14"
          fill="currentColor"
          class="bi bi-x"
          viewBox="0 0 16 16"
        >
          <path d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708z" />
        </svg>
      </div>
    </div>
    <div class="suggestion-wrapper">
      <div class="list-group">
        <div
          v-for="{ slug, name, displayName, _id } in autoComplete"
          :key="slug"
          class="list-group-item"
          :title="displayName || name"
          @click="() => navigateToTeamLeaguePage(_id)"
        >
          <p>{{ displayName || name }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
const globalClan = {
  slug: '',
  _id: '',
  displayName: $.i18n.t('league_v2.global_clan_name'),
}

export default {
  props: {
    myClans: {
      type: Array,
      default: () => ([]),
    },
  },
  data () {
    return {
      searchString: '',
      autoComplete: [],
      lostFocusBuffer: [],
    }
  },
  mounted () {
    this.lostFocusBuffer = [globalClan, ...this.myClans]
  },
  methods: {
    debounceInput: _.debounce(async function (e) {
      const fuzzyString = e.target.value
      if (fuzzyString === '') {
        this.autoComplete = [globalClan, ...this.myClans]
        return
      }
      const res = await fetch(`/db/clan?project=slug,name,displayName&term=${fuzzyString}&limit=10`)
      const json = await res.json()
      if (res.status !== 200) {
        noty({
          text: json.message,
          layout: 'topCenter',
          type: 'error',
          timeout: 5000,
        })
        return
      }

      this.autoComplete = [globalClan, ...json]
      this.lostFocusBuffer = [...this.autoComplete]
    }, 500),

    navigateToTeamLeaguePage (clanId) {
      application.router.navigate(`/league/${clanId}`, { replace: true })
      this.$emit('changeClan', clanId)
    },

    handleFocusInput () {
      this.autoComplete = this.lostFocusBuffer
    },

    clearInput () {
      this.autoComplete = []
      this.lostFocusBuffer = [globalClan, ...this.myClans]
      this.searchString = ''
    },

    handleBlurInput () {
      setTimeout(() => {
        this.lostFocusBuffer = this.autoComplete
        this.autoComplete = []
      }, 150)
    },
  },
}
</script>

<style scoped lang="scss">
/* Custom extra-small input group */
.input-group-xs > .form-control,
.input-group-xs > .input-group-addon,
.input-group-xs > .input-group-btn > .btn {
  height: 30px;
  font-size: 12px;
  line-height: 1;
}

.input-group-xs > .input-group-addon {
  padding: 4px 8px;
}
.clan-form {
  font-size: 18px;
  line-height: 24px;
  justify-items: center;
  margin-top: 20px;
  position: relative;

  .input-group {
    width: 70%;
  }

  .suggestion-wrapper {
    position: absolute;
    width: 70%;
    z-index: 999;

    .list-group {
      width: 100%;
      max-height: 70vh;
      overflow-y: auto;
      z-index: 10;
      padding: 0;

      .list-group-item {
        height: 32px;
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

    }

  }

}
</style>