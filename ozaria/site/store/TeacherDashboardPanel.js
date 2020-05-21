import moment from 'moment'

export const PRACTICE_LEVEL = 'PRACTICE_LEVEL'
export const CAPSTONE_LEVEL = 'CAPSTONE_LEVEL'
export const DRAGGABLE_ORDERING = 'DRAGGABLE_ORDERING'
export const INSERT_CODE = 'INSERT_CODE'
export const DRAGGABLE_STATEMENT_COMPLETION = 'DRAGGABLE_STATEMENT_COMPLETION'

/**
 * Payload for practiceLevelData for displaying on the teacher dashboard panel.
 */
function practiceLevelData ({
  starterCode,
  studentCode,
  solutionCode,
  language
}) {
  return {
    type: PRACTICE_LEVEL,
    starterCode,
    studentCode,
    solutionCode,
    language
  }
}
/**
 * Payload for practiceLevelData for displaying on the teacher dashboard panel.
 */
function capstoneLevelData ({
  studentCode,
  gameGoals,
  language
}) {
  return {
    type: CAPSTONE_LEVEL,
    studentCode,
    gameGoals,
    language
  }
}

function draggableOrderingData ({
  prompt,
  submissionText,
  solutionText,
  lastColText
}) {
  return {
    type: DRAGGABLE_ORDERING,
    prompt,
    submissionText,
    solutionText,
    lastColText
  }
}

function draggableStatementCompletionData ({
  prompt,
  submissionText,
  solutionText,
  labels
}) {
  return {
    type: DRAGGABLE_STATEMENT_COMPLETION,
    prompt,
    submissionText,
    solutionText,
    labels
  }
}
function insertCodeData ({
  prompt,
  code,
  studentSubmission,
  solution,
  options
}) {
  return {
    type: INSERT_CODE,
    prompt,
    code,
    studentSubmission,
    solution,
    options
  }
}

export default {
  namespaced: true,
  state: {
    // TODO: Temporary to keep panel open while working. Should start false.
    open: true,
    panelHeader: 'Module 1 | Hard Coded',
    studentInfo: {
      name: 'Student Name',
      completedContent: moment().format('MMM D, YYYY H:mm A')
    },
    conceptCheck: {
      learningGoal: 'Lorem Ipsum',
      totalSubmissions: 0,
      timeSpent: -1,
      classAverage: -1
    },
    //     panelSessionContent: practiceLevelData({
    //       starterCode: `var name = hero.length('codestatement');`,
    //       studentCode: `const code = hero.length(rawr);\ncode.statement(example);\ncode.statement2(example2);`,
    //       solutionCode: `const code = hero.length(rawr);
    // code.statement(example);
    // code.statement2(example2);`,
    //       language: 'javascript'
    //     })

    //   panelSessionContent: capstoneLevelData({
    //     studentCode: `var name = hero.walkLeft();\nconst var2 = 10;\nhero.walkUp();\nhero.walkDown();`,
    //     language: 'javascript',
    //     gameGoals: [
    //       {
    //         description: 'Create first character using a variable',
    //         completed: Math.random() < 0.5
    //       },
    //       {
    //         description: 'Have each character SAY at least one thing',
    //         completed: Math.random() < 0.5
    //       },
    //       {
    //         description: 'Use if statements to branch your dialogue',
    //         completed: Math.random() < 0.5
    //       },
    //       {
    //         description: 'Another goal that is pulled from the level in some way.',
    //         completed: Math.random() < 0.5
    //       },
    //       {
    //         description: 'Set background',
    //         completed: Math.random() < 0.5
    //       },
    //       {
    //         description: 'Have your characters ENTER the screen',
    //         completed: Math.random() < 0.5
    //       }
    //     ]
    //   })

    // panelSessionContent: draggableOrderingData({
    //   prompt: 'Drag on the steps on the left into the correct order to make a sandwich.',
    //   submissionText: [
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.', correct: true },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.', correct: false },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.', correct: false },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.', correct: true }
    //   ],
    //   solutionText: [
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //   ],
    //   lastColText: [
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //     { text: 'Lorem ipsum, dolor sit amet, consectur adipscing.' },
    //   ]
    // })
    // panelSessionContent: draggableStatementCompletionData({
    //   prompt: 'Drag the blocks into the correct place in the code statement.',
    //   submissionText: [
    //     { text: '"snake"', correct: true },
    //     { text: 'avatars', correct: false },
    //     { text: 'setArt', correct: false }
    //   ],
    //   solutionText: [
    //     { text: 'avatars' },
    //     { text: 'setArt' },
    //     { text: '"snake"' }
    //   ],
    //   labels: [
    //     { text: 'object' },
    //     { text: 'method' },
    //     { text: 'argument' }
    //   ]
    // })
    panelSessionContent: insertCodeData({
      prompt: 'Add the line of code to call Capella\'s name.',
      code: `var character_name = thisis.veryLong(codestatement);\ncode.statement(example);\ncode.statement(example)\n//answer goes here\ncharacter_name = very.short(code)`,
      studentSubmission: {
        text: 'code.statement(example)',
        correct: false
      },
      solution: {
        text: 'correct.statement(example)'
      },
      options: [
        { text: 'code.statement(example)' },
        { text: 'code.statement(example2)' },
        { text: 'code.statement(example3)' },
        { text: 'code.statement(example4)' }
      ]
    })
  },

  mutations: {
    togglePanel (state) {
      state.open = !state.open
    },
    setPanelHeader (state, header) {
      state.panelHeader = header
    },
    setStudentInfo (state, { name, completedContent }) {
      state.studentInfo = { name, completedContent }
    }
  }
}
