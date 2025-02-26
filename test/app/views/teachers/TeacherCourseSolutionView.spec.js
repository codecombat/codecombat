
const TeacherCourseSolution = require('views/teachers/TeacherCourseSolutionView.js')
const Level = require('models/Level')

describe('TeacherCourseSolution', function () {
  let view
  beforeEach(function () {
    view = new TeacherCourseSolution()
  })

  describe('updateShownLevels', function () {
    let mockLevels
    beforeEach(() => {
      mockLevels = [
        new Level({ slug: 'level1', practice: false }),
        new Level({ slug: 'level2', practice: true }),
        new Level({ slug: 'level3', practice: false }),
      ]
      view.levels = { models: mockLevels }
    })

    it('should update shownLevelModels to all levels when isJunior is false', () => {
      view.isJunior = false
      view.updateShownLevels('level1')
      expect(JSON.stringify(view.shownLevelModels)).toEqual(JSON.stringify(mockLevels))
    })

    it('should update shownLevelModels to non-practice levels when isJunior is true and showPracticeLevelsForSlug is false', () => {
      view.isJunior = true
      view.showPracticeLevelsForSlug = false
      view.updateShownLevels('level1')
      const expectedModels = mockLevels.filter(l => !l.get('practice'))
      expect(view.shownLevelModels.map(i => i.get('slug'))).toEqual(expectedModels.map(i => i.get('slug')))
    })

    it('should update shownLevelModels to specified level when isJunior is true and showPracticeLevelsForSlug is true', () => {
      view.isJunior = true
      view.showPracticeLevelsForSlug = true
      view.updateShownLevels('level1')
      const expectedModel = mockLevels.find(l => l.get('slug') === 'level1')
      expect(view.shownLevelModels.map(i => i.get('slug'))).toEqual([expectedModel].map(i => i.get('slug')))
    })
  })
})