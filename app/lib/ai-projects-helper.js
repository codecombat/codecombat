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
}
