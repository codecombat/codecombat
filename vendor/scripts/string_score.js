/*!
 * string_score.js: String Scoring Algorithm 0.1.10 
 *
 * http://joshaven.com/string_score
 * https://github.com/joshaven/string_score
 *
 * Copyright (C) 2009-2011 Joshaven Potter <yourtech@gmail.com>
 * Special thanks to all of the contributors listed here https://github.com/joshaven/string_score
 * MIT license: http://www.opensource.org/licenses/mit-license.php
 *
 * Date: Tue Mar 1 2011
*/

/*
 * Modified by Nick Winter to not create a new method on the String prototype, just doing what Esprima does with UMD.
 */

(function (root, factory) {
    'use strict';

    // Universal Module Definition (UMD) to support AMD, CommonJS/Node.js,
    // Rhino, and plain browser loading.
    if (typeof define === 'function' && define.amd) {
        define(['exports'], factory);
    } else if (typeof exports !== 'undefined') {
        factory(exports);
    } else {
        factory((root.string_score = {}));
    }
}(this, function (exports) {
    'use strict';

    /**
     * Scores a string against another string.
     *  string_score('Hello World', 'he');     //=> 0.5931818181818181
     *  string_score('Hello World', 'Hello');  //=> 0.7318181818181818
     */
    function score(string, abbreviation, fuzziness) {
      // If the string is equal to the abbreviation, perfect match.
      if (string == abbreviation) {return 1;}
      //if it's not a perfect match and is empty return 0
      if(abbreviation == "") {return 0;}
    
      var total_character_score = 0,
          abbreviation_length = abbreviation.length,
          string_length = string.length,
          start_of_string_bonus,
          abbreviation_score,
          fuzzies=1,
          final_score;
      
      // Walk through abbreviation and add up scores.
      for (var i = 0,
             character_score/* = 0*/,
             index_in_string/* = 0*/,
             c/* = ''*/,
             index_c_lowercase/* = 0*/,
             index_c_uppercase/* = 0*/,
             min_index/* = 0*/;
         i < abbreviation_length;
         ++i) {
        
        // Find the first case-insensitive match of a character.
        c = abbreviation.charAt(i);
        
        index_c_lowercase = string.indexOf(c.toLowerCase());
        index_c_uppercase = string.indexOf(c.toUpperCase());
        min_index = Math.min(index_c_lowercase, index_c_uppercase);
        index_in_string = (min_index > -1) ? min_index : Math.max(index_c_lowercase, index_c_uppercase);
        
        if (index_in_string === -1) { 
          if (fuzziness) {
            fuzzies += 1-fuzziness;
            continue;
          } else {
            return 0;
          }
        } else {
          character_score = 0.1;
        }
        
        // Set base score for matching 'c'.
        
        // Same case bonus.
        if (string[index_in_string] === c) { 
          character_score += 0.1; 
        }
        
        // Consecutive letter & start-of-string Bonus
        if (index_in_string === 0) {
          // Increase the score when matching first character of the remainder of the string
          character_score += 0.6;
          if (i === 0) {
            // If match is the first character of the string
            // & the first character of abbreviation, add a
            // start-of-string match bonus.
            start_of_string_bonus = 1; //true;
          }
        }
        else {
      // Acronym Bonus
      // Weighing Logic: Typing the first character of an acronym is as if you
      // preceded it with two perfect character matches.
      if (string.charAt(index_in_string - 1) === ' ') {
        character_score += 0.8; // * Math.min(index_in_string, 5); // Cap bonus at 0.4 * 5
      }
        }
        
        // Left trim the already matched part of the string
        // (forces sequential matching).
        string = string.substring(index_in_string + 1, string_length);
        
        total_character_score += character_score;
      } // end of for loop
      
      // Uncomment to weigh smaller words higher.
      // return total_character_score / string_length;
      
      abbreviation_score = total_character_score / abbreviation_length;
      //percentage_of_matched_string = abbreviation_length / string_length;
      //word_score = abbreviation_score * percentage_of_matched_string;
      
      // Reduce penalty for longer strings.
      //final_score = (word_score + abbreviation_score) / 2;
      final_score = ((abbreviation_score * (abbreviation_length / string_length)) + abbreviation_score) / 2;
      
      final_score /= fuzzies;
      
      if (start_of_string_bonus && (final_score + 0.15 < 1)) {
        final_score += 0.15;
      }
      
      return final_score;
    };

    exports.score = score;

}));
