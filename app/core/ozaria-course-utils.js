// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
// this is a copy of course info from utils.coffee for ozaria since we want to show oz info in coco now
const campaignIDs =
  {CHAPTER_ONE: '5d1a8368abd38e8b5363bad9'};

const freeCampaignIds = [campaignIDs.CHAPTER_ONE]; // CH1 campaign
const internalCampaignIds = ['5eb34fc8dc0fd35e8eae66b0']; // CH2 playtest

const courseIDs = {
  CHAPTER_ONE: '5d41d731a8d1836b5aa3cba1',
  CHAPTER_TWO: '5d8a57abe8919b28d5113af1',
  CHAPTER_THREE: '5e27600d1c9d440000ac3ee7',
  CHAPTER_FOUR: '5f0cb0b7a2492bba0b3520df'
};

const otherCourseIDs = {
  INTRODUCTION_TO_COMPUTER_SCIENCE: '560f1a9f22961295f9427742',
  GAME_DEVELOPMENT_1: '5789587aad86a6efb573701e',
  WEB_DEVELOPMENT_1: '5789587aad86a6efb573701f',
  COMPUTER_SCIENCE_2: '5632661322961295f9428638',
  GAME_DEVELOPMENT_2: '57b621e7ad86a6efb5737e64',
  WEB_DEVELOPMENT_2: '5789587aad86a6efb5737020',
  COMPUTER_SCIENCE_3: '56462f935afde0c6fd30fc8c',
  GAME_DEVELOPMENT_3: '5a0df02b8f2391437740f74f',
  COMPUTER_SCIENCE_4: '56462f935afde0c6fd30fc8d',
  COMPUTER_SCIENCE_5: '569ed916efa72b0ced971447',
  COMPUTER_SCIENCE_6: '5817d673e85d1220db624ca4'
};

const CSCourseIDs = [
  courseIDs.CHAPTER_ONE,
  courseIDs.CHAPTER_TWO,
  courseIDs.CHAPTER_THREE,
  courseIDs.CHAPTER_FOUR
];
const WDCourseIDs = [];
const orderedCourseIDs = [
  courseIDs.CHAPTER_ONE,
  courseIDs.CHAPTER_TWO,
  courseIDs.CHAPTER_THREE,
  courseIDs.CHAPTER_FOUR
];
const otherOrderedCourseIDs = [
  otherCourseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE,
  otherCourseIDs.GAME_DEVELOPMENT_1,
  otherCourseIDs.WEB_DEVELOPMENT_1,
  otherCourseIDs.COMPUTER_SCIENCE_2,
  otherCourseIDs.GAME_DEVELOPMENT_2,
  otherCourseIDs.WEB_DEVELOPMENT_2,
  otherCourseIDs.COMPUTER_SCIENCE_3,
  otherCourseIDs.GAME_DEVELOPMENT_3,
  otherCourseIDs.COMPUTER_SCIENCE_4,
  otherCourseIDs.COMPUTER_SCIENCE_5,
  otherCourseIDs.COMPUTER_SCIENCE_6
];

// Harcoding module names for simplicity
// Use db to store these later when we add sophisticated module functionality, right now its only used for UI
const courseModules = {};
courseModules[courseIDs.CHAPTER_ONE] = {
  '1': 'Introduction to Coding'
};
courseModules[courseIDs.CHAPTER_TWO] = {
  '1': 'Algorithms and Syntax',
  '2': 'Debugging',
  '3': 'Variables',
  '4': 'Conditionals',
  '5': 'Capstone Intro',
  '6': 'Capstone Project'
};
courseModules[courseIDs.CHAPTER_THREE] = {
  '1': 'Review',
  '2': 'For Loops',
  '3': 'Nesting',
  '4': 'While Loops',
  '5': 'Capstone'
};
courseModules[courseIDs.CHAPTER_FOUR] = {
  '1': 'Compound Conditionals',
  '2': 'Functions and Data Analysis',
  '3': 'Writing Functions',
  '4': 'Capstone'
};

const hourOfCodeOptions = {
  campaignId: freeCampaignIds[0],
  courseId: courseIDs.CHAPTER_ONE,
  name: 'Chapter 1: Up The Mountain',
  progressModalAfter: 1500000 //25 mins
};

module.exports = {
  courseModules
};
