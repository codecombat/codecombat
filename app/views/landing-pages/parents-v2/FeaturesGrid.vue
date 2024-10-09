<template>
  <div class="table">
    <table-row
      v-for="(row, index) in rows"
      :key="index"
      :type="row.type"
      :gridless="row.gridless || false"
      :col1-content="row.content[0]"
      :col2-content="row.content[1]"
      :col3-content="row.content[2]"
      :col4-content="row.content[3]"
    />
  </div>
</template>

<script>
import TableRow from './TableRow.vue'
import { mapActions, mapGetters } from 'vuex'

export default {
  components: {
    TableRow,
  },
  data: () => ({
    rows: [
      { type: 'top-header', content: [null, null, $.i18n.t('parents_v2.grid_most_popular'), $.i18n.t('parents_v2.grid_best_value')] },
      { type: 'links', content: [null, $.i18n.t('parents_v2.grid_self_paced'), $.i18n.t('parents_v2.grid_1_sessions_weekly'), $.i18n.t('parents_v2.grid_2_sessions_weekly')] },
      { type: 'header', content: [$.i18n.t('parents_v2.grid_features'), $.i18n.t('parents_v2.grid_99_annual'), $.i18n.t('parents_v2.grid_219_monthly'), $.i18n.t('parents_v2.grid_399_monthly')] },
      { content: [$.i18n.t('parents_v2.grid_personalized_instruction'), null, '✓', '✓'] },
      { content: [$.i18n.t('parents_v2.grid_premium_access'), null, null, null], gridless: true },
      { type: 'subitem', content: [$.i18n.t('parents_v2.grid_codecombat'), '✓', '✓', '✓'], gridless: true },
      { type: 'subitem', content: [$.i18n.t('parents_v2.grid_ozaria'), null, '✓', '✓'], gridless: true },
      { type: 'subitem', content: [$.i18n.t('parents_v2.grid_ai_league'), '✓', '✓', '✓'], gridless: true },
      { type: 'subitem', content: [$.i18n.t('parents_v2.grid_codecombat_worlds'), '✓', '✓', '✓'], gridless: true },
      { type: 'subitem', content: [$.i18n.t('parents_v2.grid_ai_hackstack'), '✓', '✓', '✓'] },
      { content: [$.i18n.t('parents_v2.grid_parent_dashboard'), null, '✓', '✓'] },
      { content: [$.i18n.t('parents_v2.grid_lesson_slides'), null, '✓', '✓'] },
      { content: [$.i18n.t('parents_v2.grid_connections_applications'), null, '✓', '✓'] },
      { content: [$.i18n.t('parents_v2.grid_monthly_reports'), null, '✓', '✓'] },
      { content: [$.i18n.t('parents_v2.grid_completion_certificates'), null, '✓', '✓'] },
      { content: [$.i18n.t('parents_v2.grid_apcsp_option'), null, '✓', '✓'] },
      { content: [$.i18n.t('parents_v2.grid_class_recording'), null, '✓', '✓'] },
      { content: [$.i18n.t('parents_v2.grid_money_back'), null, '✓', '✓'] },
      { content: [$.i18n.t('parents_v2.grid_ai_hints_allowance'), 10, 20, 20] },
      { content: [$.i18n.t('parents_v2.grid_prompts_allowance'), 50, 200, 200] },
    ],
  }),
  computed: {
    ...mapGetters('products', ['basicAnnualSubscriptionForCurrentUser']),
    price () {
      const p = this.basicAnnualSubscriptionForCurrentUser
      let origPrice = 99
      if (p) {
        origPrice = (p.amount / 100).toFixed(2)
        if (origPrice % 1 === 0) {
          origPrice = Math.floor(origPrice)
        }
      }
      // we don't have coupon ID in parent page so no sale price here
      if (p?.formattedAmount) {
        return $.i18n.t('parents_v2.grid_self_paced_year_price_without_currency', { price: p.formattedAmount })
      } else {
        return $.i18n.t('parents_v2.grid_self_paced_year_price', { price: origPrice })
      }
    },
  },
  watch: {
    price: {
      immediate: true,
      handler (newPrice) {
        this.updatePriceInRows(newPrice)
      },
    },
  },
  created () {
    try {
      this.loadProducts()
    } catch (e) {
      console.error('Error loading products in parents-v2', e)
    }
  },
  mounted () {
    this.updatePriceInRows(this.price)
  },
  methods: {
    ...mapActions({
      loadProducts: 'products/loadProducts',
    }),
    updatePriceInRows (newPrice) {
      this.rows = this.rows.map(row => {
        if (row.type === 'header') {
          return { ...row, content: [row.content[0], newPrice, row.content[2], row.content[3]] }
        }
        return row
      })
    },
  },
}
</script>

<style scoped lang="scss">
@import 'app/styles/component_variables.scss';

.table {
  display: grid;
  grid-template-columns: 1fr 160px 160px 160px;
  @media screen and (max-width: $screen-sm) {
    grid-template-columns: 1fr 1fr 1fr 1fr;
  }
}
</style>
