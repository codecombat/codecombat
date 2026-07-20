module.exports = {
  checkIfProjectComplete (aiScenario, aiProjects) {
    if (aiProjects?.length === 0) return false
    if (aiScenario.minMsgs) { // if minMsgs is 0, let's still use old logic
      if (aiProjects.some(project => {
        return (project.totalChatMessages || 0) - (project.unsafeChatMessages?.length || 0) >= aiScenario.minMsgs
      })) {
        return true
      }
      return false
    }
    const latestProject = aiProjects[aiProjects.length - 1]
    if (aiScenario.mode === 'learn to use') {
      return latestProject.actionQueue?.length === 0
    } else {
      return !!latestProject.isReadyToReview
    }
  },
  // a student had to do multiple attempts while selecting correct option in learn mode
  hasStruggledOnProject (aiProjects) {
    const MAX_WRONG_CHOICES = 1
    return (aiProjects || []).some(project => {
      const wrongChoices = project.wrongChoices || []
      const counts = wrongChoices.reduce((acc, obj) => {
        const key = obj.actionMessageId
        acc[key] = (acc?.[key] || 0) + 1
        return acc
      }, {})
      return Object.values(counts).some(v => v > MAX_WRONG_CHOICES)
    })
  },
}
