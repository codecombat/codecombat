/**
 * Based upon:
 * A Dynamic Programming Algorithm for Name Matching
 * Top, P.;   Dowla, F.;   Gansemer, J.;   
 * Sch. of Electr. & Comput. Eng., Purdue Univ., West Lafayette, IN
 *
 * Variation in JavaScript
 * Copyright © 2011, Christopher Stoll
 * @author <a href="http://www.christopherstoll.org/">Christopher Stoll</a>
 *
 * @constructor
 * @param {String} [pNameSource=''] The source name, the name of interest
 * @param {Boolean} [pDebug=false] The instance is in debugging mode
 * @param {String} [pDebugOutputArea=''] Where to put debuging output
 */
function fuzziac(pNameSource, pDebug, pDebugOutputArea){
	var tNameSource = pNameSource || '';
	
	if(tNameSource){
		// convert "last, first" to "first last"
		if(tNameSource.indexOf(',') > 0){
			var tIndex = tNameSource.indexOf(','),
				tFirst = tNameSource.slice(tIndex+1),
				tLast = tNameSource.slice(0, tIndex);
			tNameSource = tFirst + ' ' + tLast;
		}
		
		// all lowercase, no special characters, and no double sapces
		tNameSource = tNameSource.toLowerCase();
		tNameSource = tNameSource.replace(/[.'"]/ig, ' ');
		tNameSource = tNameSource.replace(/\s{2,}/g, ' ');
	}
	
	// TODO: remove when converted for string matching only
	// debug variables
	this.DEBUG = pDebug || false;
	this.DEBUG_AREA = pDebugOutputArea;
	
	// y axis in matrix, the name in question
	this.nameSource = tNameSource;
	this.nameSourceLength = this.nameSource.length + 1;
	this.nameSourceScore = 0;
	this._reset();
}

fuzziac.prototype = {
	/**
	 * Reset class variables
	 * @private
	 */
	_reset: function(pNameTarget){
		var tNameTarget = pNameTarget || '';
		
		// TODO: remove when converted for string matching only
		if(tNameTarget){
			tNameTarget = tNameTarget.toLowerCase();
			tNameTarget = tNameTarget.replace(/[.,'"]/ig, '');
			tNameTarget = tNameTarget.replace(/\s{2,}/g, ' ');
		}
		
		// x axis in matrix, the name to check against
		this.nameTarget = tNameTarget;
		this.nameTargetLength = this.nameTarget.length + 1;
		this.nameTargetScore = 0;
	
		// DV, the dunamic programming matrix
		this.dynamicMatrix = [];
		
		// Max value in the matrix
		this.maxMatrixValue = 0;
		
		// the score for the string
		this.overallScore = 0;
		
		// weighted average of string and tokens
		this.finalScore = 0;
	},
	
	/**
	 * CM, character mismatch lookup,
	 * Abreviated 2D array for hex values
	 *
	 * @static
	 * @field
	 */
	characterMatrix: [
		//bcdefghijklmnopqrstuvwxyz
		'a0004000000000400000000000', // a
		'0a000000000000000000000000', // b
		'00a00000004000002000000000', // c
		'000a0000000000000002000000', // d
		'4000a000000000000000000020', // e
		'00000a00000000020000020000', // f
		'000000a0000000000000000000', // g
		'0000000a040000000000000000', // h
		'00000000a20400000000000020', // i
		'000000042a0000000000000040', // j
		'0040000000a000002000000000', // k
		'00000000400a00000000000000', // l
		'000000000000a4000000000000', // m
		'0000000000004a000000000000', // n
		'40000000000000a00000000000', // o
		'000002000000000a0000000000', // p
		'0020000000200000a000000000', // q
		'00000000000000000a00000000', // r
		'000000000000000000a0000000', // s
		'0002000000000000000a000000', // t
		'00000000000000000000a00000', // u
		'000002000000000000000a4000', // v
		'0000000000000000000004a000', // w
		'00000000000000000000000a00', // x
		'000020002400000000000000a0', // y
		'0000000000000000002000000a', // z
		'00000000000000400000000000', // 0
		'00000000400400000000000000', // 1
		'00000000000000000100000002', // 2
		'00002000000000000000000001', // 3
		'20000002000000000000000000', // 4
		'00000000000000000020000000', // 5
		'01000010000000000000000000', // 6
		'00000000100100000002000000', // 7
		'01000000000000000000000000', // 8
		'00000020000000000000000000'  // 9
	],
	
	/**
	 * Dictionary to speed lookups in the character matrix
	 *
	 * @static
	 * @field
	 */
	charMatrixDictionary: {
		a: 0,
		b: 1,
		c: 2,
		d: 3,
		e: 4,
		f: 5,
		g: 6,
		h: 7,
		i: 8,
		j: 9,
		k: 10,
		l: 11,
		m: 12,
		n: 13,
		o: 14,
		p: 15,
		q: 16,
		r: 17,
		s: 18,
		t: 19,
		u: 20,
		v: 21,
		w: 22,
		x: 23,
		y: 24,
		z: 25,
		0: 26,
		1: 27,
		2: 28,
		3: 29,
		4: 30,
		5: 31,
		6: 32,
		7: 33,
		8: 34,
		9: 35
	},
	
	/**
	 * Return a matching score for two characters
	 *
	 * @private
	 * @param {String} pCharA The first character to test
	 * @param {String} pCharB The second character to test
	 * @returns {Number} Score for the current characters
	 */
	_characterScore: function(pCharA, pCharB){
		var matchScore = 10,
			mismatchScore = 0,
			mismatchPenalty = -4,
			charIndexA = 0,
			charIndexB = 0,
			refValue = 0;
			
		if(pCharA && pCharB){
			if(pCharA == pCharB){
				return matchScore;
			}else{
				charIndexA = this.charMatrixDictionary[pCharA];
				charIndexB = this.charMatrixDictionary[pCharB];
				
				if(charIndexA && charIndexB){
					mismatchScore = this.characterMatrix[charIndexA][charIndexB]
					refValue = parseInt(mismatchScore, 16);

					if(refValue){
						return refValue;
					}else{
						return mismatchPenalty;
					}
				}else{
					return mismatchPenalty;
				}
			}
		}else{
			return mismatchPenalty;
		}
	},
	
	/**
	 * Return a score for string gaps
	 *
	 * @private
	 * @param {String} pCharA The first character to test
	 * @param {String} pCharB The second character to test
	 * @returns {Number} Score for the current characters
	 */
	_gappedScore: function(pCharA, pCharB){
		var gapPenalty = -3,
			mismatchPenalty = -4;
			
		if((pCharA == ' ') || (pCharB == ' ')){
			return gapPenalty;
		}else{
			return mismatchPenalty;
		}
	},
	
	/**
	 * Return a score for transposed strings
	 * TODO: Either actuallly check for transposed characters or eliminate
	 *
	 * @private
	 * @param {String} pCharA The first character to test
	 * @param {String} pCharB The second character to test
	 * @returns {Number} Score for the current characters
	 */
	_transposedScore: function(pCharA, pCharB){
		var transposePenalty = -2;
		return transposePenalty;
	},
	
	/**
	 * Build the dynamic programming matrix for the two current strings 
	 * @private
	 */
	_buildMatrix: function(){
		var tmpArray = [],
			tCharA = '',
			tCharB = '',
			gapScore = 0;
		
		// fill DV, the dynamic programming matrix, with zeros
		for(var ix=0; ix<this.nameTargetLength; ix++){
			tmpArray.push(0);
		}
		for(var iy=0; iy<this.nameSourceLength; iy++){
			this.dynamicMatrix.push(tmpArray.slice(0));
		}
		
		// calculate the actual values for DV
		for(var iy=1; iy<this.nameSourceLength; iy++){
			for(var ix=1; ix<this.nameTargetLength; ix++){
				tCharA = this.nameSource[iy-1];
				tCharB = this.nameTarget[ix-1];
				
				gapScore = this._gappedScore(tCharA, tCharB);
				this.dynamicMatrix[iy][ix] = Math.max(
					this.dynamicMatrix[iy-1][ix-1] + this._characterScore(tCharA, tCharB),
					0,
					this.dynamicMatrix[iy-1][ix] + gapScore,
					this.dynamicMatrix[iy][ix-1] + gapScore
				);
				
				if((this.dynamicMatrix[iy-1][ix] > this.dynamicMatrix[iy-1][ix-1]) && 
					(this.dynamicMatrix[iy][ix-1] > this.dynamicMatrix[iy-1][ix-1])){
					
					this.dynamicMatrix[iy-1][ix-1] = Math.max(
						this.dynamicMatrix[iy-1][ix],
						this.dynamicMatrix[iy][ix-1]
					);
					this.dynamicMatrix[iy][ix] = Math.max(
						this.dynamicMatrix[iy-1][ix-1] + this._transposedScore(tCharA, tCharB),
						this.dynamicMatrix[iy][ix]
					);
				}
			}
		}
	},
	
	/**
	 * Backtrack through the matrix to find the best path
	 * @private
	 */
	_backtrack: function(){
		var tmaxi = 0,
			maxix = 0;
		
		// find the intial local max
		for(var ix=this.nameTargetLength-1; ix>0; ix--){
			if(this.dynamicMatrix[this.nameSourceLength-1][ix] > tmaxi){
				tmaxi = this.dynamicMatrix[this.nameSourceLength-1][ix];
				maxix = ix;
			}
			
			// break out of loop if we have reached zeros after non zeros
			if((tmaxi > 0) && (this.dynamicMatrix[this.nameSourceLength-1][ix+1] == 0)){
				break;
			}
		}
		
		if(tmaxi <= 0){
			return false;
		}
		
		var ix = maxix,
			iy = this.nameSourceLength-1,
			ixLast = 0,
			iyLast = 0,
			diagonal = 0,
			above = 0,
			left = 0;
		
		// TODO: replace with better algo or refactor
		while((iy>0) && (ix>0)){
			// store max value
			if(this.dynamicMatrix[iy][ix] > this.maxMatrixValue){
				this.maxMatrixValue = this.dynamicMatrix[iy][ix];
			}
			
			// DEBUG
			if(this.DEBUG){
				$('#'+this.DEBUG_AC+'-'+(iy+1)+'-'+(ix+1)).css('background-color','#ccc');
			}
			
			// calculate values for possible paths
			diagonal = this.dynamicMatrix[iy-1][ix-1];
			above = this.dynamicMatrix[iy][ix-1];
			left = this.dynamicMatrix[iy-1][ix];
			
			// choose next path
			if((diagonal>=above) && (diagonal>=left)){
				iy--;
				ix--;
			}else if((above>=diagonal) && (above>=left)){
				ix--;
			}else if((left>=diagonal) && (left>=above)){
				iy--;
			}
			
			// end while if we have all zeros
			if((diagonal == 0) && (above == 0) && (left == 0)){
				iy = 0;
				ix = 0;
			}
		}
		
		return true;
	},
	
	/**
	 * Calculate the final match score for this pair of names
	 * @private
	 */
	_finalMatchScore: function(){
		var averageNameLength = (this.nameSourceLength + this.nameTargetLength) / 2
		this.overallScore = (2 * this.maxMatrixValue) / averageNameLength;
		this.finalScore = this.overallScore / 10;
	},
	
	/**
	 * Display debug information
	 * TODO: remove when converted for string matching only
	 *
	 * @private
	 */
	_debug_ShowDVtable: function(){
		var DEBUG_AA = 0,
			DEBUG_AB = '';
			DEBUG_AC = Math.round(Math.random() * 9999);
			
		this.DEBUG_AC = DEBUG_AC;
			
		DEBUG_AB += '<table class="example">';
		for(var iy=0; iy<=(this.nameSourceLength); iy++){
			DEBUG_AB += '<tr>';
			for(var ix=0; ix<=(this.nameTargetLength); ix++){
				if(iy==0){
					if(ix>1){
						DEBUG_AB += '<td id="'+DEBUG_AC+'-'+iy+'-'+ix+'">'+this.nameTarget[ix-2]+'</td>';
					}else{
						DEBUG_AB += '<td id="'+DEBUG_AC+'-'+iy+'-'+ix+'"></td>';
					}
				}else{
					if(ix>0){
						DEBUG_AA = Math.round(this.dynamicMatrix[iy-1][ix-1] * 100) / 100;
						DEBUG_AB += '<td id="'+DEBUG_AC+'-'+iy+'-'+ix+'">'+DEBUG_AA+'</td>';
					}else{
						if(iy>1){
							DEBUG_AB += '<td id="'+DEBUG_AC+'-'+iy+'-'+ix+'">'+this.nameSource[iy-2]+'</td>';
						}else{
							DEBUG_AB += '<td id="'+DEBUG_AC+'-'+iy+'-'+ix+'"></td>';
						}
					}
				}
			}
			DEBUG_AB += '</tr>';
		}
		DEBUG_AB += '</table>';
		$(this.DEBUG_AREA).append(DEBUG_AB);
	},
	
	/**
	 * Public method to perform a search
	 *
	 * @param {String} pNameTarget The target to compare the source with
	 * @returns The match score of the two strings
	 */
	score: function(pNameTarget){
		this._reset(pNameTarget);
		
		this._buildMatrix();
		
		if(this.DEBUG){
			this._debug_ShowDVtable();
		}
		
		this._backtrack();
		this._finalMatchScore();	
		return this.finalScore;
	},

	/**
	 * Find matches from an array of choices
	 *
	 * @param {String[]} pArray The array of strings to check against
	 * @param {Number} [10] pLimit The number of resutls to return 
	 * @returns {string[]} The top matching strings
	 */
	topMatchesFromArray: function(pArray, pLimit){
		var tmpValue = 0,
			tmpValRound = 0,
			worstValue = 0,
			resultLimit = pLimit || 10,
			resultArray = [];
			
		for(var i=0; i<resultLimit; ++i){
			resultArray.push({v:0,n:'-'});
		}
		
		//var dateStart = {},
		//	dateEnd = {},
		
		// Emperical Analysis
		//dateStart = new Date();

		// check against all names in the name list
		for(var i=0; i<pArray.length; i++){
			tmpValue = this.score(allNames[i]);
			//tmpValRound = String(Math.round(tmpValue * 100) / 1000);

			// add selected names to drop-down list
			// does unnecessary work, refactor to improve speed
			if(tmpValue > resultArray[resultLimit-1].v){
				newObj = {v:tmpValue,n:pArray[i]};
				tmpObj = {v:0,n:''};
				for(var j=0; j<resultLimit; ++j){
					if(newObj.v > resultArray[j].v){
						tmpObj.v = resultArray[j].v;
						tmpObj.n = resultArray[j].n;
						resultArray[j].v = newObj.v;
						resultArray[j].n = newObj.n;
						newObj.v = tmpObj.v;
						newObj.n = tmpObj.n;
					}
				}
			}
		}

		for(var i=0; i<resultArray.length; i++){
			tmp = resultArray[i];
			//resultArray[i] = tmp.v + ' ~~ ' + tmp.n;
			resultArray[i] = tmp.n;
		}

		// Emperical Analysis
		//dateEnd = new Date();
		//timeElapsed = dateEnd.getTime() - dateStart.getTime();
		//console.log('topMatchesFromArray:', timeElapsed);

		return resultArray;
	}
};

module.exports = fuzziac;