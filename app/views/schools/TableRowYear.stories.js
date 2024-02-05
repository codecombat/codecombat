import TableRowYear from './TableRowYear.vue'

export default {
  title: 'Pages/Schools/TableRowYear',
  component: TableRowYear,
  argTypes: {
    year: { control: 'number', defaultValue: 2021 },
    percents: { control: 'array', defaultValue: [20, 45, 50] }
  }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { TableRowYear },
  template: '<table-row-year v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
  year: 2021,
  percents: [20, 45, 50]
}

export const FiveColumns = Template.bind({})
FiveColumns.args = {
  year: 2022,
  percents: [10, 45, 60, null]
}

export const FiveColumnsMiddleEmpty = Template.bind({})
FiveColumnsMiddleEmpty.args = {
  year: 2022,
  percents: [10, 60, null, 45]
}
