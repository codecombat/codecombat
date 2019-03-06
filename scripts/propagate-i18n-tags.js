const fs = require('fs');
const path = require('path');
const enTranslations = require('../app/locale/en').translation;

require('./generateRot13Locale');

function escapeRegexp(s) {
    return s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
}

const enSourceFile = fs.readFileSync(
    path.join(__dirname, '../app/locale/en.coffee'),
    { encoding: 'utf8'}
);

const CHANGE_MARKER = '{change}'

const CATEGORY_SPLIT_PATTERN = /^[\s\n]*(?=[^:\n]+:\s*$)/gm; // One or more new lines followed by "key:", followed by newline
const CATEGORY_CAPTURE_PATTERN = /^([^:\n]+):\s*\n/; // Extracts category name from first line of category section
const COMMENTS_PATTERN = /^[\s\n]*([^:\n]+):\s*"[^#\n"]+"\s*#(.*)$/gm; // Find lines with comments, capture key / value / comment
const CHANGE_PATTERN = new RegExp(`\s?\s?(#\s)?${escapeRegexp(CHANGE_MARKER)}`); // Identify translation marked change
const QUOTE_TAG_NAME_PATTERN = /^[a-z0-9_]+$/i // Determines if tag name needs to be quoted


const enSplitByCategory = enSourceFile.split(CATEGORY_SPLIT_PATTERN);

const comments = {};

// Extract comments per translation so we can add back later
for (const section of enSplitByCategory) {
    const categoryMatch = CATEGORY_CAPTURE_PATTERN.exec(section);

    if (categoryMatch) {
        const categoryName = categoryMatch[1];

        comments[categoryName] = comments[categoryName] || {};

        let comment;
        while ((comment = COMMENTS_PATTERN.exec(section)) !== null) {
            comments[categoryName][comment[1]] = comment[2].trim();
        }
    }
}

// Grab all locale files that we need to manage
const IGNORE_FILES = [ 'rot13.coffee', 'en.coffee', 'locale.coffee' ];
const localeFiles = fs
    .readdirSync(
        path.join(__dirname, '../app/locale')
    )
    .filter((fileName) => IGNORE_FILES.indexOf(fileName) === -1);

for (const localeFile of localeFiles) {
    console.log(`Processing ${localeFile}`);

    // Load raw source file
    const localeSource = fs.readFileSync(
        path.join(__dirname, `../app/locale/${localeFile}`),
        { encoding: 'utf8'}
    );

    // Load locale
    const localeContents = require(`../app/locale/${localeFile}`);
    const localeTranslations = localeContents.translation || {};

    // Initialie rewrite of file with first line
    const rewrittenLines = [
        `module.exports = nativeDescription: "${localeContents.nativeDescription}", englishDescription: ` +
            `"${localeContents.englishDescription}", translation:`
    ];

    // For each category within the locale
    for (const enCategoryName of Object.keys(enTranslations)) {
        const enCategory = enTranslations[enCategoryName];
        const catIsPresent = (typeof localeTranslations[enCategoryName] !== 'undefined');
        const localeCategory = localeTranslations[enCategoryName] || {};

        rewrittenLines.push('');

        // Add the category line, commenting it out if it does not exist in the locale file
        const categoryCommentPrefix = (!catIsPresent)  ? '#' : '';
        rewrittenLines.push(`${categoryCommentPrefix}  ${enCategoryName}:`);

        // For each tag within the category
        for (const enTagName of Object.keys(enCategory)) {
            const localeTranslation = localeCategory[enTagName];
            const tagIsPresent = (typeof localeTranslation !== 'undefined');

            // Prepare the comment for the tag if it exists.  Note that this will propagate {change} tag from en locale
            let comment = '';
            if (comments[enCategoryName] && comments[enCategoryName][enTagName]) {
                comment = comments[enCategoryName][enTagName];
            }

            if (localeSource.search(new RegExp(`#\\s+${escapeRegexp(enTagName)}:`)) >= 0) {
                // If the translation is commented out in the locale fine, make sure it is not marked as changed.  A
                // translation is not marked as changed until it is uncommented in a locale file.  Once it is
                // uncommented in a translation file, the translation is considered active and changes should be
                // tracked
                comment = comment.replace(CHANGE_PATTERN, '');
            } else {
                const tagIsMarkedChangeRegex = new RegExp(`^\\s+"?${escapeRegexp(enTagName)}"?:\\s".*"\\s*#\\s*${escapeRegexp(CHANGE_MARKER)}\\s*$`, 'm');

                // If locale file has tag marked as change and comment is not already marked change,
                // add change to comment
                if (localeSource.search(tagIsMarkedChangeRegex) >= 0 &&
                    comment.search(CHANGE_PATTERN) === -1) {

                    comment += ` ${CHANGE_MARKER}`; // TODO make {change} a constant
                }
            }

            comment = comment.trim();
            if (comment.length > 0) {
                comment = `# ${comment}`;
            }

            // If the tag does not exist in the locale file, make sure it is commented otu
            const lineCommentPrefix = (!tagIsPresent) ? '#' : '';
            const finalTagName = (QUOTE_TAG_NAME_PATTERN.test(enTagName)) ? enTagName : `"${enTagName}"`;
            const finalLocaleTranslation = (localeTranslation || enCategory[enTagName]).replace(/"/g, '\\"');

            rewrittenLines.push(`${lineCommentPrefix}    ${finalTagName}: "${finalLocaleTranslation}" ${comment}`.trimRight());
        }
    }

    // Write the new file contents to the locale file
    const newLocaleContents = rewrittenLines.join("\n");
    fs.writeFileSync(
        path.join(__dirname, `../app/locale/${localeFile}`),
        newLocaleContents,
        { encoding: 'utf8' }
    );
}

// Remove change tags from english now that they have been propagated
const rewrittenEnSource = enSourceFile.replace(CHANGE_PATTERN, '');
fs.writeFileSync(
    path.join(__dirname, '../app/locale/en.coffee'),
    '../app/locale/en.coffee',
    rewrittenEnSource,
    { encoding: 'utf8'}
);

console.log('Done!')
