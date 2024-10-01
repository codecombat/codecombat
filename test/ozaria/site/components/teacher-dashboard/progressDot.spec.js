import { shallowMount } from '@vue/test-utils'
import ProgressDot from 'ozaria/site/components/teacher-dashboard/common/progress/progressDot.vue' // replace with your actual component path

describe('ProgressDot', () => {
  let wrapper

  beforeEach(() => {
    wrapper = shallowMount(ProgressDot)
  })

  describe('filterPracticeLevelsToDisplay', () => {
    it('returns last three levels including first "assigned" one from end', () => {
      const practiceLevels = [
        { name: 'Level 1', isCompleted: true, inProgress: true }, // complete
        { name: 'Level 2', isCompleted: false, inProgress: true }, // progress
        { name: 'Level 3', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 4', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 5', isCompleted: false, inProgress: false }, // assigned
      ]

      const result = wrapper.vm.filterPracticeLevelsToDisplay(practiceLevels)

      expect(result).toEqual([
        { name: 'Level 1', status: 'complete' },
        { name: 'Level 2', status: 'progress' },
        { name: 'Level 3', status: 'assigned' },
      ])
    })

    it('returns last three levels if no "assigned" level is found', () => {
      const practiceLevels = [
        { name: 'Level 1', isCompleted: true, inProgress: true }, // complete
        { name: 'Level 2', isCompleted: true, inProgress: true }, // complete
        { name: 'Level 3', isCompleted: true, inProgress: true }, // complete
        { name: 'Level 4', isCompleted: true, inProgress: true }, // complete
        { name: 'Level 5', isCompleted: true, inProgress: true }, // complete
      ]

      const result = wrapper.vm.filterPracticeLevelsToDisplay(practiceLevels)

      expect(result).toEqual([
        { name: 'Level 3', status: 'complete' },
        { name: 'Level 4', status: 'complete' },
        { name: 'Level 5', status: 'complete' },
      ])
    })

    it('shows the first three levels if all are "assigned"', () => {
      const practiceLevels = [
        { name: 'Level 1', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 2', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 3', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 4', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 5', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 6', isCompleted: false, inProgress: false }, // assigned
      ]

      const result = wrapper.vm.filterPracticeLevelsToDisplay(practiceLevels)

      expect(result).toEqual([
        { name: 'Level 1', status: 'assigned' },
        { name: 'Level 2', status: 'assigned' },
        { name: 'Level 3', status: 'assigned' },
      ])
    })

    it('shows all levels if there are only three and they are complete, in-progress, assigned', () => {
      const practiceLevels = [
        { name: 'Level 1', isCompleted: true, inProgress: true }, // complete
        { name: 'Level 2', isCompleted: false, inProgress: true }, // progress
        { name: 'Level 3', isCompleted: false, inProgress: false }, // assigned
      ]

      const result = wrapper.vm.filterPracticeLevelsToDisplay(practiceLevels)

      expect(result).toEqual([
        { name: 'Level 1', status: 'complete' },
        { name: 'Level 2', status: 'progress' },
        { name: 'Level 3', status: 'assigned' },
      ])
    })

    it('returns last three levels including first "inProgress" one from end', () => {
      const practiceLevels = [
        { name: 'Level 1', isCompleted: true, inProgress: false }, // complete
        { name: 'Level 2', isCompleted: true, inProgress: false }, // complete
        { name: 'Level 3', isCompleted: true, inProgress: false }, // complete
        { name: 'Level 4', isCompleted: true, inProgress: false }, // complete
        { name: 'Level 5', isCompleted: false, inProgress: true }, // in progress
        { name: 'Level 6', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 7', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 8', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 9', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 10', isCompleted: false, inProgress: false }, // assigned
      ]

      const result = wrapper.vm.filterPracticeLevelsToDisplay(practiceLevels)

      expect(result).toEqual([
        { name: 'Level 4', status: 'complete' },
        { name: 'Level 5', status: 'progress' },
        { name: 'Level 6', status: 'assigned' },
      ])
    })

    it('returns last completed ones and first assigned if there is no in-progress one.', () => {
      const practiceLevels = [
        { name: 'Level 1', isCompleted: true, inProgress: false }, // complete
        { name: 'Level 2', isCompleted: true, inProgress: false }, // complete
        { name: 'Level 3', isCompleted: true, inProgress: false }, // complete
        { name: 'Level 4', isCompleted: true, inProgress: false }, // complete
        { name: 'Level 5', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 6', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 7', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 8', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 9', isCompleted: false, inProgress: false }, // assigned
        { name: 'Level 10', isCompleted: false, inProgress: false }, // assigned
      ]

      const result = wrapper.vm.filterPracticeLevelsToDisplay(practiceLevels)

      expect(result).toEqual([
        { name: 'Level 3', status: 'complete' },
        { name: 'Level 4', status: 'complete' },
        { name: 'Level 5', status: 'assigned' },
      ])
    })
  })
})