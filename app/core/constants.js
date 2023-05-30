// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
import utils from './utils';

const STARTER_LICENSE_COURSE_IDS = [
  "560f1a9f22961295f9427742", // Introduction to Computer Science
  "5632661322961295f9428638", // Computer Science 2
  "5789587aad86a6efb573701e", // Game Development 1
  "5789587aad86a6efb573701f" // Web Development 1
];

const LICENSE_PRESETS = {
  'CS1+CS2+GD1+WD1': STARTER_LICENSE_COURSE_IDS,
  'CS1+CS2+CS3+CS4': [
    '560f1a9f22961295f9427742', // Introduction to Computer Science
    '5632661322961295f9428638', // CS 2
    '56462f935afde0c6fd30fc8c', // CS 3
    '56462f935afde0c6fd30fc8d' // CS 4
  ],
  'CS1+CS2+CS3+CS4+CS5+CS6': [
    '560f1a9f22961295f9427742', // Introduction to Computer Science
    '5632661322961295f9428638', // CS 2
    '56462f935afde0c6fd30fc8c', // CS 3
    '56462f935afde0c6fd30fc8d', // CS 4
    '569ed916efa72b0ced971447', // CS 5
    '5817d673e85d1220db624ca4' // CS 6
  ],
  'CS1+CS2+GD1+GD2+WD1+WD2': [
    '560f1a9f22961295f9427742', // Introduction to Computer Science
    '5632661322961295f9428638', // CS 2
    '5789587aad86a6efb573701e', // Game Development 1
    '57b621e7ad86a6efb5737e64', // GD 2
    '5789587aad86a6efb573701f', // Web Development 1
    '5789587aad86a6efb5737020' // WD 2
  ],
  'CS1+CS2+GD1+GD2': [
    '560f1a9f22961295f9427742', // Introduction to Computer Science
    '5632661322961295f9428638', // CS 2
    '5789587aad86a6efb573701e', // Game Development 1
    '57b621e7ad86a6efb5737e64' // GD 2
  ],
  'CH1+CH2+CH3+CH4': OZARIA_COURSE_IDS
};

const FREE_COURSE_IDS = [
  "560f1a9f22961295f9427742" // Introduction to Computer Science
];

var OZARIA_COURSE_IDS = [
  "5d41d731a8d1836b5aa3cba1", // chapter 1
  "5d8a57abe8919b28d5113af1", // chapter 2
  "5e27600d1c9d440000ac3ee7", // chapter 3
  "5f0cb0b7a2492bba0b3520df" // chapter 4
];

const MAX_STARTER_LICENSES = 75;

const STARTER_LICENCE_LENGTH_MONTHS = 3;

const COCO_CHINA_CONST = {
  CONTACT_PHONE: '13810906731',
  CONTACT_EMAIL: 'china@codecombat.com'
};

const HTTP_STATUS_CODES = {
  PAYMENT_REQUIRED_CODE: 402,
};

const ESPORTS_PRODUCT_STATS = {
  TOURNAMENTS: {
    BASIC: 1,
    PRO: 3,
    MIN: 0,
  },
  TEAMS: {
    BASIC: 1,
    PRO: 5,
    MIN: 0,
    MAX: 10
  }
};

const LEADERBOARDNAME = {
  FULLNAME: 'fullName',
  ANONYMOUS: 'anonymous',
  NAME: 'name' // default
};

const HTML5_FMT_DATETIME_LOCAL = 'YYYY-MM-DDTHH:mm'; // moment 2.20+ do have this string but we use 2.19 :joy:
const HTML5_FMT_DATE_LOCAL = 'YYYY-MM-DD';
const HTML5_FMT_TIME_LOCAL = 'HH:mm';

const ANNOUNCEMENT_LIMIT = 11; // fetch 11 and display 10 only, so that we can check if all announcements loaded

export default {
  STARTER_LICENSE_COURSE_IDS,
  FREE_COURSE_IDS,
  MAX_STARTER_LICENSES,
  STARTER_LICENCE_LENGTH_MONTHS,
  COCO_CHINA_CONST,
  HTTP_STATUS_CODES,
  LICENSE_PRESETS,
  ESPORTS_PRODUCT_STATS,
  HTML5_FMT_DATETIME_LOCAL,
  HTML5_FMT_DATE_LOCAL,
  HTML5_FMT_TIME_LOCAL,
  LEADERBOARDNAME,
  ANNOUNCEMENT_LIMIT
};
