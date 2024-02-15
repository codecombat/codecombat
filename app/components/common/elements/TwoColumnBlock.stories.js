import TwoColumnBlock from './TwoColumnBlock.vue'

export default {
  title: 'Example/TwoColumnBlock',
  component: TwoColumnBlock
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { TwoColumnBlock },
  template: `
    <two-column-block v-bind="$props">
      <template v-slot:column-one>
        {{ columnOneContent }}
      </template>
      <template v-slot:column-two>
        {{ columnTwoContent }}
      </template>
    </two-column-block>
  `
})

export const Default = Template.bind({})
Default.args = {
  columnOneContent: 'Content for Column One',
  columnTwoContent: 'Content for Column Two'
}
