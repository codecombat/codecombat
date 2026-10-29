const AIScenarioVersionsModal = require('views/editor/ai-scenario/AIScenarioVersionsModal')
const ThangTypeVersionsModal = require('views/editor/thang/ThangTypeVersionsModal')

// Renders the rows without the fetches: the modal's model request stays unanswered.
function rowLinks (Modal) {
  const modal = new Modal({}, '6adb146e0e103758a145abb2')
  modal.versions = { models: [{ attributes: { _id: 'v0', version: { major: 0, minor: 0 }, commitMessage: 'first' } }, { attributes: { _id: 'v3', version: { major: 0, minor: 3 } } }] }
  modal.render()
  const links = modal.$el.find('td a').map((i, a) => a.getAttribute('href')).get()
  modal.destroy()
  return links
}

describe('VersionsModal rows', function () {
  it('spell out the scenario version, so v0.0 (its _id is the original id) opens as itself and not as the latest', function () {
    expect(rowLinks(AIScenarioVersionsModal)).toEqual(['/editor/ai-scenario/v0?version=0.0', '/editor/ai-scenario/v3?version=0.3'])
  })

  it('stay plain ids for the other editors', function () {
    expect(rowLinks(ThangTypeVersionsModal)).toEqual(['/editor/thang/v0', '/editor/thang/v3'])
  })
})
