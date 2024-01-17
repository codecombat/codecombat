<template>
  <div class="library">
    <div
      class="library__name"
    >
      {{ libraryName || '' }}
    </div>
    <div class="library__desc">
      {{ $t('library.welcome_dashboard') }}, <span
        v-if="libraryName"
        class="library__desc__name"
      >{{ libraryName }}!</span> {{ $t('library.adjust_dates_explore') }}
    </div>
    <sidebar-component
      :stats="licenseStats"
      :printing="printing"
    />
    <library-data-component
      :start-date="startDate"
      :end-date="endDate"
      :stats="licenseStats"
      :loading="loading"
      :printing="printing"
      @startDateChanged="onStartDateChanged"
      @endDateChanged="onEndDateChanged"
    />
  </div>
</template>

<script>
import SidebarComponent from './components/SidebarComponent'
import LibraryDataComponent from './components/LibraryDataComponent'
import moment from 'moment'
import { mapActions, mapGetters } from 'vuex'
const _ = require('lodash')

export default {
  name: 'MainView',
  components: {
    SidebarComponent,
    LibraryDataComponent
  },
  data () {
    return {
      startDate: moment().subtract(3, 'months').format('YYYY-MM-DD'),
      endDate: moment().format('YYYY-MM-DD'),
      clientId: null,
      printing: false
    }
  },
  methods: {
    ...mapActions({
      fetchClientId: 'apiClient/fetchClientId',
      fetchLicenseStats: 'apiClient/fetchLicenseStats'
    }),
    onStartDateChanged (val) {
      this.startDate = val
      this.debouncedFetchStats()
    },
    onEndDateChanged (val) {
      this.endDate = val
      this.debouncedFetchStats()
    },
    fetchStats ({ initialFetch = false } = {}) {
      const query = { clientId: this.clientId, startDate: this.startDate, endDate: this.endDate }
      this.fetchLicenseStats(query)
      if (!initialFetch) {
        window.tracker?.trackEvent('Partner board date-filter change', {
          startDate: this.startDate, endDate: this.endDate, spyId: window.serverSession?.amActually
        })
      }
    },
    debouncedFetchStats: _.debounce(function () {
      this.fetchStats()
    }, 3000)
  },
  computed: {
    ...mapGetters({
      licenseStats: 'apiClient/getLicenseStats',
      loading: 'apiClient/getLoadingByLicenseState'
    }),
    libraryName () {
      return this.licenseStats?.info?.name
    }
  },
  async created () {
    this.clientId = await this.fetchClientId()
    this.fetchStats({ initialFetch: true })
  }
}
</script>

<style scoped lang="scss">
@import "./css-mixins/variables";

.library {
  font-size: 62.5%; // 10px/16px = 62.5% -> 1rem = 10px
  font-family: Work Sans, "Open Sans", sans-serif;

  display: grid;
  grid-template-columns: [sidebar-start] 25rem [sidebar-end main-content-start] repeat(3, [main-start] 1fr [main-end]) [main-content-end];
  grid-template-rows: 7rem 1fr;

  &__name {
    grid-column: sidebar-start / sidebar-end;

    background: $color-yellow-1;
    box-shadow: 0px -4px 2rem 0px rgba(0, 0, 0, 0.20);
    text-transform: uppercase;
    text-align: center;

    color: $color-blue-2;
    font-feature-settings: 'clig' off, 'liga' off;
    font-size: 1.8rem;
    font-style: normal;
    font-weight: 600;
    line-height: 2.4rem; /* 133.333% */
    letter-spacing: 0.444px;

    padding: 2rem;
  }

  &__desc {
    grid-column: main-content-start / main-content-end;

    background: $color-blue-1 !important;
    -webkit-print-color-adjust: exact !important;
    color: $color-yellow-2;
    font-feature-settings: 'clig' off, 'liga' off;
    font-size: 1.4rem;
    font-style: normal;
    font-weight: 700;
    line-height: 2.4rem; /* 171.429% */
    letter-spacing: 0.44px;

    &__name {
      color: $color-white;
      text-transform: uppercase;
    }

    padding: 2rem;
  }
}
</style>
