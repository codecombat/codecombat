import AccessLevelIndicator from './AccessLevelIndicator.vue'

export default {
  title: 'AccessLevelIndicator',
  component: AccessLevelIndicator,
  argTypes: {
    level: {
      control: { type: 'select', options: ['free', 'sales-call', 'paid'] },
      description: 'The access level of the user',
    },
    boundary: {
      control: { type: 'select', options: ['free', 'sales-call', 'paid'] },
      description: 'The boundary level for displaying the badge',
    },
    displayBadge: {
      control: 'boolean',
      description: 'Whether to display the badge or not',
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
  boundary: 'sales-call',
  displayBadge: true,
  displayText: false,
  displayIcon: false,
}

export const SalesCall = Template.bind({})
SalesCall.args = {
  level: 'sales-call',
  boundary: 'paid',
  displayBadge: true,
  displayText: true,
  displayIcon: false,
}

export const Paid = Template.bind({})
Paid.args = {
  level: 'paid',
  boundary: 'paid',
  displayBadge: true,
  displayText: true,
  displayIcon: true,
}
