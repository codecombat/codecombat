import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/ai_project.schema'

class AIProject extends CocoModel { }

AIProject.className = 'AIProject'
AIProject.schema = schema
AIProject.urlRoot = '/db/ai_project'
AIProject.prototype.urlRoot = '/db/ai_project'
AIProject.prototype.defaults = {
  visibility: 'public'
}

AIProject.AI_EVALUATION_YES = 'ai-eval-yes'
AIProject.AI_EVALUATION_NO = 'ai-eval-no'
AIProject.AI_EVALUATION_UNSURE = 'ai-eval-unsure'
AIProject.AI_EVALUATION_NONE = 'ai-eval-none'
AIProject.AI_EVALUATION_FLAGS = [
  AIProject.AI_EVALUATION_YES,
  AIProject.AI_EVALUATION_NO,
  AIProject.AI_EVALUATION_NONE,
  AIProject.AI_EVALUATION_UNSURE,
]

AIProject.getAiEvaluationFlag = (evaluation) => {
  if (!evaluation) return AIProject.AI_EVALUATION_NONE
  if (evaluation.completed === 'Yes') return AIProject.AI_EVALUATION_YES
  if (evaluation.completed === 'No') return AIProject.AI_EVALUATION_NO
  return AIProject.AI_EVALUATION_UNSURE
}

AIProject.getEvaluationLabel = (flag) => {
  const labels = {
    [AIProject.AI_EVALUATION_YES]: $.i18n.t('teacher_dashboard.ai_eval_yes'),
    [AIProject.AI_EVALUATION_NO]: $.i18n.t('teacher_dashboard.ai_eval_no'),
    [AIProject.AI_EVALUATION_UNSURE]: $.i18n.t('teacher_dashboard.ai_eval_unsure'),
  }
  return labels[flag] || null
}

AIProject.AI_STRUGGLING = 'ai-struggling' // if a student struggles to complete AIProject learn mode in less attempts
AIProject.AI_UNSAFE = 'ai-unsafe' // if a student uses abusive language or tries to mis-use the system via their chat messages

module.exports = AIProject
