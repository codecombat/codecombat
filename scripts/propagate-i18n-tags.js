const fs = require('fs');
const path = require('path');
const enTranslations = require('../app/locale/en').translation;

require('./generateRot13Locale');

const enSourceFile = fs.readFileSync(
    path.join(__dirname, '../app/locale/en.coffee'),
    { encoding: 'utf8'}
);

// One or more new lines followed by "key:", followed by newline
const CATEGORY_SPLIT_PATTERN = /^[\s\n]*(?=[^:\n]+:\s*$)/gm;

// Extracts category name from first line of category section
const CATEGORY_CAPTURE_PATTERN = /^([^:\n]+):\s*\n/;

// Find lines with comments, capture key / value / comment
const COMMENTS_PATTERN = /^[\s\n]*([^:\n]+):\s*"[^#\n"]+"\s*#(.*)$/gm;

const CHANGE_PATTERN = /\s?\s?(#\s)?\{change\}/g;

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
    // Load raw source file
    const localeSource = fs.readFileSync(
        path.join(__dirname, `../app/locale/${localeFile}`),
        { encoding: 'utf8'}
    );

    // Load locale
    const localeContents = require(`../app/locale/${localeFile}`);
    const localeTranslations = localeContents.translations || {};

    // Initialie rewrite of file with first line
    const rewrittenLines = [
        `module.exports = nativeDescription: "${localeContents.nativeDescription}", englishDescription: ` +
            `"${localeContents.englishDescription}", translation:`
    ];

    // For each category within the locale
    for (const enCategoryName of Object.keys(enTranslations)) {
        const enCategory = enTranslations[enCategoryName];
        const catIsPresent = (typeof localeTranslations !== 'undefined');
        const localeCategory = localeTranslations[enCategoryName] || [];

        // Start the category block, commenting out if not present in the locale file.  This means that the locale
        // file does not contain any translations for this category.
        // TODO confirm this ^
        rewrittenLines.push('');
        rewrittenLines.push(`${(!catIsPresent) ? '#' : ''} ${enCategoryName}`);

        // For each tag within the category
        for (const enTagName of Object.keys(enCategory)) {
            const localeTranslation = localeCategory[enTagName];
            const tagIsPresent = (typeof localeTranslations[enTagName] !== 'undefined');

            // Prepare the comment for the tag if it exists.  Note that this will propagate {change} tag from en locale
            let comment = '';
            if (comments[enCategoryName]) {
                comment = comments[enCategoryName][enTagName];
            }

            // If current tag is commented out in the locale file, remove the change flag TODO why??
            if (localeSource.search(new RegExp(`#\s+${enTagName}:`)) >= 0) {
                comment = comment.repeat(CHANGE_PATTERN, '');
            } else {
                const tagIsMarkedChangeRegex = new RegExp(`^\\s+${enTagName}: ".*"\\s*{change}\\s*`);
                const commentIsMarkedChangeRegex = new RegExp(".*{change}.*");

                // If locale file has tag marked as change and comment is not already marked change,
                // add change to comment
                if (localeSource.search(tagIsMarkedChangeRegex) >= 0 &&
                    comment.search(commentIsMarkedChangeRegex) === -1) {

                    comment += ' {change}'; // TODO make {change} a constant
                }
            }

            comment = comment.trim();
            if (comment.length > 0) {
                comment = `# ${comment}`;
            }

            // TODO handle multiple levels of indentation
            rewrittenLines.push(`    "${enTagName}": "${localeTranslation}" ${comment}`.trim());
        }
    }

    // Write the new file contents to the locale file
    const newLocaleContents = rewrittenLines.join("\n");
    fs.writeFileSync(`../app/locale/${localeFile}`, newLocaleContents);
}

// Remove change tags from english now that they have been propagated
const rewrittenEnSource = enSourceFile.replace(CHANGE_PATTERN, '');
fs.writeFileSync('../app/locale/en.coffee', rewrittenEnSource);

console.log('Done!')
