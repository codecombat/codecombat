<script>
  import { getDisplayPermission } from "../../../common/utils"
  import IconShareGray from '../common/icons/IconShareGray'
  import IconArchived from './icons/IconArchive'

  export default {
    components: {
      IconShareGray,
      IconArchived
    },
    props: {
      language: {
        type: String,
        required: false,
        default: 'javascript'
      },
      numStudents: {
        type: Number,
        required: true
      },
      dateCreated: {
        type: String,
        required: true
      },
      sharePermission: {
        type: String,
      },
      archived: {
        type: Boolean,
        default: false
      }
    },

    computed: {
      languageImgSrc () {
        return `/images/ozaria/teachers/dashboard/png_icons/${this.language}.png`
      }
    },

    created () {
      if (this.language && !['javascript', 'python'].includes(this.language)) {
        throw new Error(`Unexpected language prop passed into ClassInfoRow.vue. Got: '${this.langauge}'`)
      }
    },
    methods: {
      displayPermission(permission) {
        return getDisplayPermission(permission)
      }
    }
  }
</script>

<template>
  <div class="class-info-row">
    <div class="stats-tab">
      <img :src="languageImgSrc">
      <span>{{ language[0].toUpperCase() + language.slice(1) }}</span>
    </div>
    <div class="stats-tab">
      <img src="/images/ozaria/teachers/dashboard/png_icons/MultipleUsers.png" />
      <span>{{ numStudents }} Student{{ numStudents === 1 ? '' : 's'}}</span>
    </div>
    <div class="stats-tab">
      <img src="/images/ozaria/teachers/dashboard/svg_icons/calendar.svg" />
      <span>{{ dateCreated }}</span>
    </div>
    <div
      v-if="sharePermission"
      class="stats-tab"
    >
      <icon-share-gray />
      <span>{{this.displayPermission(sharePermission)}}</span>
    </div>
    <div
      v-if="sharePermission && archived"
      class="stats-tab"
    >
      <icon-archived />
      {{ $t('general.archived') }}
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  .class-info-row {
    display: flex;
    flex-direction: row;
  }

  .stats-tab {
    img {
      height: 15px;
      width: auto;
      transform: translateY(-1px);
    }

    margin: 0 7.5px;
    @include font-p-4-paragraph-smallest-gray;
  }
</style>
