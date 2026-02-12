module.exports = {
  checkIfProjectComplete (aiScenario, aiProjects) {
    if (aiScenario.minMsgs) { // if minMsgs is 0, let's still use old logic
      if (aiProjects.some(project => {
        return (project.totalChatMessages || 0) - (project.unsafeChatMessages?.length || 0) >= aiScenario.minMsgs
      })) {
        return true
      }
      return false
    }
    if (aiScenario.mode === 'learn to use' && aiProjects.some(project => (project.actionQueue?.length === 0))) {
      return true
    } else if (aiScenario.mode === 'use' && aiProjects.some(project => (project.isReadyToReview))) {
      return true
    }
    return false
  },
}
