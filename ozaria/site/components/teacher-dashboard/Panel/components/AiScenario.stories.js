import AiScenario from './AiScenario.vue'

export default {
  title: 'TeacherDashboard/Panel/AiScenario',
  component: AiScenario,
}

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AiScenario },
  template: '<AiScenario v-bind="$props" />',
})

export const Default = Template.bind({})
Default.args = {
  aiScenario: {
    name: 'Scenario 1',
    tool: 'gpt-4-turbo',
    initialActionQueue: ['action1', 'action2', 'action3', 'action4', 'action5'],
  },
  aiProjects: [
    {
      _id: '1',
      name: 'Project 1',
      user: 'User 1',
      visibility: 'Public',
      actionQueue: ['action1', 'action2'],
    },
    {
      _id: '2',
      name: 'Project 2',
      user: 'User 2',
      visibility: 'Private',
      actionQueue: ['action3'],
      wrongChoices: [
        {
          actionMessageId: 'action1',
          choiceIndex: 0,
          answerIndex: 1,
        },
        {
          actionMessageId: 'action2',
          choiceIndex: 1,
          answerIndex: 0,
        },
      ]
    },
    {
      _id: '3',
      name: 'Project 3',
      user: 'User 3',
      visibility: 'Public',
      actionQueue: [],
    },
  ],
}