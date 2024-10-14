import AccessLevelIndicator from './AccessLevelIndicator.vue'

export default {
  title: 'AccessLevelIndicator',
  component: AccessLevelIndicator,
  argTypes: {
    level: {
      control: { type: 'select', options: ['free', 'sales-call', 'paid'] },
      description: 'The access level of the user',
    },
    displayText: {
      control: 'boolean',
      description: 'Whether to display the text or not',
    },
    displayIcon: {
      control: 'boolean',
      description: 'Whether to display the icon or not',
    },
  },
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AccessLevelIndicator },
  template: '<access-level-indicator v-bind="$props" />',
})

export const Free = Template.bind({})
Free.args = {
  level: 'free',
  displayText: true,
  displayIcon: false,
}

export const SalesCall = Template.bind({})
SalesCall.args = {
  level: 'sales-call',
  displayText: false,
  displayIcon: true,
}

export const Paid = Template.bind({})
Paid.args = {
  level: 'paid',
  displayText: true,
  displayIcon: true,
}
