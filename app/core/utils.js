// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

let campaignIDs, compare, courseIDs, courseModules, courseModuleInfo, courseModuleLevels, coursesWithProjects, CSCourseIDs, freeCampaignIds, hourOfCodeOptions, injectCSS, internalCampaignIds, left, orderedCourseIDs, otherCourseIDs, otherOrderedCourseIDs, replaceText, slugify, WDCourseIDs
const product = ((left = typeof COCO_PRODUCT !== 'undefined' && COCO_PRODUCT !== null ? COCO_PRODUCT : __guard__(typeof process !== 'undefined' && process !== null ? process.env : undefined, x => x.COCO_PRODUCT))) != null ? left : 'codecombat'
const shaTag = ((left = typeof SHA_TAG !== 'undefined' && SHA_TAG !== null ? SHA_TAG : __guard__(typeof process !== 'undefined' && process !== null ? process.env : undefined, x => x.SHA_TAG))) != null ? left : 'unknown'
const isCodeCombat = product === 'codecombat'
const isOzaria = !isCodeCombat
const _ = require('lodash')
const useWebsocket = false

// Yuqiang: i don't know why we use same slugify from different source but let's keep it right now since change it sometimes trigger unbelievable bug
if (isCodeCombat) {
  if (global && global._ && global._.str && global._.str.slugify) { // TODO: why _.string on client and _.str on server?
    ({
      slugify
    } = global._.str) // server
  } else if (_ && _.string && _.string.slugify) {
    ({
      slugify
    } = _.string) // client
  }
} else {
  ({
    slugify
  } = require('underscore.string')) // TODO: why _.string on client and _.str on server?
}

const getCorrectName = function (session) {
  if (session.fullName) { // already handle anonymize in server side
    return session.fullName.replace(/^Anonymous/, $.i18n.t('general.player'))
  } else if (session.get('fullName')) {
    return session.get('fullName').replace(/^Anonymous/, $.i18n.t('general.player'))
  } else {
    return session.creatorName || session.get('creatorName') || $.i18n.t('play.anonymous')
  }
}

const getAnonymizationStatus = function (league, supermodel) {
  if (!league || !features.enableAnonymization) {
    return new Promise((resolve, reject) => resolve(false))
  }

  const fetchAnonymous = $.get('/esports/anonymous/' + league)
  supermodel.trackRequest(fetchAnonymous)
  return new Promise((resolve, reject) => fetchAnonymous.then(res => {
    return resolve(res.anonymous)
  }))
}

const anonymizingUser = function (user) {
  const id = (user != null ? user.id : undefined) != null ? (user != null ? user.id : undefined) : user
  const hashString = str => // hash * 33 + c
        (__range__(0, str.length, false).map((i) => str.charCodeAt(i))).reduce((hash, char) => ((hash << 5) + hash) + char, 5381)
  return $.i18n.t('general.player') + ' ' + (Math.abs(hashString(id)) % 10000)
}

const clone = function (obj) {
  if ((obj === null) || (typeof (obj) !== 'object')) { return obj }
  const temp = obj.constructor()
  for (const key in obj) {
    temp[key] = clone(obj[key])
  }
  return temp
}

const combineAncestralObject = function (obj, propertyName) {
  const combined = {}
  while (obj != null ? obj[propertyName] : undefined) {
    for (const key in obj[propertyName]) {
      const value = obj[propertyName][key]
      if (combined[key]) { continue }
      combined[key] = value
    }
    if (obj.__proto__) {
      obj = obj.__proto__
    } else {
      // IE has no __proto__. TODO: does this even work? At most it doesn't crash.
      obj = Object.getPrototypeOf(obj)
    }
  }
  return combined
}

// Walk a key chain down to the value. Can optionally set newValue instead.
// Same as in world_utils, but don't want mutual imports
const downTheChain = function (obj, keyChain, newValue) {
  if (newValue == null) { newValue = undefined }
  if (!obj) { return null }
  if (!_.isArray(keyChain)) { return obj[keyChain] }
  let value = obj
  while (keyChain.length && value) {
    if ((newValue !== undefined) && (keyChain.length === 1)) {
      value[keyChain[0]] = newValue
      return newValue
    }
    value = value[keyChain[0]]
    keyChain = keyChain.slice(1)
  }
  return value
}

const countries = [
  { country: 'united-states', countryCode: 'US', ageOfConsent: 13, addressesIncludeAdministrativeRegion: true },
  { country: 'china', countryCode: 'CN', addressesIncludeAdministrativeRegion: true },
  { country: 'brazil', countryCode: 'BR' },

  // Loosely ordered by decreasing traffic as measured 2016-09-01 - 2016-11-07
  // TODO: switch to alphabetical ordering
  { country: 'united-kingdom', countryCode: 'GB', inEU: true, ageOfConsent: 13 },
  { country: 'russia', countryCode: 'RU' },
  { country: 'australia', countryCode: 'AU', addressesIncludeAdministrativeRegion: true },
  { country: 'canada', countryCode: 'CA', addressesIncludeAdministrativeRegion: true },
  { country: 'france', countryCode: 'FR', inEU: true, ageOfConsent: 15 },
  { country: 'taiwan', countryCode: 'TW' },
  { country: 'ukraine', countryCode: 'UA' },
  { country: 'poland', countryCode: 'PL', inEU: true, ageOfConsent: 13 },
  { country: 'spain', countryCode: 'ES', inEU: true, ageOfConsent: 13 },
  { country: 'germany', countryCode: 'DE', inEU: true, ageOfConsent: 16 },
  { country: 'netherlands', countryCode: 'NL', inEU: true, ageOfConsent: 16 },
  { country: 'hungary', countryCode: 'HU', inEU: true, ageOfConsent: 16 },
  { country: 'japan', countryCode: 'JP' },
  { country: 'turkey', countryCode: 'TR' },
  { country: 'south-africa', countryCode: 'ZA' },
  { country: 'indonesia', countryCode: 'ID' },
  { country: 'new-zealand', countryCode: 'NZ' },
  { country: 'finland', countryCode: 'FI', inEU: true, ageOfConsent: 13 },
  { country: 'south-korea', countryCode: 'KR' },
  { country: 'mexico', countryCode: 'MX', addressesIncludeAdministrativeRegion: true },
  { country: 'vietnam', countryCode: 'VN' },
  { country: 'singapore', countryCode: 'SG' },
  { country: 'colombia', countryCode: 'CO' },
  { country: 'india', countryCode: 'IN', addressesIncludeAdministrativeRegion: true },
  { country: 'thailand', countryCode: 'TH' },
  { country: 'belgium', countryCode: 'BE', inEU: true, ageOfConsent: 13 },
  { country: 'sweden', countryCode: 'SE', inEU: true, ageOfConsent: 13 },
  { country: 'denmark', countryCode: 'DK', inEU: true, ageOfConsent: 13 },
  { country: 'czech-republic', countryCode: 'CZ', inEU: true, ageOfConsent: 15 },
  { country: 'hong-kong', countryCode: 'HK' },
  { country: 'italy', countryCode: 'IT', inEU: true, ageOfConsent: 16, addressesIncludeAdministrativeRegion: true },
  { country: 'romania', countryCode: 'RO', inEU: true, ageOfConsent: 16 },
  { country: 'belarus', countryCode: 'BY' },
  { country: 'norway', countryCode: 'NO', inEU: true, ageOfConsent: 13 }, // GDPR applies to EFTA
  { country: 'philippines', countryCode: 'PH' },
  { country: 'lithuania', countryCode: 'LT', inEU: true, ageOfConsent: 16 },
  { country: 'argentina', countryCode: 'AR' },
  { country: 'malaysia', countryCode: 'MY', addressesIncludeAdministrativeRegion: true },
  { country: 'pakistan', countryCode: 'PK' },
  { country: 'serbia', countryCode: 'RS' },
  { country: 'greece', countryCode: 'GR', inEU: true, ageOfConsent: 15 },
  { country: 'israel', countryCode: 'IL', inEU: true },
  { country: 'portugal', countryCode: 'PT', inEU: true, ageOfConsent: 13 },
  { country: 'slovakia', countryCode: 'SK', inEU: true, ageOfConsent: 16 },
  { country: 'ireland', countryCode: 'IE', inEU: true, ageOfConsent: 16 },
  { country: 'switzerland', countryCode: 'CH', inEU: true, ageOfConsent: 16 }, // GDPR applies to EFTA
  { country: 'peru', countryCode: 'PE' },
  { country: 'bulgaria', countryCode: 'BG', inEU: true, ageOfConsent: 14 },
  { country: 'venezuela', countryCode: 'VE' },
  { country: 'austria', countryCode: 'AT', inEU: true, ageOfConsent: 14 },
  { country: 'croatia', countryCode: 'HR', inEU: true, ageOfConsent: 16 },
  { country: 'saudia-arabia', countryCode: 'SA' },
  { country: 'chile', countryCode: 'CL' },
  { country: 'united-arab-emirates', countryCode: 'AE' },
  { country: 'kazakhstan', countryCode: 'KZ' },
  { country: 'estonia', countryCode: 'EE', inEU: true, ageOfConsent: 13 },
  { country: 'iran', countryCode: 'IR' },
  { country: 'egypt', countryCode: 'EG' },
  { country: 'ecuador', countryCode: 'EC' },
  { country: 'slovenia', countryCode: 'SI', inEU: true, ageOfConsent: 15 },
  { country: 'macedonia', countryCode: 'MK' },
  { country: 'cyprus', countryCode: 'CY', inEU: true, ageOfConsent: 14 },
  { country: 'latvia', countryCode: 'LV', inEU: true, ageOfConsent: 13 },
  { country: 'luxembourg', countryCode: 'LU', inEU: true, ageOfConsent: 16 },
  { country: 'malta', countryCode: 'MT', inEU: true, ageOfConsent: 16 },
  { country: 'lichtenstein', countryCode: 'LI', inEU: true }, // GDPR applies to EFTA
  { country: 'iceland', countryCode: 'IS', inEU: true } // GDPR applies to EFTA
]

const inEU = country => !!__guard__(_.find(countries, c => c.country === slugify(country)), x1 => x1.inEU)

const addressesIncludeAdministrativeRegion = country => !!__guard__(_.find(countries, c => c.country === slugify(country)), x1 => x1.addressesIncludeAdministrativeRegion)

const ageOfConsent = function (countryName, defaultIfUnknown) {
  if (defaultIfUnknown == null) { defaultIfUnknown = 0 }
  if (!countryName) { return defaultIfUnknown }
  const country = _.find(countries, c => c.country === slugify(countryName))
  if (!country) { return defaultIfUnknown }
  if (country.ageOfConsent) { return country.ageOfConsent }
  if (country.inEU) { return 16 }
  return defaultIfUnknown
}

const countryCodeToFlagEmoji = function (code) {
  if ((code != null ? code.length : undefined) !== 2) { return code }
  return (Array.from(code.toUpperCase()).map((c) => String.fromCodePoint(c.charCodeAt() + 0x1F1A5))).join('')
}

const countryCodeToName = function (code) {
  let country
  if ((code != null ? code.length : undefined) !== 2) { return code }
  if (!(country = _.find(countries, { countryCode: code.toUpperCase() }))) { return code }
  return titleize(country.country)
}

const countryNameToCode = country => __guard__(_.find(countries, { country: (country != null ? country.toLowerCase() : undefined) }), x1 => x1.countryCode)

var titleize = s => // Turns things like 'dungeons-of-kithgard' into 'Dungeons of Kithgard'
    _.string.titleize(_.string.humanize(s)).replace(
      / (and|or|but|nor|yet|so|for|a|an|the|in|to|of|at|by|up|for|off|on|with|from)(?= )/ig,
      word => word.toLowerCase()
    )

if (isCodeCombat) {
  campaignIDs = {
    JUNIOR: '65c56663d2ca2055e65676af',
    INTRO: '55b29efd1cd6abe8ce07db0d',
    HACKSTACK: '663b25881c568468efc7b51c'
  }

  freeCampaignIds = [campaignIDs.JUNIOR, campaignIDs.INTRO] // Junior, CS1 campaign
  internalCampaignIds = [] // Ozaria has one of these, CoCo doesn't

  courseIDs = {
    JUNIOR: '65f32b6c87c07dbeb5ba1936',
    HACKSTACK: '663b25f11c568468efc8adde',
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
  }

  courseModuleInfo = {
    [courseIDs.JUNIOR]: {
      1: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1Y5_Eu5uVPrHpnqcoSuGfFR8qeAYkTIyE'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1Y5_Eu5uVPrHpnqcoSuGfFR8qeAYkTIyE'
        }
      },
      2: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/18cse7g50mdcEwLiTovHR_edPhYd77UDM'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/18cse7g50mdcEwLiTovHR_edPhYd77UDM'
        }
      },
      3: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1iQJEvgaQ0z3AMw64fTOwcZOYKu0zOqOr'
        },  
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1iQJEvgaQ0z3AMw64fTOwcZOYKu0zOqOr'
        }
      },
      4: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1v6DZfzb3zp_lmjM00vZvjTSRoUpBSqq8'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1v6DZfzb3zp_lmjM00vZvjTSRoUpBSqq8'
        }
      },
      5: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1-kKodhaMC1oL1OVnolQ5V9OVM0VEI7kF'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1-kKodhaMC1oL1OVnolQ5V9OVM0VEI7kF'
        }
      },
      6: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/11SIA1sYVRdq69u0o0w0ihAF65MjoIq2W'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/11SIA1sYVRdq69u0o0w0ihAF65MjoIq2W'
        }
      },
      7: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1-U3aJggcZibizu8fZPdT8veKOqby9uBj'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1-U3aJggcZibizu8fZPdT8veKOqby9uBj'
        }
      },
      8: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1hnLLCpxF4HeAhO3WVAaB9tYmoYQ9aKx1'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1hnLLCpxF4HeAhO3WVAaB9tYmoYQ9aKx1'
        }
      }
    },
    [courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE]: {
      1: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1wApGYfq9gM3C9G3_zkkyWDijiEYyEcgX?usp=sharing'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1asYzKfqDHWLK2ibxWPgRKkq8_VEN667c?usp=sharing'
        }
      }
    },
    [courseIDs.GAME_DEVELOPMENT_1]: {},
    [courseIDs.WEB_DEVELOPMENT_1]: {},
    [courseIDs.COMPUTER_SCIENCE_2]: {
      1: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1y8yTPgOg-_S8v_J5zbXpbQQ9hP4rZHXE?usp=drive_link'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1hzrex4_AMpredS748hlEv_zSjwHaN210?usp=drive_link'
        }
      },
      2: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1WNz-vxVxsy7MpbYMf-Reo1P-jOQ6vW94?usp=drive_link'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1AomycHLH5axRIguXKEdi2rMk95URbHWG?usp=drive_link'
        }
      },
      3: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1r2nWGfTyHZrUvFeNyfnbN_A06ZYn2CRk?usp=drive_link'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1ihBZmQp74wfg92bapWV0PuYH296TmkyZ?usp=sharing'
        }
      },
      4: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1CuXgk0i_z7lZ0W5gEkU3L2how-ZlYaeM?usp=drive_link'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1L80QV9Wv6J3IQx_lnQpB51Gfzb4VB05w?usp=drive_link'
        }
      },
      5: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1SRzgEcIbOX7jozBL-oDhfoLVWU1oEu1Y?usp=drive_link'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1whhA6ehkZcJweoAH0c27SK4yR8OMLv3j?usp=drive_link'
        }
      },
      6: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1cdO9C1k9N5x6BdbohVaAzncuzBSItv7z?usp=drive_link'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1mWy01Zz-6_G6jBEYYaxr1zkvq660McHp?usp=drive_link'
        }
      },
      7: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1HAxoKk6oNQwPm0OolRvf_vWISBrb_LSd?usp=drive_link'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/16HAarJNeM2EpFOfRS95BoOE-GQjendHB?usp=drive_link'
        }
      },
    },
    [courseIDs.GAME_DEVELOPMENT_2]: {},
    [courseIDs.WEB_DEVELOPMENT_2]: {},
    [courseIDs.COMPUTER_SCIENCE_3]: {
      1: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1ZjhjlqcIGHOWENIpAn0Kz5DaJFHZJMTd?usp=sharing'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/10JaIo3NFXvaB9dEPo9hYSZ9z9owzmVQ9?usp=drive_link'
        }
      },
      2: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1SDTVOD2tTfe5eM7rrJ4BqFPSFwL3Xb19?usp=sharing'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1Ub6AwI6XRP7LKcWzVdFOSZ7n8f-oE1Ck?usp=drive_link'
        }
      },
      3: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1TdLym5_SNIGoEDKyzVSAk0fw1XQCe_Be?usp=sharing'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1AAzbz-nZi4g9dQvs-fJKGtVAZv7sjfhJ?usp=drive_link'
        }
      },
      4: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1JapqAXlXFjz9Qgp4sL3rJpnZkv1S6ASk?usp=sharing'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1DPeWPZrhXHQC4pBJDb-kn0-bOv6gIiw4?usp=drive_link'
        }
      },
      5: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1sm6gKudpfWnO3OAeu5DdOt-3ACp4ouqQ?usp=drive_link'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1Q6wRGMunTM5CH68YtqdqHFl2udEmS-L0?usp=sharing'
        }
      },
      6: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/178Gt7U2Oxvo0bIDXlYqiepHUqDu0ZwzG?usp=drive_link'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1i__s8tGAuPVhnic6LuNNKBubqrelrQYb?usp=sharing'
        }
      },
      7: {
        python: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1m2E9wo3ZF1FGR2jQhQ16rCIsjCuvnH1i?usp=drive_link'
        },
        javascript: {
          lessonSlidesUrl: 'https://drive.google.com/drive/folders/1kdH7_VVlnXqXVSP0KDWGghRcAP6y-lUC?usp=sharing'
        }
      }
    },
    [courseIDs.GAME_DEVELOPMENT_3]: {},
    [courseIDs.COMPUTER_SCIENCE_4]: {},
    [courseIDs.COMPUTER_SCIENCE_5]: {},
    [courseIDs.COMPUTER_SCIENCE_6]: {}
  }

  coursesWithProjects = [
    courseIDs.GAME_DEVELOPMENT_1,
    courseIDs.WEB_DEVELOPMENT_1,
    courseIDs.GAME_DEVELOPMENT_2,
    courseIDs.WEB_DEVELOPMENT_2,
    courseIDs.GAME_DEVELOPMENT_3
  ]

  otherCourseIDs = {
    CHAPTER_ONE: '5d41d731a8d1836b5aa3cba1',
    CHAPTER_TWO: '5d8a57abe8919b28d5113af1',
    CHAPTER_THREE: '5e27600d1c9d440000ac3ee7',
    CHAPTER_FOUR: '5f0cb0b7a2492bba0b3520df'
  }

  CSCourseIDs = [
    courseIDs.JUNIOR,
    courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE,
    courseIDs.COMPUTER_SCIENCE_2,
    courseIDs.COMPUTER_SCIENCE_3,
    courseIDs.COMPUTER_SCIENCE_4,
    courseIDs.COMPUTER_SCIENCE_5,
    courseIDs.COMPUTER_SCIENCE_6
  ]
  WDCourseIDs = [
    courseIDs.WEB_DEVELOPMENT_1,
    courseIDs.WEB_DEVELOPMENT_2
  ]
  orderedCourseIDs = [
    courseIDs.JUNIOR,
    courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE,
    courseIDs.GAME_DEVELOPMENT_1,
    courseIDs.WEB_DEVELOPMENT_1,
    courseIDs.COMPUTER_SCIENCE_2,
    courseIDs.GAME_DEVELOPMENT_2,
    courseIDs.WEB_DEVELOPMENT_2,
    courseIDs.COMPUTER_SCIENCE_3,
    courseIDs.GAME_DEVELOPMENT_3,
    courseIDs.COMPUTER_SCIENCE_4,
    courseIDs.COMPUTER_SCIENCE_5,
    courseIDs.COMPUTER_SCIENCE_6
  ]
  otherOrderedCourseIDs = [
    otherCourseIDs.CHAPTER_ONE,
    otherCourseIDs.CHAPTER_TWO,
    otherCourseIDs.CHAPTER_THREE,
    otherCourseIDs.CHAPTER_FOUR
  ]

  courseModules = {}
  courseModuleLevels = {}

  courseModules[courseIDs.JUNIOR] = {
    1: 'A1: Sequences',
    2: 'A2: Arguments',
    3: 'B1: Complex Arguments (Hit)',
    4: 'B2: Complex Arguments (Spin)',
    5: 'C1: Complex Arguments (Zap)',
    6: 'C2: Intro to Loops',
    7: 'D1: Complex Loops',
    8: 'D2: Intro to Conditionals',
    // 9: 'Variables'
  }

  // TODO: move all the level/module data to database
  // structure: [courseId][moduleNumber]: [levelName1, levelName2, ...]
  courseModuleLevels[courseIDs.JUNIOR] = {
    1: [
      'The Gem',
      'Go Go Go',
      'Two Gems',
      'Elbow',
      'Shiny',
      'Gem Square',
      'The X',
      'X Marks the Spot',
      'Gems First',
      'Walk It Off',
    ],
    2: [
      'Go Smart',
      'Steps',
      'Hiker',
      'Long Hall',
      'Step Change',
      'Go Around',
      'Big Gem Square',
      'Turns',
      'Snake Maze',
      'One Block',
    ],
    3: [
      'Knock Knock',
      'Open and Shut',
      'Doors',
      'Open Up',
      'Airlock',
      'No Keys',
      'Bad Guys',
      'Hall Monitor',
      'Clean Up',
      'Just a Scratch',
      'Brave',
      'Wise',
      'Careful',
      'Heart Up',
      'Tough',
      'One at a Time',
      'Choose Your Battles',
    ],
    4: [
      'Spin to Win',
      'Whirlwind',
      'Twister',
      'Vortex',
      'Busy Intersection',
      'Badder Guy',
      'Two Big',
      'Tornado',
      'Cyclone',
      'Hit and Spin',
      'Hurricane',
    ],
    5: [
      'Zap Gap',
      'Easy Pickings',
      'Advantage',
      'Hit Me Up',
      'Zap It',
      'Target Practice',
      'TNT',
      'Kaboom',
      'Back Up',
      'Monster',
      'Lure It',
      'It\'s a Trap',
      'Friends',
      'Careful Aim',
      'Chain Reaction',
      'Zap Master',
    ],
    6: [
      'Loopy',
      'More Times',
      'Right Up',
      'Square Wave',
      'Grabber',
      'Smasher',
      'Spin Eternally',
      'Down the Line',
      'Tall Wave',
      'Clearing the Way',
      'Restraint',
      'Fern',
      'Scratch Loop',
      'Regular Path',
      'Detonations',
      'Showdown',
    ],
    7: [
      'Gem Weave',
    ],
    8: [
      'Zap Smart',
    ],
  }

  courseModules[courseIDs.COMPUTER_SCIENCE_2] = {
    1: 'Coordinate Systems',
    2: 'Conditionals Part 1',
    3: 'Conditionals Part 2',
    4: 'Conditionals Part 3',
    5: 'Functions Part 1',
    6: 'Functions Part 2',
    7: 'Events'
  }

  courseModuleLevels[courseIDs.COMPUTER_SCIENCE_2] = {
    1: [
      'Defense of Plainswood',
      'Course: Winding Trail',
      'One Wrong Step',
      'Forest Evasion',
      'Gem Berries',
    ],
    2: [
      'Woodland Cubbies',
      'Backwoods Ambush',
      'Patrol Buster',
      'Patrol Buster A',
      'Picnic Buster',
      'Eagle Eye',
      'If-stravaganza',
      'Village Guard',
      'Thornbush Farm',
      'Cleanup',
      'Middle Point',
    ],
    3: [
      'Back to Back',
      'Ogre Encampment',
      'Sacred Glade',
      'Woodland Cleaver',
      'Elseweyr',
      'Backwoods Standoff',
      'Backwoods Standoff A',
      'Backwoods Standoff B',
      'Range Finder',
      'Peasant Protection',
      'Munchkin Swarm',
      'Brave Ogres',
    ],
    4: [
      'Maniac Munchkins',
      'Free Billy',
      'Forest Fire Dancing',
      'Stillness in Motion',
      'The Agrippa Defense',
      'The Agrippa Defense A',
      'The Agrippa Defense B',
      'Dangerous Tree',
      'Last Guardian',
    ],
    5: [
      'Village Rover',
      'Village Warder',
      'Village Champion',
      'A Fine Mint',
      'Silent Village',
    ],
    6: [
      'Backwoods Fork',
      'Tomb Raider',
      'Tomb Ghost',
      'Seek-and-Hide',
      'Forest Miners',
      'Leave it to Cleaver',
      'Timberland Trap',
      'Return to Thornbush Farm',
      'Return to Thornbush Farm A',
      'Return to Thornbush Farm B',
      'Agrippa Refactored',
      'Closed Crossroad',
      'Greed Traps',
      'Last Cannon',
      'Functional Patrol',
    ],
    7: [
      'Backwoods Buddy',
      'Buddy\'s Name A',
      'Buddy\'s Name B',
      'Buddy\'s Name',
      'Phd Kitty',
      'Pet Quiz',
      'Timely Word',
      'Go Fetch',
      'Guard Dog',
      'Long Road',
      'Tough Bait',
      'Forest Jogging',
      'Forest Cannon Dancing',
      'Sharp Bait',
      'Eventful Skirmish',
      'Power Peak',
    ]
  }

  courseModules[courseIDs.GAME_DEVELOPMENT_2] = {
    1: 'Events',
    2: 'Random Numbers',
    3: 'Manual Goals',
    4: 'Input'
  }

  courseModuleLevels[courseIDs.GAME_DEVELOPMENT_2] = {
    1: [
      'Guard Duty',
      'Army Training 2',
      'Standard Operating Procedure',
      'Center Formation',
      'Chokepoint',
      'Adventure Time',
      'Teatime',
      'Random Riposte',
      'Agony of Defeat',
    ],
    2: [
      'Lernaean Hydra',
      'Stick Shift',
      'Don\'t Touch Them',
      'From Dust to Dust',
      'Cages',
    ],
    3: [
      'Accounts Department',
      'Hot Gems',
      'Berserker',
      'Freeze Tag',
    ],
    4: [
      'Run for Gold',
      'Disintegration Arrow',
      'Game of Coins Step 1: Layout',
      'Game of Coins Step 2: Score',
      'Game of Coins Step 3: Enemies',
      'Game of Coins Step 4: Power-Ups',
      'Game of Coins Step 5: Balance',
      'Game Dev 2 Final Project',
    ]
  }

  courseModules[courseIDs.WEB_DEVELOPMENT_2] = {
    1: 'JavaScript',
    2: 'jQuery',
    3: 'CSS',
    4: 'Input'
  }

  courseModuleLevels[courseIDs.WEB_DEVELOPMENT_2] = {
    1: [
      'True Names',
      'Fire Dancing',
      'Lost in the Stacks',
      'Master of Names',
      'Patrol Buster',
      'Back to Back',
      'Maniac Munchkins',
      'Stillness in Motion',
      'A Fine Mint',
      'Return to Thornbush Farm',
    ],
    2: [
      'Query Confirmed',
      'Clickthrough',
      'Disappearing Act',
      'Toggulation',
      'Eventful Selectors',
      'Sibling Rivalry',
    ],
    3: [
      'Border Patrol',
      'Marginal Utility',
      'Transformative Properties',
      'Animania',
      'Precision Coloring',
      'Quizlet',
    ]
  }

  courseModules[courseIDs.COMPUTER_SCIENCE_3] = {
    1: 'Expressions',
    2: 'Properties',
    3: 'Return',
    4: 'Comparisons',
    5: 'Movement',
    6: 'Properties Revisted',
    7: 'Break and Continue'
  }

  courseModuleLevels[courseIDs.COMPUTER_SCIENCE_3] = {
    1: [
      'Friend and Foe',
      'Deja Brew',
      'Reward and Ruination',
      'Air Rescue Service',
      'The Wizard\'s Door',
      'The Wizard\'s Haunt',
      'The Wizard\'s Plane',
      'True Alchemy',
    ],
    2: [
      'Coincrumbs',
      'White Rabbit',
      'Chameleons',
      'Rich and Safe',
      'Wind Correction',
      'Backwoods Bombardier',
      'Thumb Biter',
      'Endangered Burl',
      'Taunting',
      'Wrong Type',
    ],
    3: [
      'Burlbole Grove',
      'Blind Distance',
      'Hit and Freeze',
      'Coin Hunter',
      'Agrippa Returned',
      'Metal Detector',
      'Ogre Invaders',
      'Forest Storm',
    ],
    4: [
      'Passing Through',
      'Useful Competitors',
      'Wonderglade',
      'Cursed Wonderglade',
      'Wild Alliance',
      'Gems or Death',
      'Burls Beets Booleans',
      'Salted Earth',
      'Star Shower',
      'Forest Shadow',
      'Warders',
      'Spring Thunder',
      'Teleport Lasso',
      'Brawler Hunt',
      'Helpful Hunting',
      'Usual Day',
      'Logical Path',
      'Logical Circle',
      'Logical Conclusion',
      'Nonandor',
    ],
    5: [
      'The Mighty Sand Yak',
      'Oasis',
      'Sarven Road',
      'Dried Irrigation',
      'Sarven Gaps',
      'Crossroads',
      'Interception',
      'Thunderhooves',
      'Friendly Minefield',
      'Kithgard Enchanter',
    ],
    6: [
      'Minesweeper',
      'Operation \'Killdeer\'',
      'Medical Attention',
      'Valley of the King',
      'Valley of a Thousand Rocks',
      'Keeping Time',
      'Crux of the Desert',
    ],
    7: [
      'Hoarding Gold',
      'Decoy Drill',
      'Greed Protection',
      'Continuous Alchemy',
      'Master Of Camouflage',
      'Escape to the Spring',
      'Fast and Furry-ous',
      'Sand Mushrooms',
      'Mushroom Noise',
      'Key Traps',
      'Chain of Command',
      'Pet Engineer',
      'Pet Translator',
      'Pet Adjutant',
      'Alchemic Power',
      'Pet Explorer',
      'Dangerous Key',
      'Olympic Race',
      'Cross Bones',
    ]
  }

  courseModules[courseIDs.GAME_DEVELOPMENT_3] = {
    1: 'Frames',
    2: 'Position',
    3: 'Movement',
    4: 'Bring It Together'
  }

  courseModuleLevels[courseIDs.GAME_DEVELOPMENT_3] = {
    1: [
      'The Rule of the Square',
      'The Big Guy',
    ],
    2: [
      'Quantum Jump',
      'Looping Forest',
    ],
    3: [
      'Smooth Run',
      'Looney Gems',
    ],
    4: [
      'Runner Step 1: Environment',
      'Runner Step 2: Scoring',
      'Runner Step 3: Enemies',
      'Runner Step 4: Balance',
      'Game Dev 3 Final Project',
    ]
  }

  courseModules[courseIDs.COMPUTER_SCIENCE_4] = {
    1: 'While Loops Revisited',
    2: 'Lists Part 1',
    3: 'Lists Part 2',
    4: 'Movement Revisited',
    5: 'For Loops'
  }

  courseModuleLevels[courseIDs.COMPUTER_SCIENCE_4] = {
    1: [
      'Dust',
      'Double Check',
      'Canyon of Storms',
      'No Pain No Gain',
      'Desert Combat',
      'Bait and Switch',
      'Mirage Maker',
      'Spinach Power',
    ],
    2: [
      'Team Work',
      'Coordinated Defense',
      'Recruiting Queue',
      'Second Gem',
    ],
    3: [
      'Sarven Savior',
      'Bank Raid',
      'Wandering Souls',
      'Lurkers',
      'Preferential Treatment',
      'Sarven Shepherd',
      'Shine Getter',
      'Marauder',
      'Sand Snakes',
      'Odd Sandstorm',
      'Mad Maxer',
    ],
    4: [
      'Brittle Morale',
      'Mad Maxer Strikes Back',
      'Wishing Well',
      'Crag Tag',
      'Slalom',
      'Ogre Gorge Gouger',
      'Cloudrip Commander',
      'Mountain Mercenaries',
    ],
    5: [
      'Timber Guard',
      'Zoo Keeper',
      'Noble Sacrifice',
      'Hunting Party',
      'Borrowed Sword',
      'Summation Summit',
    ]
  }

  courseModules[courseIDs.COMPUTER_SCIENCE_5] = {
    1: 'Functions Revisited',
    2: 'Modulo',
    3: 'Strings',
    4: 'For Loops Revisited',
    5: 'Matrices'
  }

  courseModuleLevels[courseIDs.COMPUTER_SCIENCE_5] = {
    1: [
      'Vital Powers',
      'The Two Flowers',
      'Hunters and Prey',
      'Reaping Fire',
      'Toil and Trouble',
      'Mixed Unit Tactics',
    ],
    2: [
      'Ring Bearer',
      'Library Tactician',
      'The Geometry of Flowers',
    ],
    3: [
      'The Spy Among Us',
      'In My Name',
      'Highlanders',
    ],
    4: [
      'Perimeter Defense',
      'Dangerous Tracks',
      'Resource Valleys',
      'Flawless Pairs',
      'Twins Power',
      'Think Ahead',
      'Grid Search',
      'Grid Minefield',
      'To Arms!',
    ],
    5: [
      'Power Points',
      'Danger Valley',
      'Sleepwalkers',
      'Cannon Landing Force',
      'Snowdrops',
      'Reindeer Wakeup',
      'Reindeer Spotter',
      'Reindeer Tender',
      'Ritual of Rectangling',
      'Square Shield',
      'Area of Yetis',
      'Bits and Trits',
    ]
  }

  courseModules[courseIDs.COMPUTER_SCIENCE_6] = {
    1: 'Common Algorithms',
    2: 'Vectors',
    3: 'More Algorithms',
    4: 'Data Structures',
    5: 'Advanced Algorithms'
  }

  courseModuleLevels[courseIDs.COMPUTER_SCIENCE_6] = {
    1: [
      'Misty Island Mine',
      'Grim Determination',
      'Yeti Eater',
      'Antipodes',
      'The Hunt Begins',
      'Yak Heist',
      'Slumbering Sample',
    ],
    2: [
      'Circle Walking',
      'Skating Away',
      'Brewball',
      'Precision Kicking',
      'Ice Soccer',
      'Serpent Savings',
      'Snowflakes on the Ice',
    ],
    3: [
      'Ice Life',
      'Coded Orders',
      'Guess My Number',
      'Form Up!',
    ],
    4: [
      'First Out',
      'Double Queue',
      'Queue Manager',
      'Key Stack',
      'Stack Triage',
      'Alchemic Stack',
      'Linked Keys',
      'Count Links',
      'Gem by Gem',
      'Wireless',
      'Hashed Yaks',
      'Hashing Magic',
    ],
    5: [
      'Match Cord',
      'Golden Choice',
      'Kelvintaph Pillars',
      'Fragile Maze',
      'Treasured in Ice',
      'Broken Circles',
      'Bombing Run',
      'Ace of Coders',
    ]
  }

  hourOfCodeOptions = {
    campaignId: freeCampaignIds[1],
    courseId: courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE,
    name: 'Introduction to Computer Science',
    progressModalAfter: 1500000 // 25 mins
  }
} else {
  campaignIDs =
    { CHAPTER_ONE: '5d1a8368abd38e8b5363bad9' }

  freeCampaignIds = [campaignIDs.CHAPTER_ONE] // CH1 campaign
  internalCampaignIds = ['5eb34fc8dc0fd35e8eae66b0'] // CH2 playtest

  courseIDs = {
    CHAPTER_ONE: '5d41d731a8d1836b5aa3cba1',
    CHAPTER_TWO: '5d8a57abe8919b28d5113af1',
    CHAPTER_THREE: '5e27600d1c9d440000ac3ee7',
    CHAPTER_FOUR: '5f0cb0b7a2492bba0b3520df'
  }

  otherCourseIDs = {
    JUNIOR: '65f32b6c87c07dbeb5ba1936',
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
  }

  CSCourseIDs = [
    courseIDs.CHAPTER_ONE,
    courseIDs.CHAPTER_TWO,
    courseIDs.CHAPTER_THREE,
    courseIDs.CHAPTER_FOUR
  ]
  WDCourseIDs = []
  orderedCourseIDs = [
    courseIDs.CHAPTER_ONE,
    courseIDs.CHAPTER_TWO,
    courseIDs.CHAPTER_THREE,
    courseIDs.CHAPTER_FOUR
  ]
  otherOrderedCourseIDs = [
    otherCourseIDs.JUNIOR,
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
  ]

  // Harcoding module names for simplicity
  // Use db to store these later when we add sophisticated module functionality, right now its only used for UI
  courseModules = {}
  courseModuleLevels = {}
  courseModules[courseIDs.CHAPTER_ONE] = {
    1: 'Introduction to Coding'
  }
  courseModules[courseIDs.CHAPTER_TWO] = {
    1: 'Algorithms and Syntax',
    2: 'Debugging',
    3: 'Variables',
    4: 'Conditionals',
    5: 'Capstone Intro',
    6: 'Capstone Project'
  }
  courseModules[courseIDs.CHAPTER_THREE] = {
    1: 'Review',
    2: 'For Loops',
    3: 'Nesting',
    4: 'While Loops',
    5: 'Capstone'
  }
  courseModules[courseIDs.CHAPTER_FOUR] = {
    1: 'Compound Conditionals',
    2: 'Functions and Data Analysis',
    3: 'Writing Functions',
    4: 'Capstone'
  }

  hourOfCodeOptions = {
    campaignId: freeCampaignIds[0],
    courseId: courseIDs.CHAPTER_ONE,
    name: 'Chapter 1: Up The Mountain',
    progressModalAfter: 1500000 // 25 mins
  }
}

const allCourseIDs = _.assign(courseIDs, otherCourseIDs)

const freeCocoCourseIDs = [allCourseIDs.JUNIOR, allCourseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE]
const allFreeCourseIDs = [...freeCocoCourseIDs, allCourseIDs.CHAPTER_ONE]

const courseNumericalStatus = {};
(function () {
  courseNumericalStatus.NO_ACCESS = 0
  let index = 1
  for (const key of [...Array.from(orderedCourseIDs), ...Array.from(otherOrderedCourseIDs)]) {
    courseNumericalStatus[key] = index
    index *= 2
  }
  return courseNumericalStatus.FULL_ACCESS = index - 1
})()

const courseAcronyms = {}
courseAcronyms[allCourseIDs.JUNIOR] = 'JR'
courseAcronyms[allCourseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE] = 'CS1'
courseAcronyms[allCourseIDs.GAME_DEVELOPMENT_1] = 'GD1'
courseAcronyms[allCourseIDs.WEB_DEVELOPMENT_1] = 'WD1'
courseAcronyms[allCourseIDs.COMPUTER_SCIENCE_2] = 'CS2'
courseAcronyms[allCourseIDs.GAME_DEVELOPMENT_2] = 'GD2'
courseAcronyms[allCourseIDs.WEB_DEVELOPMENT_2] = 'WD2'
courseAcronyms[allCourseIDs.COMPUTER_SCIENCE_3] = 'CS3'
courseAcronyms[allCourseIDs.GAME_DEVELOPMENT_3] = 'GD3'
courseAcronyms[allCourseIDs.COMPUTER_SCIENCE_4] = 'CS4'
courseAcronyms[allCourseIDs.COMPUTER_SCIENCE_5] = 'CS5'
courseAcronyms[allCourseIDs.COMPUTER_SCIENCE_6] = 'CS6'
courseAcronyms[allCourseIDs.CHAPTER_ONE] = 'CH1'
courseAcronyms[allCourseIDs.CHAPTER_TWO] = 'CH2'
courseAcronyms[allCourseIDs.CHAPTER_THREE] = 'CH3'
courseAcronyms[allCourseIDs.CHAPTER_FOUR] = 'CH4'
courseAcronyms[allCourseIDs.HACKSTACK] = 'HS'

const registerHocProgressModalCheck = function () {
  let hocProgressModalCheck
  return hocProgressModalCheck = setInterval(() => {
    if ((window.sessionStorage != null ? window.sessionStorage.getItem('hoc_progress_modal_time') : undefined) < new Date().getTime()) {
      window.sessionStorage.setItem('show_hoc_progress_modal', true)
      window.sessionStorage.removeItem('hoc_progress_modal_time')
      return clearInterval(hocProgressModalCheck)
    }
  }
                                             , 60000) // every 1 min
}

const petThangIDs = [
  '578d320d15e2501f00a585bd', // Wolf Pup
  '5744e3683af6bf590cd27371', // Cougar
  '5786a472a6c64135009238d3', // Raven
  '577d5d4dab818b210046b3bf', // Pugicorn
  '58c74b7c3d4a3d2900d43b7e', // Brown Rat
  '58c7614a62cc3a1f00442240', // Yetibab
  '58a262520b43652f00dad75e', // Phoenix
  '57869cf7bd31c14400834028', // Frog
  '578691f9bd31c1440083251d', // Polar Bear Cub
  '58a2712b0b43652f00dae5a4', // Blue Fox
  '58c737140ca7852e005deb8a', // Mimic
  '57586f0a22179b2800efda37' // Baby Griffin
]

const premiumContent = {
  premiumHeroesCount: '15',
  totalHeroesCount: '19',
  premiumLevelsCount: '531',
  freeLevelsCount: '5'
}

// Ozaria-specific
// adds displayName and learning goals from intro levels content to the intro level given
const addIntroLevelContent = function (introLevel, introLevelsContent) {
  if ((introLevel.get('type') === 'intro') && ((introLevel.get('introContent') || []).length > 0) && introLevelsContent) {
    return introLevel.get('introContent').forEach(c => {
      let introLevelData
      if (c.type === 'avatarSelectionScreen') { return }
      if (typeof c.contentId === 'object') { // contentId can be an object if interactive is different for python/js
        // for simplicity, assuming that the display name/learning goals will be same for a given interactive in python/js
        introLevelData = introLevelsContent[c.contentId.python] || {}
      } else {
        introLevelData = introLevelsContent[c.contentId] || {}
      }
      c.displayName = i18n(introLevelData, 'displayName') || i18n(introLevelData, 'name')
      const learningGoals = ((introLevelData.documentation || {}).specificArticles || []).find(a => a.name === 'Learning Goals')
      if (learningGoals) {
        return c.learningGoals = i18n(learningGoals, 'body')
      }
    })
  }
}

const normalizeFunc = function (func_thing, object) {
  // func could be a string to a function in this class
  // or a function in its own right
  if (object == null) { object = {} }
  if (_.isString(func_thing)) {
    const func = object[func_thing]
    if (!func) {
      console.error(`Could not find method ${func_thing} in object`, object)
      return () => null // always return a func, or Mediator will go boom
    }
    func_thing = func
  }
  return func_thing
}

const objectIdToDate = objectID => new Date(parseInt(objectID.toString().slice(0, 8), 16) * 1000)

const hexToHSL = hex => rgbToHsl(hexToR(hex), hexToG(hex), hexToB(hex))

var hexToR = h => parseInt((cutHex(h)).substring(0, 2), 16)
var hexToG = h => parseInt((cutHex(h)).substring(2, 4), 16)
var hexToB = h => parseInt((cutHex(h)).substring(4, 6), 16)
var cutHex = function (h) { if (h.charAt(0) === '#') { return h.substring(1, 7) } else { return h } }

const hslToHex = hsl => '#' + (Array.from(hslToRgb(...Array.from(hsl || []))).map((n) => toHex(n))).join('')

var toHex = function (n) {
  let h = Math.floor(n).toString(16)
  if (h.length === 1) { h = '0' + h }
  return h
}

const pathToUrl = function (path) {
  const base = location.protocol + '//' + location.hostname + (location.port && (':' + location.port))
  return base + path
}

const extractPlayerCodeTag = function (code) {
  const unwrappedDefaultCode = __guard__(code.match(/<playercode>\n([\s\S]*)\n *<\/playercode>/), x1 => x1[1])
  if (unwrappedDefaultCode) {
    return stripIndentation(unwrappedDefaultCode)
  } else {
    return undefined
  }
}

var stripIndentation = function (code) {
  let line
  const codeLines = code.split('\n')
  const indentation = _.min(_.filter(codeLines.map(line => __guard__(__guard__(line.match(/^\s*/), x2 => x2[0]), x1 => x1.length))))
  const strippedCode = ((() => {
    const result = []
    for (line of Array.from(codeLines)) {
      result.push(line.substr(indentation))
    }
    return result
  })()).join('\n')
  return strippedCode
}

// @param {Object} say - the object containing an i18n property.
// @param {string} target - the attribute that you want to access.
// @returns {string} translated string if possible
// Example usage:
//   `courseName = utils.i18n(course.attributes, 'name')`
var i18n = function (say, target, language, fallback) {
  let generalName
  if (language == null) { language = me.get('preferredLanguage', true) }
  if (fallback == null) { fallback = 'en' }
  let generalResult = null
  let fallBackResult = null
  let fallForwardResult = null // If a general language isn't available, the first specific one will do.
  let fallSidewaysResult = null // If a specific language isn't available, its sibling specific language will do.
  const matches = (/\w+/gi).exec(language)
  if (matches) { generalName = matches[0] }

  const removeAI = function (str) {
    // we have some objects as return value.
    // when ai translation finished we can know how to deal with them
    // now return first
    if (!str) {
      return ''
    }
    if (typeof str === 'object') {
      const newObject = {}
      Object.keys(str).forEach((key) => {
        newObject[key] = removeAI(str[key])
      })
      return newObject
    }
    if (typeof str !== 'string') {
      return str
    }
    return str.replace(/^\[AI_TRANSLATION\]/, '')
  }
  // Lets us safely attempt to translate undefined objects
  if (!(say != null ? say.i18n : undefined)) { return removeAI(say != null ? say[target] : undefined) }

  for (const localeName in say.i18n) {
    var result
    const locale = say.i18n[localeName]
    if (localeName === '-') { continue }
    if (target in locale && locale[target]) {
      result = locale[target]
    } else { continue }
    if (localeName === language) { return removeAI(result) }
    if (localeName === generalName) { generalResult = result }
    if (localeName === fallback) { fallBackResult = result }
    if ((localeName.indexOf(language) === 0) && (fallForwardResult == null)) { fallForwardResult = result }
    if ((localeName.indexOf(generalName) === 0) && (fallSidewaysResult == null)) { fallSidewaysResult = result }
  }

  if (generalResult != null) { return removeAI(generalResult) }
  if (fallForwardResult != null) { return removeAI(fallForwardResult) }
  if (fallSidewaysResult != null) { return removeAI(fallSidewaysResult) }
  if (fallBackResult != null) { return removeAI(fallBackResult) }
  if (target in say) { return removeAI(say[target]) }
  return null // if we call i18n for a unexisting key
}

const getByPath = function (target, path) {
  if (!target) { throw new Error('Expected an object to match a query against, instead got null') }
  const pieces = path.split('.')
  let obj = target
  for (const piece of Array.from(pieces)) {
    if (!(piece in obj)) { return undefined }
    obj = obj[piece]
  }
  return obj
}

const isID = id => _.isString(id) && (id.length === 24) && (__guard__(id.match(/[a-f0-9]/gi), x1 => x1.length) === 24)

const isRegionalSubscription = name => /_basic_subscription/.test(name)

const isSmokeTestEmail = email => /@example.com/.test(email) || /smoketest/.test(email)

const round = _.curry((digits, n) => n = +n.toFixed(digits))

const positify = func => params => function (x) { if (x > 0) { return func(params)(x) } else { return 0 } }

// f(x) = ax + b
const createLinearFunc = params => x => ((params.a || 1) * x) + (params.b || 0)

// f(x) = ax² + bx + c
const createQuadraticFunc = params => x => ((params.a || 1) * x * x) + ((params.b || 1) * x) + (params.c || 0)

// f(x) = a log(b (x + c)) + d
const createLogFunc = params => function (x) { if (x > 0) { return ((params.a || 1) * Math.log((params.b || 1) * (x + (params.c || 0)))) + (params.d || 0) } else { return 0 } }

// f(x) = ax^b + c
const createPowFunc = params => x => ((params.a || 1) * Math.pow(x, params.b || 1)) + (params.c || 0)

const functionCreators = {
  linear: positify(createLinearFunc),
  quadratic: positify(createQuadraticFunc),
  logarithmic: positify(createLogFunc),
  pow: positify(createPowFunc)
}

// Call done with true to satisfy the 'until' goal and stop repeating func
const keepDoingUntil = function (func, wait, totalWait) {
  let done
  if (wait == null) { wait = 100 }
  if (totalWait == null) { totalWait = 5000 }
  let waitSoFar = 0
  return (done = function (success) {
    if (((waitSoFar += wait) <= totalWait) && !success) {
      return _.delay(() => func(done), wait)
    }
  })(false)
}

const grayscale = function (imageData) {
  const d = imageData.data
  for (let i = 0, end = d.length; i <= end; i += 4) {
    const r = d[i]
    const g = d[i + 1]
    const b = d[i + 2]
    const v = (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
    d[i] = (d[i + 1] = (d[i + 2] = v))
  }
  return imageData
}

// Deep compares l with r, with the exception that undefined values are considered equal to missing values
// Very practical for comparing Mongoose documents where undefined is not allowed, instead fields get deleted
const kindaEqual = (compare = function (l, r) {
  if (_.isObject(l) && _.isObject(r)) {
    for (const key of Array.from(_.union(Object.keys(l), Object.keys(r)))) {
      if (!compare(l[key], r[key])) { return false }
    }
    return true
  } else if (l === r) {
    return true
  } else {
    return false
  }
})

// Return UTC string "YYYYMMDD" for today + offset
const getUTCDay = function (offset) {
  if (offset == null) { offset = 0 }
  const day = new Date()
  day.setDate(day.getUTCDate() + offset)
  const partYear = day.getUTCFullYear()
  let partMonth = (day.getUTCMonth() + 1)
  if (partMonth < 10) { partMonth = '0' + partMonth }
  let partDay = day.getUTCDate()
  if (partDay < 10) { partDay = '0' + partDay }
  return `${partYear}${partMonth}${partDay}`
}

// Fast, basic way to replace text in an element when you don't need much.
// http://stackoverflow.com/a/4962398/540620
if (typeof document !== 'undefined' && document !== null ? document.createElement : undefined) {
  const dummy = document.createElement('div')
  dummy.innerHTML = 'text'
  const TEXT = dummy.textContent === 'text' ? 'textContent' : 'innerText'
  replaceText = function (elems, text) {
    for (const elem of Array.from(elems)) { elem[TEXT] = text }
    return null
  }
}

// Add a stylesheet rule
// http://stackoverflow.com/questions/524696/how-to-create-a-style-tag-with-javascript/26230472#26230472
// Don't use wantonly, or we'll have to implement a simple mechanism for clearing out old rules.
if (typeof document !== 'undefined' && document !== null ? document.createElement : undefined) {
  injectCSS = (function (doc) {
    // wrapper for all injected styles and temp el to create them
    const wrap = doc.createElement('div')
    const temp = doc.createElement('div')
    // rules like "a {color: red}" etc.
    return function (cssRules) {
      // append wrapper to the body on the first call
      if (!wrap.id) {
        wrap.id = 'injected-css'
        wrap.style.display = 'none'
        doc.body.appendChild(wrap)
      }
      // <br> for IE: http://goo.gl/vLY4x7
      temp.innerHTML = '<br><style>' + cssRules + '</style>'
      wrap.appendChild(temp.children[1])
    }
  })(document)
}

// So that we can stub out userAgent in tests
const userAgent = () => window.navigator.userAgent

const getDocumentSearchString = () => // moved to a separate function so it can be mocked for testing
      document.location.search

const getQueryVariables = function () {
  const query = module.exports.getDocumentSearchString().substring(1) // use module.exports so spy is used in testing
  const pairs = (Array.from(query.split('&')).map((pair) => pair.split('=')))
  const variables = {}
  for (const [key, value] of Array.from(pairs)) {
    var left1
    variables[key] = (left1 = { true: true, false: false }[value]) != null ? left1 : decodeURIComponent(value)
  }
  return variables
}

const getQueryVariable = function (param, defaultValue) {
  const variables = getQueryVariables()
  return variables[param] != null ? variables[param] : defaultValue
}

const getSponsoredSubsAmount = function (price, subCount, personalSub) {
  // 1 100%
  // 2-11 80%
  // 12+ 60%
  // TODO: make this less confusing
  if (price == null) { price = 999 }
  if (subCount == null) { subCount = 0 }
  if (personalSub == null) { personalSub = false }
  if (!(subCount > 0)) { return 0 }
  const offset = personalSub ? 1 : 0
  if (subCount <= (1 - offset)) {
    return price
  } else if (subCount <= (11 - offset)) {
    return Math.round(((1 - offset) * price) + (((subCount - 1) + offset) * price * 0.8))
  } else {
    return Math.round(((1 - offset) * price) + (10 * price * 0.8) + (((subCount - 11) + offset) * price * 0.6))
  }
}

const getCourseBundlePrice = function (coursePrices, seats) {
  let pricePerSeat
  if (seats == null) { seats = 20 }
  const totalPricePerSeat = coursePrices.reduce((a, b) => a + b, 0)
  if (coursePrices.length > 2) {
    pricePerSeat = Math.round(totalPricePerSeat / 2.0)
  } else {
    pricePerSeat = parseInt(totalPricePerSeat)
  }
  return seats * pricePerSeat
}

const getCoursePraise = function () {
  const praise = [
    {
      quote: 'The kids love it.',
      source: 'Leo Joseph Tran, Athlos Leadership Academy'
    },
    {
      quote: 'My students have been using the site for a couple of weeks and they love it.',
      source: 'Scott Hatfield, Computer Applications Teacher, School Technology Coordinator, Eastside Middle School'
    },
    {
      quote: 'Thanks for the captivating site. My eighth graders love it.',
      source: 'Janet Cook, Ansbach Middle/High School'
    },
    {
      quote: 'My students have started working on CodeCombat and love it! I love that they are learning coding and problem solving skills without them even knowing it!!',
      source: 'Kristin Huff, Special Education Teacher, Webb City School District'
    },
    {
      quote: 'I recently introduced Code Combat to a few of my fifth graders and they are loving it!',
      source: 'Shauna Hamman, Fifth Grade Teacher, Four Peaks Elementary School'
    },
    {
      quote: "Overall I think it's a fantastic service. Variables, arrays, loops, all covered in very fun and imaginative ways. Every kid who has tried it is a fan.",
      source: 'Aibinder Andrew, Technology Teacher'
    },
    {
      quote: 'I love what you have created. The kids are so engaged.',
      source: 'Desmond Smith, 4KS Academy'
    },
    {
      quote: 'My students love the website and I hope on having content structured around it in the near future.',
      source: 'Michael Leonard, Science Teacher, Clearwater Central Catholic High School'
    }
  ]
  return praise[_.random(0, praise.length - 1)]
}

const getPrepaidCodeAmount = function (price, users, months) {
  if (price == null) { price = 0 }
  if (users == null) { users = 0 }
  if (months == null) { months = 0 }
  if (!(users > 0) || !(months > 0)) { return 0 }
  const total = price * users * months
  return total
}

const formatDollarValue = dollars => '$' + (parseFloat(dollars).toFixed(2))

const capitalLanguages = {
  javascript: 'JavaScript',
  coffeescript: 'CoffeeScript',
  python: 'Python',
  java: 'Java',
  cpp: 'C++',
  lua: 'Lua',
  html: 'HTML'
}

const createLevelNumberMap = function (levels, courseID) {
  const levelNumberMap = {}
  let practiceLevelTotalCount = 0
  let practiceLevelCurrentCount = 0
  for (let i = 0; i < levels.length; i++) {
    const level = levels[i]
    let levelNumber = (i - practiceLevelTotalCount) + 1
    if (isCodeCombat && level.practice) {
      levelNumber = (i - practiceLevelTotalCount) + String.fromCharCode('a'.charCodeAt(0) + practiceLevelCurrentCount)
      practiceLevelTotalCount++
      practiceLevelCurrentCount++
    } else if (level.assessment) {
      practiceLevelTotalCount++
      practiceLevelCurrentCount++
      if (isCodeCombat) {
        levelNumber = level.assessment === 'cumulative' ? $.t('play_level.combo_challenge') : $.t('play_level.concept_challenge')
      } else {
        levelNumber = $.i18n.t('play_level.challenge')
      }
    } else {
      practiceLevelCurrentCount = 0
    }
    if (level.key) {
      levelNumberMap[level.key] = levelNumber
    } else {
      levelNumberMap[level.key] = ''
    }

    if (courseID) {
      levelNumberMap[courseID + ':' + level.key] = levelNumberMap[level.key]
    }
  }
  return levelNumberMap
}

const isOptional = level => level != null ? level.optional : undefined
const isLocked = level => (level != null ? level.locked : undefined) && !isOptional(level)
const isCompleteOrAssessmentOrSkipped = level => (level != null ? level.complete : undefined) || (level != null ? level.assessment : undefined) || isOptional(level)
const isPractice = level => level != null ? level.practice : undefined

const skipNonPracticeLevels = function (levels, index) {
  while ((index >= 0) && !isPractice(levels[index])) {
    index--
  }
  return index
}

const skipPracticeLevels = function (levels, index) {
  while ((index >= 0) && isPractice(levels[index])) {
    index--
  }
  return index
}

const findFirstIncompleteLevelOfPreviousPracticeChain = function (levels, currentIndex) {
  let index = skipNonPracticeLevels(levels, currentIndex - 1)

  if (index >= 0) {
    index = skipPracticeLevels(levels, index)

    if (index >= 0) {
      index++

      // Skip completed practice levels
      while ((index < levels.length) && isPractice(levels[index]) && levels[index].complete) { index++ }

      if (isLocked(levels[index])) { return -1 }
      if (isPractice(levels[index]) && !levels[index].complete) { return index }
    }
  }

  return -1
}

const isAnyPrecedingLevelLocked = function (levels, currentIndex) {
  for (let i = 0, end = currentIndex, asc = end >= 0; asc ? i <= end : i >= end; asc ? i++ : i--) {
    if (isLocked(levels[i])) { return true }
  }
  return false
}

const findNextLevel = function (levels, currentIndex, needsPractice) {
  let index = currentIndex + 1

  if (isAnyPrecedingLevelLocked(levels, currentIndex)) { return -1 }

  if (needsPractice) {
    if (isPractice(levels[currentIndex]) || ((index < levels.length) && isPractice(levels[index]))) {
      while ((index < levels.length) && (isCompleteOrAssessmentOrSkipped(levels[index]) || isLocked(levels[index]))) {
        if (isLocked(levels[index])) { return -1 }
        index++
      }
    } else {
      index = findFirstIncompleteLevelOfPreviousPracticeChain(levels, currentIndex)

      if (index === -1) {
        index = currentIndex + 1
        while ((index < levels.length) && (isCompleteOrAssessmentOrSkipped(levels[index]) || isLocked(levels[index]))) {
          if (isLocked(levels[index])) { return -1 }
          index++
        }
      }
    }
  } else {
    while ((index < levels.length) && (isPractice(levels[index]) || isCompleteOrAssessmentOrSkipped(levels[index]) || isLocked(levels[index]))) {
      if (isLocked(levels[index])) { return -1 }
      index++
    }
  }

  return index
}

const findNextAssessmentForLevel = function (levels, currentIndex, needsPractice) {
  // Find assessment level immediately after current level (and its practice levels)
  // Only return assessment if it's the next level
  // Skip over practice levels unless practice neeeded
  // levels = [{practice: true/false, complete: true/false, assessment: true/false, locked: true/false}]
  // eg: l*,p,p,a*,a',l,...
  // given index l*, return index a*
  // given index a*, return index a'
  let index = currentIndex
  index++
  while (index < levels.length) {
    if (levels[index].practice) {
      if (needsPractice && !levels[index].complete) { return -1 }
      index++ // It's a practice level but do not need practice, keep looking
    } else if (levels[index].assessment) {
      if (levels[index].complete) { return -1 }
      return index
    } else if (levels[index].complete) { // It's completed, keep looking
      index++
    } else { // we got to a normal level; we didn't find an assessment for the given level.
      return -1
    }
  }
  return -1 // we got to the end of the list and found nothing
}

const needsPractice = function (playtime, threshold) {
  if (playtime == null) { playtime = 0 }
  if (threshold == null) { threshold = 5 }
  return (playtime / 60) > threshold
}

const sortCourses = courses => _.sortBy(courses, function (course) {
  // ._id can be from classroom.courses, otherwise it's probably .id
  let index = orderedCourseIDs.indexOf(course.id != null ? course.id : course._id)
  if (index === -1) { index = 9001 }
  return index
})

const sortOtherCourses = courses => _.sortBy(courses, function (course) {
  let index = otherOrderedCourseIDs.indexOf(course.id != null ? course.id : course._id)
  if (index === -1) { index = 9001 }
  return index
})

const sortCoursesByAcronyms = function (courses) {
  const orderedCourseAcronyms = _.sortBy(courseAcronyms)
  return _.sortBy(courses, function (course) {
    // ._id can be from classroom.courses, otherwise it's probably .id
    let index = orderedCourseAcronyms.indexOf(courseAcronyms[course.id != null ? course.id : course._id])
    if (index === -1) { index = 9001 }
    return index
  })
}

const tournamentSortFn = function (ta, tb) {
  const stateOrder = {
    starting: 0,
    ended: 1,
    initializing: 2,
    disabled: 4
  }
  return (stateOrder[ta.state] - stateOrder[tb.state]) || (new Date(ta.endDate) - new Date(tb.endDate))
}

const usStateCodes =
      // https://github.com/mdzhang/us-state-codes
      // generated by js2coffee 2.2.0
      (function () {
        const stateNamesByCode = {
          AL: 'Alabama',
          AK: 'Alaska',
          AZ: 'Arizona',
          AR: 'Arkansas',
          CA: 'California',
          CO: 'Colorado',
          CT: 'Connecticut',
          DE: 'Delaware',
          DC: 'District of Columbia',
          FL: 'Florida',
          GA: 'Georgia',
          HI: 'Hawaii',
          ID: 'Idaho',
          IL: 'Illinois',
            IN: 'Indiana',
          IA: 'Iowa',
          KS: 'Kansas',
          KY: 'Kentucky',
          LA: 'Louisiana',
          ME: 'Maine',
          MD: 'Maryland',
          MA: 'Massachusetts',
          MI: 'Michigan',
          MN: 'Minnesota',
          MS: 'Mississippi',
          MO: 'Missouri',
          MT: 'Montana',
          NE: 'Nebraska',
          NV: 'Nevada',
          NH: 'New Hampshire',
          NJ: 'New Jersey',
          NM: 'New Mexico',
          NY: 'New York',
          NC: 'North Carolina',
          ND: 'North Dakota',
          OH: 'Ohio',
          OK: 'Oklahoma',
          OR: 'Oregon',
          PA: 'Pennsylvania',
          RI: 'Rhode Island',
          SC: 'South Carolina',
          SD: 'South Dakota',
          TN: 'Tennessee',
          TX: 'Texas',
          UT: 'Utah',
          VT: 'Vermont',
          VA: 'Virginia',
          WA: 'Washington',
          WV: 'West Virginia',
          WI: 'Wisconsin',
          WY: 'Wyoming'
        }
        const stateCodesByName = _.invert(stateNamesByCode)
        // normalizes case and removes invalid characters
        // returns null if can't find sanitized code in the state map

        const sanitizeStateCode = function (code) {
          code = _.isString(code) ? code.trim().toUpperCase().replace(/[^A-Z]/g, '') : null
          if (stateNamesByCode[code]) { return code } else { return null }
        }

        // returns a valid state name else null

        const getStateNameByStateCode = code => stateNamesByCode[sanitizeStateCode(code)] || null

        // normalizes case and removes invalid characters
        // returns null if can't find sanitized name in the state map

        const sanitizeStateName = function (name) {
          if (!_.isString(name)) {
            return null
          }
          // bad whitespace remains bad whitespace e.g. "O  hi o" is not valid
          name = name.trim().toLowerCase().replace(/[^a-z\s]/g, '').replace(/\s+/g, ' ')
          let tokens = name.split(/\s+/)
          tokens = _.map(tokens, token => token.charAt(0).toUpperCase() + token.slice(1))
          // account for District of Columbia
          if (tokens.length > 2) {
            tokens[1] = tokens[1].toLowerCase()
          }
          name = tokens.join(' ')
          if (stateCodesByName[name]) { return name } else { return null }
        }

        // returns a valid state code else null

        const getStateCodeByStateName = name => stateCodesByName[sanitizeStateName(name)] || null

        return {
          sanitizeStateCode,
          getStateNameByStateCode,
          sanitizeStateName,
          getStateCodeByStateName,
          codes: Object.keys(stateNamesByCode)
        }
      })()

const emailRegex = /[A-z0-9._%+-]+@[A-z0-9.-]+\.[A-z]{2,63}/
const isValidEmail = email => emailRegex.test(email != null ? email.trim().toLowerCase() : undefined)

const formatStudentLicenseStatusDate = function (status, date) {
  const string = (() => {
    switch (status) {
    case 'not-enrolled': return $.i18n.t('teacher.status_not_enrolled')
    case 'enrolled': if (date) { return $.i18n.t('teacher.status_enrolled') } else { return '-' }
    case 'expired': return $.i18n.t('teacher.status_expired')
    }
  })()
  return string.replace('{{date}}', date || 'Never')
}

const formatStudentSingleLicenseStatusDate = function (product) {
  let string = $.i18n.t('teacher.full_license')
  if ((product.productOptions != null ? product.productOptions.includedCourseIDs : undefined) != null) {
    string = product.productOptions.includedCourseIDs.map(id => courseAcronyms[id]).join('+')
  }
  return string += ': ' + moment(product.endDate).format('ll')
}

const getApiClientIdFromEmail = function (email) {
  if (/@codeninjas.com$/i.test(email)) { // hard coded for code ninjas since a lot of their users do not have clientCreator set
    const clientID = '57fff652b0783842003fed00'
    return clientID
  }
}

// hard-coded 3 CS1 levels with concept video details
// TODO: move them to database if more such levels
const videoLevels = {
  // gems in the deep
  '54173c90844506ae0195a0b4': {
    i18name: 'basic_syntax',
    url: 'https://iframe.videodelivery.net/d9a73d2f2d3d8de2e5e86203af47e20c?defaultTextTrack=en',
    cn_url: 'https://assets.koudashijie.com/videos/%E5%AF%BC%E8%AF%BE01-%E5%9F%BA%E6%9C%AC%E8%AF%AD%E6%B3%95-Codecombat%20Instruction%20for%20Teachers.mp4',
    title: 'Basic Syntax',
    original: '54173c90844506ae0195a0b4',
    thumbnail_locked: '/images/level/videos/basic_syntax_locked.png',
    thumbnail_unlocked: '/images/level/videos/basic_syntax_unlocked.png',
    captions_available: ['en', 'es-419', 'es']
  },
  // fire dancing
  '55ca293b9bc1892c835b0136': {
    i18name: 'while_loops',
    url: 'https://iframe.videodelivery.net/1cec5da9a56cd42ade2906cd03c0b82b?defaultTextTrack=en',
    cn_url: 'https://assets.koudashijie.com/videos/%E5%AF%BC%E8%AF%BE03-CodeCombat%E6%95%99%E5%AD%A6%E5%AF%BC%E8%AF%BE-CS1-%E5%BE%AA%E7%8E%AFlogo.mp4',
    title: 'While Loops',
    original: '55ca293b9bc1892c835b0136',
    thumbnail_locked: '/images/level/videos/while_loops_locked.png',
    thumbnail_unlocked: '/images/level/videos/while_loops_unlocked.png',
    captions_available: ['en', 'es-419', 'es']
  },
  // known enemy
  '5452adea57e83800009730ee': {
    i18name: 'variables',
    url: 'https://iframe.videodelivery.net/239838623c19b13437705ebe69929031?defaultTextTrack=en',
    cn_url: 'https://assets.koudashijie.com/videos/%E5%AF%BC%E8%AF%BE02-%E5%8F%98%E9%87%8F-CodeCombat-CS1-%E5%8F%98%E9%87%8Flogo.mp4',
    title: 'Variables',
    original: '5452adea57e83800009730ee',
    thumbnail_locked: '/images/level/videos/variables_locked.png',
    thumbnail_unlocked: '/images/level/videos/variables_unlocked.png',
    captions_available: ['en', 'es-419', 'es']
  }
}

// Adds a `Vue.nonreactive` global method that can be used
// to prevent Vue traversing our large and expensive game objects.
// Reference Library: https://github.com/rpkilby/vue-nonreactive
const vueNonReactiveInstall = function (Vue) {
  const Observer = (new Vue())
        .$data
        .__ob__
        .constructor

  return Vue.nonreactive = function (value) {
    // Vue sees the noop Observer and stops traversing the structure.
    value.__ob__ = new Observer({})
    return value
  }
}

const yearsSinceMonth = function (birth, now) {
  if (!birth) { return undefined }
  // Should probably review this logic, written quickly and haven't tested any edge cases
  if (_.isString(birth)) {
    if (!/^\d{4}-\d{1,2}(-\d{1,2})?$/.test(birth)) { return undefined }
    if (birth.split('-').length === 2) {
      birth = birth + '-28' // Assume near the end of the month, don't let timezones mess it up, skew younger in interpretation
    }
    const dates = birth.split('-')
    birth = new Date(+dates[0], +dates[1] - 1, +dates[2])
  }
  if (!_.isDate(birth)) { return undefined }

  let birthYear = birth.getFullYear()
  if (birth.getMonth() > 7) { birthYear += 1 } // getMonth start from 0 # child birth after 9.1 should join school in next year
  const season = currentSeason()
  if (now == null) { now = new Date() }
  let schoolYear = now.getFullYear()

  const seasonAfterSep = +(season.start.split('-')[0]) >= 9
  if (seasonAfterSep) { schoolYear += 1 } // school year comes into a new year after 9.1
  return schoolYear - birthYear
}

// Keep in sync with the copy in background-processor
const ageBrackets = [
  { slug: '0-11', max: 11 },
  { slug: '11-14', max: 14 },
  { slug: '14-18', max: 18 },
  { slug: 'open', max: 9001 }
]

const ageBracketsChina = [
  { slug: '0-11', max: 11 },
  { slug: '11-18', max: 18 },
  { slug: 'open', max: 9001 }
]

const seasonTimes = [
  {
    name: 'Season 1',
    start: '01-01',
    end: '04-30'
  },
  {
    name: 'Season 2',
    start: '05-01',
    end: '08-31'
  },
  {
    name: 'Season 3',
    start: '09-01',
    end: '12-31'
  }
]

var currentSeason = function () {
  const now = new Date()
  const year = now.getFullYear()
  return seasonTimes.find(function (season) {
    const dates = season.end.split('-')
    return now < new Date(year, +dates[0] - 1, dates[1]).setHours(24, 0, 0, 0)
  })
}

const ageToBracket = function (age) {
  // Convert years to an age bracket
  if (!age) { return 'open' }
  for (const bracket of Array.from(ageBrackets)) {
    if (age <= bracket.max) {
      return bracket.slug
    }
  }
  return 'open'
}

const bracketToAge = function (slug) {
  let higherBound, i, lowerBound
  let asc, end
  let asc1, end1
  for (i = 0, end = ageBrackets.length, asc = end >= 0; asc ? i < end : i > end; asc ? i++ : i--) {
    if (ageBrackets[i].slug === slug) {
      lowerBound = i === 0 ? 0 : ageBrackets[i - 1].max
      higherBound = ageBrackets[i].max
      return { $gt: lowerBound, $lte: higherBound }
    }
  }

  for (i = 0, end1 = ageBracketsChina.length, asc1 = end1 >= 0; asc1 ? i < end1 : i > end1; asc1 ? i++ : i--) {
    if (ageBracketsChina[i].slug === slug) {
      lowerBound = i === 0 ? 0 : ageBracketsChina[i - 1].max
      higherBound = ageBracketsChina[i].max
      return { $gt: lowerBound, $lte: higherBound }
    }
  }
}

const CODECOMBAT = 'codecombat'
const CODECOMBAT_CHINA = 'koudashijie'
const OZARIA = 'ozaria'
const OZARIA_CHINA = 'aojiarui'

const isOldBrowser = function () {
  if ($.browser) {
    if (!($.browser.webkit || $.browser.mozilla || $.browser.msedge)) { return true }
    const majorVersion = $.browser.versionNumber
    // css math function supports
    if ($.browser.mozilla && (majorVersion < 75)) { return true }
    if ($.browser.chrome && (majorVersion < 79)) { return true }
    if ($.browser.safari && (majorVersion < 11.1)) { return true }
  }
  return false
}

const isChinaOldBrowser = function () {
  if (features.china && isOldBrowser()) {
    return true
  }
  return false
}

// AI League arenas
const arenas = [
  { season: 1, slug: 'blazing-battle', type: 'regular', start: new Date('2021-01-01T00:00:00.000-08:00'), end: new Date('2021-05-01T00:00:00.000-07:00'), results: new Date('2021-05-01T00:00:00.000-07:00'), levelOriginal: '5fca06dc8b4da8002889dbf1', tournament: '608cea0f8f2b971478556ac6', image: '/file/db/level/5fca06dc8b4da8002889dbf1/Blazing Battle Final cut.jpg' },
  { season: 1, slug: 'infinite-inferno', type: 'championship', start: new Date('2021-04-01T00:00:00.000-07:00'), end: new Date('2021-05-01T00:00:00.000-07:00'), results: new Date('2021-05-01T00:00:00.000-07:00'), levelOriginal: '602cdc204ef0480075fbd954', tournament: '608cd3f814fa0bf9f1c1f928', image: '/file/db/level/602cdc204ef0480075fbd954/InfiniteInferno_Banner_Final.jpg' },
  { season: 2, slug: 'mages-might', type: 'regular', start: new Date('2021-05-01T00:00:00.000-07:00'), end: new Date('2021-09-01T00:00:00.000-07:00'), results: new Date('2021-09-08T07:00:00.000-07:00'), levelOriginal: '6066f956ddfd6f003d1ed6bb', tournament: '612d554b9abe2e0019aeffb9', image: '/file/db/level/6066f956ddfd6f003d1ed6bb/Mages\'%20Might%20Banner.jpg' },
  { season: 2, slug: 'sorcerers', type: 'championship', start: new Date('2021-08-01T00:00:00.000-07:00'), end: new Date('2021-09-01T00:00:00.000-07:00'), results: new Date('2021-09-08T07:00:00.000-07:00'), levelOriginal: '609a6ad2e1eb34001a84e7af', tournament: '612d556f9abe2e0019af000b', image: "/file/db/level/609a6ad2e1eb34001a84e7af/Sorcerer's-Blitz-01.jpg" },
  { season: 3, slug: 'giants-gate', type: 'regular', start: new Date('2021-09-01T00:00:00.000-07:00'), end: new Date('2021-12-15T00:00:00.000-08:00'), results: new Date('2021-12-21T07:00:00.000-08:00'), levelOriginal: '60e69b24bed8ae001ac6ce3e', tournament: '6136a86e0c0ecaf34e431e81', image: '/file/db/level/60e69b24bed8ae001ac6ce3e/Giant’s-Gate-Final.jpg' },
  { season: 3, slug: 'colossus', type: 'championship', start: new Date('2021-11-19T00:00:00.000-08:00'), end: new Date('2021-12-15T00:00:00.000-08:00'), results: new Date('2021-12-21T07:00:00.000-08:00'), levelOriginal: '615ffaf2b20b4900280e0070', tournament: '61983f74fd75db5e28ac127a', image: '/file/db/level/615ffaf2b20b4900280e0070/Colossus-Clash-02.jpg' },
  { season: 4, slug: 'iron-and-ice', type: 'regular', start: new Date('2022-01-01T00:00:00.000-08:00'), end: new Date('2022-05-01T00:00:00.000-07:00'), results: new Date('2022-05-10T07:00:00.000-07:00'), levelOriginal: '618a5a13994545008d2d4990', tournament: '623a648580501d0025d8f4ef', image: '/file/db/level/618a5a13994545008d2d4990/Iron-and-Ice-Arena-Banner-02.jpg' },
  { season: 4, slug: 'tundra-tower', type: 'championship', start: new Date('2022-03-11T00:00:00.000-07:00'), end: new Date('2022-05-01T00:00:00.000-07:00'), results: new Date('2022-05-10T07:00:00.000-07:00'), levelOriginal: '620cb80a9bc0f1005e9189d7', tournament: '623a652b53903c1c6c1c6045', image: '/file/db/level/620cb80a9bc0f1005e9189d7/Tundra-Tower-Cup-Arena-Banner-1000px.jpeg' },
  { season: 5, slug: 'desert-duel', type: 'regular', start: new Date('2022-05-01T00:00:00.000-07:00'), end: new Date('2022-09-01T00:00:00.000-07:00'), results: new Date('2022-09-13T07:00:00.000-07:00'), levelOriginal: '62540bd270cb4400504ad44c', tournament: '626c6017deb6dd43a1937b81', image: '/file/db/level/62540bd270cb4400504ad44c/Basketball-Arena-Banner-01.jpg' },
  { season: 5, slug: 'sandstorm', type: 'championship', start: new Date('2022-08-01T00:00:00.000-07:00'), end: new Date('2022-09-01T00:00:00.000-07:00'), results: new Date('2022-09-13T07:00:00.000-07:00'), levelOriginal: '62d50c5cd722b00025eddac7', tournament: '62e6ff22a6960064d67d87c3', image: '/file/db/level/62d50c5cd722b00025eddac7/Basketball-Arena-Sandstorm-Banner-02.jpg' },
  { season: 6, slug: 'magma-mountain', type: 'regular', start: new Date('2022-09-01T00:00:00.000-07:00'), end: new Date('2023-01-01T00:00:00.000-08:00'), results: new Date('2023-01-11T07:00:00.000-08:00'), levelOriginal: '62f9f6506428860025b15a8b', tournament: '638557acf7cd36e695a1aad0', image: '/file/db/level/62f9f6506428860025b15a8b/Codecombat-Magma-Mountain-Banner-02b%20(1).jpg' },
  { season: 6, slug: 'lava-lake', type: 'championship', start: new Date('2022-12-01T00:00:00.000-08:00'), end: new Date('2023-01-01T00:00:00.000-08:00'), results: new Date('2023-01-11T07:00:00.000-08:00'), levelOriginal: '635bceb16dc3150020acb1f8', tournament: '63855798f7cd36e695a1aac5', image: '/file/db/level/635bceb16dc3150020acb1f8/Lava-Lake-Arena-Banner-02.jpg' },
  { season: 7, slug: 'frozen-fortress', type: 'regular', start: new Date('2023-01-01T00:00:00.000-08:00'), end: new Date('2023-05-01T00:00:00.000-07:00'), results: new Date('2023-05-10T07:00:00.000-07:00'), levelOriginal: '639c9a5fad4eb7001f66c801', tournament: '64260960f1c07d0018299145', image: '/file/db/level/639c9a5fad4eb7001f66c801/AILeague-Banner-Frozen-Fortress-01.jpg' },
  { season: 7, slug: 'equinox', type: 'championship', start: new Date('2023-04-01T00:00:00.000-07:00'), end: new Date('2023-05-01T00:00:00.000-07:00'), results: new Date('2023-05-10T07:00:00.000-07:00'), levelOriginal: '6406d8b2da5aca06eb3560d7', tournament: '642609bf54cb921c6d8cf3df', image: '/file/db/level/6406d8b2da5aca06eb3560d7/AILeague-Banner-Equinox-Cup-01.jpg' },
  { season: 8, slug: 'farmers-feud', type: 'regular', start: new Date('2023-05-01T00:00:00.000-07:00'), end: new Date('2023-09-01T00:00:00.000-07:00'), results: new Date('2023-09-14T07:00:00.000-07:00'), levelOriginal: '6436ae25bb80330019b127c6', tournament: '64c836a5d95277dfd69f9ae3', image: '/file/db/level/6436ae25bb80330019b127c6/AILeague-Banner-Farmer\'s-Feud-02.jpg' },
  { season: 8, slug: 'farmscape', type: 'championship', start: new Date('2023-07-01T00:00:00.000-07:00'), end: new Date('2023-09-01T00:00:00.000-07:00'), results: new Date('2023-09-14T07:00:00.000-07:00'), levelOriginal: '649ab0387be08b00fdf31e8a', tournament: '64c836c5d95277dfd69f9af1', image: '/file/db/level/649ab0387be08b00fdf31e8a/AILeague-Banner-Farmer\'s-Feud-03.jpg' },
  { season: 9, slug: 'storm-siege', type: 'regular', start: new Date('2023-09-01T00:00:00.000-07:00'), end: new Date('2024-01-01T00:00:00.000-08:00'), results: new Date('2024-01-10T07:00:00.000-08:00'), levelOriginal: '64c792d1562b9a008d3e2e1a', tournament: '658cfc449ac7fb700b08d815', image: '/file/db/level/64c792d1562b9a008d3e2e1a/StormSiegeBannerv3.png' },
  { season: 9, slug: 'snowhold', type: 'championship', start: new Date('2023-12-01T00:00:00.000-08:00'), end: new Date('2024-01-01T00:00:00.000-08:00'), results: new Date('2024-01-10T07:00:00.000-08:00'), levelOriginal: '654a306ba0c557007a807ead', tournament: '658cfc869ac7fb700b08d82c', image: '/file/db/level/654a306ba0c557007a807ead/SnowholdClashBannerv2.png' },
  { season: 10, slug: 'fierce-forces', type: 'regular', start: new Date('2024-01-01T00:00:00.000-08:00'), end: new Date('2024-05-01T00:00:00.000-07:00'), results: new Date('2024-05-13T07:00:00.000-07:00'), levelOriginal: '6576ff2b1457f600193d2cc9', tournament: '6631155d27d051fef8412658', image: '/file/db/level/6576ff2b1457f600193d2cc9/FierceForcesBannerNew.png' },
  { season: 10, slug: 'anti-gravity', type: 'championship', start: new Date('2024-04-01T00:00:00.000-07:00'), end: new Date('2024-05-01T00:00:00.000-07:00'), results: new Date('2024-05-13T07:00:00.000-07:00'), levelOriginal: '65f2618f757a82bcc90b7c9e', tournament: '66311610236b3e1e9dcfd9f3', image: '/file/db/level/65f2618f757a82bcc90b7c9e/AntiGravityBanner.png' },
  { season: 11, slug: 'solar-skirmish', type: 'regular', start: new Date('2024-05-01T00:00:00.000-07:00'), end: new Date('2024-09-01T00:00:00.000-07:00'), results: new Date('2024-09-14T07:00:00.000-07:00'), levelOriginal: '661f6cf6525db0fb41870360', tournament: '66311a29856d99556fa14326', image: '/file/db/level/661f6cf6525db0fb41870360/SolarSkirmishBanner.png' },
  { season: 11, slug: 'sunfire', type: 'championship', start: new Date('2024-08-01T00:00:00.000-07:00'), end: new Date('2024-09-01T00:00:00.000-07:00'), results: new Date('2024-09-14T07:00:00.000-07:00'), levelOriginal: '6682089bb98780c672659043', tournament: '669aa78fcca07ea127d445d6', image: '/file/db/level/6682089bb98780c672659043/SunfireBanner.png' },
  { season: 12, slug: 'system-shock', type: 'regular', start: new Date('2024-09-01T00:00:00.000-07:00'), end: new Date('2025-01-01T00:00:00.000-08:00'), results: new Date('2025-01-10T07:00:00.000-08:00'), levelOriginal: '', image: '' },
  { season: 12, slug: 'supercharged', type: 'championship', start: new Date('2024-12-01T00:00:00.000-08:00'), end: new Date('2025-01-01T00:00:00.000-08:00'), results: new Date('2025-01-10T07:00:00.000-08:00'), levelOriginal: '', image: '' },
]

// AI League seasons
const AILeagueSeasons = [
  { number: 1, championshipType: 'cup', image: '/images/pages/league/logo_cup.png', video: '1422969c8f5fbee2a62ee60021becfb4', videoThumbnailTime: '1584s' },
  { number: 2, championshipType: 'blitz', image: '/images/pages/league/logo_blitz.png', video: '8a347a9c0da34f487ae4fdaa8234000a', videoThumbnailTime: '837s' },
  { number: 3, championshipType: 'clash', image: '/images/pages/league/logo_clash.png', video: '26bee42b433e19f789271ae400529025', videoThumbnailTime: '1732s' },
  { number: 4, championshipType: 'cup', image: '/images/pages/league/tundra-tower-cup.png', video: 'bfbf1a5187888d110ee47f97b7491c2a', videoThumbnailTime: '1568s' },
  { number: 5, championshipType: 'blitz', image: '/images/pages/league/sand-storm-blitz.png', video: '4d73a54ff2cdc9b0084a538beb476437', videoThumbnailTime: '1638s' },
  { number: 6, championshipType: 'clash', image: '/images/pages/league/lava-lake-clash.png', video: '6650f5c84f65ecd1709cca1210c4e9ab', videoThumbnailTime: '1762s' },
  { number: 7, championshipType: 'cup', image: '/images/pages/league/equinox-cup.png', video: '4832912db10162e24cb2eb86df6c36d7', videoThumbnailTime: '1021s' },
  { number: 8, championshipType: 'blitz', image: '/images/pages/league/farmscape-blitz.png', video: 'eae72056cd1e54f77ec35612c2d0c4b5', videoThumbnailTime: '2681s' },
  { number: 9, championshipType: 'clash', image: '/images/pages/league/snowhold-clash.png', video: '5ee0896f86d690840104adaaa7ec96b6', videoThumbnailTime: '1730s' },
  { number: 10, championshipType: 'cup', image: '/images/pages/league/anti-gravity-cup.png', video: '72d0ffc93599cf8cb5b0f7fed7861d0f', videoThumbnailTime: '188s' },
  { number: 11, championshipType: 'blitz', image: '/images/pages/league/sunfire-blitz.png', video: '', videoThumbnailTime: '' },
  { number: 12, championshipType: 'clash', image: '/images/pages/league/supercharged-clash.png', video: '', videoThumbnailTime: '' },
]

const activeArenas = function () {
  const daysActiveAfterEnd = { regular: 7, championship: 14 }
  return (() => {
    const result = []
    for (const a of Array.from(arenas)) {
      var middle
      if ((a.start <= (middle = new Date()) && middle < a.end.getTime() + (daysActiveAfterEnd[a.type] * 86400 * 1000)) && a.levelOriginal) {
        result.push(_.clone(a))
      }
    }
    return result
  })()
}

const activeAndPastArenas = () => (() => {
  const result = []
  for (const a of Array.from(arenas)) {
    if (a.start <= new Date()) {
      result.push(_.clone(a))
    }
  }
  return result
})()

const teamSpells = { humans: ['hero-placeholder/plan'], ogres: ['hero-placeholder-1/plan'] }

const clanHeroes = [
  { clanId: '601351bb4b79b4013e198fbe', clanSlug: 'team-derbezt', thangTypeOriginal: '6037ed81ad0ac000f5e9f0b5', thangTypeSlug: 'armando-hoyos' },
  { clanId: '6137aab4e0bae40025bed266', clanSlug: 'team-ned', thangTypeOriginal: '6136fe7e9f1147002c1316b4', thangTypeSlug: 'ned-fulmer' }
]

const freeAccessLevels = [
  { access: 'short', slug: 'dungeons-of-kithgard' },
  { access: 'short', slug: 'gems-in-the-deep' },
  { access: 'short', slug: 'shadow-guard' },
  { access: 'short', slug: 'signs-and-portents' }, // Retroactively unlocks later on, doesn't really impact much
  { access: 'short', slug: 'enemy-mine' },
  { access: 'short', slug: 'true-names' },
  { access: 'medium', slug: 'cell-commentary' },
  { access: 'medium', slug: 'the-raised-sword' },
  { access: 'medium', slug: 'kithgard-librarian' },
  { access: 'medium', slug: 'the-prisoner' },
  { access: 'medium', slug: 'fire-dancing' },
  { access: 'medium', slug: 'haunted-kithmaze' },
  { access: 'medium', slug: 'descending-further' },
  { access: 'medium', slug: 'dread-door' },
  { access: 'long', slug: 'hack-and-dash' },
  { access: 'long', slug: 'cupboards-of-kithgard' },
  { access: 'long', slug: 'known-enemy' },
  { access: 'long', slug: 'master-of-names' },
  { access: 'long', slug: 'the-final-kithmaze' },
  { access: 'long', slug: 'kithgard-gates' },
  { access: 'extended', slug: 'defense-of-plainswood' },
  { access: 'extended', slug: 'winding-trail' },
  { access: 'china-classroom', slug: 'forgetful-gemsmith' },
  { access: 'china-classroom', slug: 'kounter-kithwise' },
  { access: 'china-classroom', slug: 'crawlways-of-kithgard' },
  { access: 'china-classroom', slug: 'illusory-interruption' },
  { access: 'china-classroom', slug: 'careful-steps' },
  { access: 'china-classroom', slug: 'long-steps' },
  { access: 'china-classroom', slug: 'favorable-odds' },
  // Yuqiang: we can directly add ozaria slugs here since all logics are based on slug and won't mess at all
  { access: 'short', slug: '1fhcutscene1b' },
  { access: 'short', slug: '1fhm1l1l1b' },
  { access: 'short', slug: '1fhm1l1l2b' },
  { access: 'short', slug: '1fhm1l1l3b' },
  { access: 'short', slug: '1fhm1l1l4b' },
  { access: 'short', slug: '1fhm1l1l5b' },
  { access: 'short', slug: '1fhm1l1l6b' },
  { access: 'short', slug: '1fhm1l1l7b' },
  { access: 'short', slug: '1fhm1l1l8b' },
  // Test set of free CoCo Jr levels
  { access: 'short', slug: 'the-gem' },
  { access: 'short', slug: 'go-go-go' },
  { access: 'short', slug: 'two-gems' },
  { access: 'short', slug: 'elbow' },
  { access: 'short', slug: 'shiny' },
  { access: 'short', slug: 'gem-square' },
  { access: 'short', slug: 'the-x' },
  { access: 'short', slug: 'x-marks-the-spot' },
  { access: 'short', slug: 'gems-first' },
  { access: 'short', slug: 'walk-it-off' },
  { access: 'short', slug: 'go-smart' },
  { access: 'short', slug: 'steps' },
  { access: 'short', slug: 'hiker' },
  { access: 'short', slug: 'long-hall' },
  { access: 'short', slug: 'step-change' },
  { access: 'short', slug: 'go-around' },
  { access: 'short', slug: 'big-gem-square' },
  { access: 'short', slug: 'turns' },
  { access: 'short', slug: 'snake-maze' },
  { access: 'short', slug: 'one-block' },
  { access: 'short', slug: 'knock-knock' },
  { access: 'short', slug: 'open-and-shut' },
  { access: 'short', slug: 'doors' },
  { access: 'short', slug: 'open-up' },
  { access: 'short', slug: 'airlock' },
  { access: 'short', slug: 'no-keys' },
  { access: 'short', slug: 'bad-guys' },
  { access: 'short', slug: 'hall-monitor' },
  { access: 'short', slug: 'clean-up' },
  { access: 'short', slug: 'just-a-scratch' },
  { access: 'short', slug: 'brave' },
  { access: 'short', slug: 'wise' },
  { access: 'short', slug: 'careful' },
  { access: 'short', slug: 'heart-up' },
  { access: 'short', slug: 'tough' },
  { access: 'short', slug: 'one-at-a-time' },
  { access: 'short', slug: 'choose-your-battles' },
  { access: 'short', slug: 'spin-to-win' },
  { access: 'short', slug: 'whirlwind' },
  { access: 'short', slug: 'twister' },
  { access: 'short', slug: 'vortex' },
  { access: 'short', slug: 'busy-intersection' },
  { access: 'short', slug: 'badder-guy' },
  { access: 'short', slug: 'two-big' },
  { access: 'short', slug: 'tornado' },
  { access: 'short', slug: 'cyclone' },
  { access: 'short', slug: 'hit-and-spin' },
  { access: 'short', slug: 'hurricane' },
  { access: 'short', slug: 'zap-gap' },
  { access: 'short', slug: 'easy-pickings' },
  { access: 'short', slug: 'advantage' },
  { access: 'short', slug: 'hit-me-up' },
  { access: 'short', slug: 'zap-it' },
  { access: 'short', slug: 'target-practice' },
  { access: 'short', slug: 'tnt' },
  { access: 'short', slug: 'kaboom' },
  { access: 'short', slug: 'back-up' },
  { access: 'short', slug: 'monster' },
  { access: 'short', slug: 'lure-it' },
  { access: 'short', slug: 'its-a-trap' },
  { access: 'short', slug: 'friends' },
  { access: 'short', slug: 'careful-aim' },
  { access: 'short', slug: 'chain-reaction' },
  { access: 'short', slug: 'zap-master' },
  { access: 'short', slug: 'loopy' },
  { access: 'short', slug: 'more-times' },
  { access: 'short', slug: 'right-up' },
  { access: 'short', slug: 'square-wave' },
  { access: 'short', slug: 'grabber' },
  { access: 'short', slug: 'smasher' },
  { access: 'short', slug: 'spin-eternally' },
  { access: 'short', slug: 'down-the-line' },
  { access: 'short', slug: 'tall-wave' },
  { access: 'short', slug: 'clearing-the-way' },
  { access: 'short', slug: 'restraint' },
  { access: 'short', slug: 'fern' },
  { access: 'short', slug: 'scratch-loop' },
  { access: 'short', slug: 'regular-path' },
  { access: 'short', slug: 'detonations' },
  { access: 'short', slug: 'showdown' },
  { access: 'short', slug: 'gem-weave' },
  { access: 'short', slug: 'zap-smart' },
]

const orgKindString = function (kind, org = null) {
  if ((kind === 'administrative-region') && ((org != null ? org.country : undefined) === 'US') && /^en/.test(me.get('preferredLanguage'))) { return 'State' }
  const key = {
    country: 'outcomes.country',
    'administrative-region': 'teachers_quote.state',
    'school-district': 'teachers_quote.district_label',
    'school-admin': 'outcomes.school_admin',
    'school-network': 'outcomes.school_network',
    'school-subnetwork': 'outcomes.school_subnetwork',
    school: 'teachers_quote.organization_label',
    teacher: 'courses.teacher',
    classroom: 'outcomes.classroom',
    student: 'courses.student'
  }[kind]
  return $.i18n.t(key)
}

const getProduct = function () { if (isOzaria) { return OZARIA } else { return CODECOMBAT } }

const getProductName = () => $.i18n.t('new_home.' + getProduct())

const supportEmail = `support@${getProduct()}.com`

const cocoBaseURL = function () {
  if (isCodeCombat) {
    return ''
  }
  if (!application.isProduction()) {
    return `${document.location.protocol}//codecombat.com`
  }
  // We are on ozaria domain.
  return `${document.location.protocol}//${document.location.host}`.replace(OZARIA, CODECOMBAT).replace(OZARIA_CHINA, CODECOMBAT_CHINA)
}

const ozBaseURL = function () {
  if (isOzaria) {
    return ''
  }
  if (!application.isProduction()) {
    return `${document.location.protocol}//ozaria.com`
  }
  // We are on codecombat domain.
  return `${document.location.protocol}//${document.location.host}`.replace(CODECOMBAT, OZARIA).replace(CODECOMBAT_CHINA, OZARIA_CHINA)
}

const capitalizeFirstLetter = str => (str[0] || '').toUpperCase() + str.slice(1)

// Note: These need to be double-escaped for insertion into regexes
const commentStarts = {
  javascript: '//',
  python: '#',
  coffeescript: '#',
  lua: '--',
  java: '//',
  cpp: '//',
  html: '<!--',
  css: '/\\*'
}

const markdownToPlainText = function (text) {
  // First, replace HTML tags in text with their plain text contents
  let element
  text = text.replace(/<[^>]*>/g, '')
  const plainTextMarkedRenderer = new marked.Renderer()
  for (element of ['code', 'blockquote', 'html', 'heading', 'hr', 'list', 'listitem', 'paragraph', 'table', 'tablerow', 'tablecell', 'strong', 'em', 'codespan', 'br', 'del', 'text']) {
    plainTextMarkedRenderer[element] = text => text
  }
  for (element of ['link', 'image']) {
    plainTextMarkedRenderer[element] = (href, title, text) => text
  }
  const plainText = marked(text, { renderer: plainTextMarkedRenderer })
  return plainText
}

const markedInline = function (text) {
  // Like marked, but inline (no wrapper <p></p>); this is an option in newer marked versions
  return marked(text).replace(/^<p>|<\/p>$/g, '')
}

/*
 * Get the estimated Hz of the primary monitor in the system.
 *
 * @param {Function} callback The function triggered after obtaining the estimated Hz of the monitor.
 * @param {Boolean} runIndefinitely If set to true, the callback will be triggered indefinitely (for live counter).
 */
// https://ourcodeworld.com/articles/read/1390/how-to-determine-the-screen-refresh-rate-in-hz-of-the-monitor-with-javascript-in-the-browser
const getScreenRefreshRate = function (callback, runIndefinitely) {
  let requestId = null
  let callbackTriggered = false
  if (window.requestAnimationFrame == null) { window.requestAnimationFrame = window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame }
  const DOMHighResTimeStampCollection = []

  const triggerAnimation = function (DOMHighResTimeStamp) {
    DOMHighResTimeStampCollection.unshift(DOMHighResTimeStamp)
    if (DOMHighResTimeStampCollection.length > 10) {
      const t0 = DOMHighResTimeStampCollection.pop()
      const fps = Math.floor((1000 * 10) / (DOMHighResTimeStamp - t0))
      if (!callbackTriggered) {
        callback.call(undefined, fps, DOMHighResTimeStampCollection)
      }
      if (runIndefinitely) {
        callbackTriggered = false
      } else {
        callbackTriggered = true
      }
    }
    requestId = window.requestAnimationFrame(triggerAnimation)
  }

  window.requestAnimationFrame(triggerAnimation)
  // Stop after half second if it shouldn't run indefinitely
  if (!runIndefinitely) {
    window.setTimeout(function () {
      window.cancelAnimationFrame(requestId)
      return requestId = null
    }, 500)
  }
}

const getProductUrl = function (product, url) {
  if ((product !== 'COCO') && (product !== 'OZ')) {
    return url
  }
  const hostVal = window.location.origin
  if (product === 'OZ') {
    return `${hostVal}/ozaria${url}`
  }
  return url
}

const allowedLanguages = ({
  [OZARIA]: ['javascript', 'python'],
  [CODECOMBAT]: ['javascript', 'python', 'java', 'cpp']
})[product]

const getModuleNumberForLevelName = function (courseId, levelName) {
  const moduleNumberByLevelName = Object.entries(courseModuleLevels[courseId]).reduce((acc, [k, v]) => {
    v.forEach(l => acc[l] = k)
    return acc
  }, {})
  return moduleNumberByLevelName[levelName] && Number(moduleNumberByLevelName[levelName])
}

module.exports.aiToolToImage = {
  'gpt-4-turbo-preview': '/images/ai/ChatGPT.svg',
  'stable-diffusion-xl': '/images/ai/Stable_Diffusion.png',
  'dall-e-3': '/images/ai/DALL-E.webp',
  'claude-3': '/images/ai/claude.webp'
}

const getUserTimeZone = function (user) {
  const geo = user.get('geo')
  if (geo?.timeZone) {
    return geo.timeZone
  } else {
    return moment.tz.guess()
  }
}

const shouldShowAiBotHelp = function (aceConfig) {
  if (aceConfig.levelChat !== 'none') {
    if (me.isAdmin()) {
      return true
    } else if (me.isHomeUser() && me.getLevelChatExperimentValue() === 'beta') {
      return true
    } else if (!me.isHomeUser()) {
      return true
    }
  }
  return false
}

const isMobile = () => {
  const mobileRELong = /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino|iPhone|iPad|iPod|Android|webos/i

  const mobileREShort = /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i
  const ua = navigator.userAgent || navigator.vendor || window.opera
  return mobileRELong.test(ua) || mobileREShort.test(ua.substr(0, 4))
}

module.exports.getCodeLanguages = () => ({
  python: {
    id: 'python',
    name: `Python (${$.i18n.t('choose_hero.default')})`
  },
  javascript: {
    id: 'javascript',
    name: 'JavaScript'
  },
  coffeescript: {
    id: 'coffeescript',
    name: 'CoffeeScript'
  },
  lua: {
    id: 'lua',
    name: 'Lua'
  },
  cpp: {
    id: 'cpp',
    name: 'C++'
  },
  java: {
    id: 'java',
    name: `Java (${$.i18n.t('choose_hero.experimental')})`
  }
})

module.exports.getCodeFormats = () => ({
  'text-code': {
    id: 'text-code',
    name: `${$.i18n.t('choose_hero.text_code')} (${$.i18n.t('choose_hero.default')})`
  },
  'blocks-and-code': {
    id: 'blocks-and-code',
    name: `${$.i18n.t('choose_hero.blocks_and_code')}`
  },
  'blocks-text': {
    id: 'blocks-text',
    name: `${$.i18n.t('choose_hero.blocks_text')}`
  },
  'blocks-icons': {
    id: 'blocks-icons',
    name: `${$.i18n.t('choose_hero.blocks_icons')}`
  }
})

module.exports = {
  ...module.exports,
  activeAndPastArenas,
  activeArenas,
  addIntroLevelContent,
  addressesIncludeAdministrativeRegion,
  ageBrackets,
  ageBracketsChina,
  ageOfConsent,
  ageToBracket,
  allowedLanguages,
  anonymizingUser,
  arenas,
  bracketToAge,
  campaignIDs,
  capitalizeFirstLetter,
  capitalLanguages,
  clanHeroes,
  clone,
  combineAncestralObject,
  commentStarts,
  countries,
  countryCodeToFlagEmoji,
  countryCodeToName,
  countryNameToCode,
  courseAcronyms,
  courseIDs,
  allCourseIDs,
  allFreeCourseIDs,
  freeCocoCourseIDs,
  courseModules,
  courseModuleInfo,
  courseModuleLevels,
  courseNumericalStatus,
  coursesWithProjects,
  CSCourseIDs,
  WDCourseIDs,
  createLevelNumberMap,
  downTheChain,
  extractPlayerCodeTag,
  freeAccessLevels,
  findNextAssessmentForLevel,
  findNextLevel,
  formatDollarValue,
  formatStudentLicenseStatusDate,
  formatStudentSingleLicenseStatusDate,
  freeCampaignIds,
  functionCreators,
  getApiClientIdFromEmail,
  getByPath,
  getCourseBundlePrice,
  getCoursePraise,
  getDocumentSearchString,
  getModuleNumberForLevelName,
  getPrepaidCodeAmount,
  getProduct,
  getProductName,
  getQueryVariable,
  getQueryVariables,
  getScreenRefreshRate,
  getSponsoredSubsAmount,
  getUTCDay,
  getAnonymizationStatus,
  getCorrectName,
  grayscale,
  getUserTimeZone,
  hexToHSL,
  hourOfCodeOptions,
  hslToHex,
  i18n,
  inEU,
  injectCSS,
  internalCampaignIds,
  isID,
  isRegionalSubscription,
  isSmokeTestEmail,
  isValidEmail,
  keepDoingUntil,
  kindaEqual,
  markdownToPlainText,
  markedInline,
  needsPractice,
  normalizeFunc,
  objectIdToDate,
  orderedCourseIDs,
  orgKindString,
  pathToUrl,
  petThangIDs,
  premiumContent,
  registerHocProgressModalCheck,
  replaceText,
  round,
  AILeagueSeasons,
  sortCourses,
  sortOtherCourses,
  sortCoursesByAcronyms,
  stripIndentation,
  shouldShowAiBotHelp,
  teamSpells,
  titleize,
  usStateCodes,
  userAgent,
  videoLevels,
  vueNonReactiveInstall,
  yearsSinceMonth,
  CODECOMBAT,
  OZARIA,
  CODECOMBAT_CHINA,
  OZARIA_CHINA,
  isOldBrowser,
  isChinaOldBrowser,
  isCodeCombat,
  isOzaria,
  isMobile,
  supportEmail,
  tournamentSortFn,
  cocoBaseURL,
  ozBaseURL,
  useWebsocket,
  getProductUrl,
  shaTag
}

function __guard__ (value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined
}
function __range__ (left, right, inclusive) {
  const range = []
  const ascending = left < right
  const end = !inclusive ? right : ascending ? right + 1 : right - 1
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i)
  }
  return range
}
