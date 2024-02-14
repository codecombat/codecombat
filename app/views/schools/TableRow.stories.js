import TableRow from './TableRow.vue'

export default {
  title: 'Pages/Schools/TableRow',
  component: TableRow,
  argTypes: {
    contents: { control: 'array', defaultValue: ['Content 1', 'Content 2', 'Content 3', 'Content 4'] },
    header: { control: 'boolean', defaultValue: false }
  }
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { TableRow },
  template: '<table-row v-bind="$props" />'
})

export const Default = Template.bind({})
Default.args = {
  contents: ['Content 1', 'Content 2-1 \n Content long 2-2 \n Content 2-3', 'Content 3', 'Content 4']
}

export const FiveColumns = Template.bind({})
FiveColumns.args = {
  contents: ['Content 1', 'Content 2', 'Content 3', 'Content 4', 'Content 5']
}

export const FiveColumnsMiddleEmpty = Template.bind({})
FiveColumnsMiddleEmpty.args = {
  contents: ['Content 1', 'Content 2', null, 'Content 4', 'Content 5']

}

export const HeaderRow = Template.bind({})
HeaderRow.args = {
  contents: ['Content 1', 'Content 2', null, 'Content 4', 'Content 5'],
  header: true
}
