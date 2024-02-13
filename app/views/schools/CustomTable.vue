<template>
  <div>
    <div class="table">
      <table-row
        :header="true"
        :contents="headerContents"
      />
    </div>
    <div
      v-for="(row, index) in tableRows"
      :key="index"
      class="table"
    >
      <table-row-year
        :year="row.year"
        :percents="row.percents"
      />
      <table-row :contents="row.contents" />
    </div>
  </div>
</template>

<script>
import TableRow from './TableRow.vue'
import TableRowYear from './TableRowYear.vue'

export default {
  name: 'CustomTable',
  components: {
    TableRow,
    TableRowYear
  },
  props: {
    headerContents: {
      type: Array,
      required: true
    },
    tableRows: {
      type: Array,
      required: true
    }
  }
}
</script>

<style scoped lang="scss">
.table {
    display: flex;
    flex-direction: column;
    gap: 16px;
}
</style>
