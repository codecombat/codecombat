<script>
import { getDisplayPermission } from '../../../common/utils'
import IconShareGray from '../common/icons/IconShareGray'
import IconArchived from './icons/IconArchive'
import utils from 'core/utils'

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
    dateStart: {
      type: String,
      default: ''
    },
    dateEnd: {
      type: String,
      default: ''
    },
    sharePermission: {
      type: String
    },
    archived: {
      type: Boolean,
      default: false
    }
  },

  computed: {
    languageImgSrc () {
      return `/images/ozaria/teachers/dashboard/png_icons/${this.language}.png`
    },

    languageName () {
      return { javascript: 'JavaScript', cpp: 'C++' }[this.language] || _.string.titleize(this.language)
    },

    classDateString () {
      const currentYear = moment().year()
      const isUSLocale = moment.locale() === 'en'

      if (this.dateStart && this.dateEnd) {
        const start = moment(this.dateStart)
        const end = moment(this.dateEnd)

        if (start.year() === end.year()) {
          if (start.month() === end.month()) {
            // Same month and year
            if (start.year() === currentYear && isUSLocale) {
              // Same as current year and US locale, format as "MMM D - D"
              return `${start.format('MMM D')} - ${end.format('D')}`
            } else {
              // Different year or non-US locale, format as "ll - D"
              return `${start.format('ll')} - ${end.format('D')}`
            }
          } else {
            // Same year but different months
            if (start.year() === currentYear && isUSLocale) {
              // Same as current year and US locale, format as "MMM D - MMM D"
              return `${start.format('MMM D')} - ${end.format('MMM D')}`
            } else {
              // Different year or non-US locale, format as "ll - ll"
              return `${start.format('ll')} - ${end.format('ll')}`
            }
          }
        } else {
          // Different years, format as "ll - ll"
          return `${start.format('ll')} - ${end.format('ll')}`
        }
      }

      if (this.dateStart) {
        return moment(this.dateStart).format('ll')
      }

      return this.dateCreated
    }
  },

  created () {
    if (this.language && !utils.allowedLanguages.includes(this.language)) {
      throw new Error(`Unexpected language prop passed into ClassInfoRow.vue. Got: '${this.language}'`)
    }
  },
  methods: {
    displayPermission (permission) {
      return getDisplayPermission(permission)
    }
  }
}
</script>

<template>
  <div class="class-info-row">
    <div class="stats-tab">
      <img :src="languageImgSrc">
      <span>{{ languageName }}</span>
    </div>
    <div class="stats-tab">
      <img src="/images/ozaria/teachers/dashboard/png_icons/MultipleUsers.png">
      <span>{{ numStudents }} Student{{ numStudents === 1 ? '' : 's' }}</span>
    </div>
    <div class="stats-tab">
      <img src="/images/ozaria/teachers/dashboard/svg_icons/calendar.svg">
      <span>{{ classDateString }}</span>
    </div>
    <div
      v-if="sharePermission === 'read' || sharePermission === 'write'"
      class="stats-tab"
    >
      <icon-share-gray />
      <span>{{ displayPermission(sharePermission) }}</span>
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

    margin: 0 5px;
    @include font-p-4-paragraph-smallest-gray;
    white-space: nowrap;
  }
</style>
