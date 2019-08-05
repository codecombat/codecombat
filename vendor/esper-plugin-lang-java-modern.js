/*!
 * jaba
 * 
 * Compiled: Wed Jun 05 2019 00:20:24 GMT-0700 (PDT)
 * Target  : web (umd)
 * Profile : modern
 * Version : 0d3b993-dirty
 * 
 * 
 * Private
 * 
 */
(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory(require("esper"));
	else if(typeof define === 'function' && define.amd)
		define(["esper"], factory);
	else if(typeof exports === 'object')
		exports["esper-plugin-lang-java"] = factory(require("esper"));
	else
		root["esper-plugin-lang-java"] = factory(root["esper"]);
})(typeof self !== 'undefined' ? self : this, function(__WEBPACK_EXTERNAL_MODULE__1__) {
return /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, { enumerable: true, get: getter });
/******/ 		}
/******/ 	};
/******/
/******/ 	// define __esModule on exports
/******/ 	__webpack_require__.r = function(exports) {
/******/ 		if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 			Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 		}
/******/ 		Object.defineProperty(exports, '__esModule', { value: true });
/******/ 	};
/******/
/******/ 	// create a fake namespace object
/******/ 	// mode & 1: value is a module id, require it
/******/ 	// mode & 2: merge all properties of value into the ns
/******/ 	// mode & 4: return value when already ns object
/******/ 	// mode & 8|1: behave like require
/******/ 	__webpack_require__.t = function(value, mode) {
/******/ 		if(mode & 1) value = __webpack_require__(value);
/******/ 		if(mode & 8) return value;
/******/ 		if((mode & 4) && typeof value === 'object' && value && value.__esModule) return value;
/******/ 		var ns = Object.create(null);
/******/ 		__webpack_require__.r(ns);
/******/ 		Object.defineProperty(ns, 'default', { enumerable: true, value: value });
/******/ 		if(mode & 2 && typeof value != 'string') for(var key in value) __webpack_require__.d(ns, key, function(key) { return value[key]; }.bind(null, key));
/******/ 		return ns;
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = 0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, exports, __webpack_require__) {

var esper_ref = __webpack_require__(1);
var plugin = __webpack_require__(2);
esper_ref._registerPlugin(plugin);

/***/ }),
/* 1 */
/***/ (function(module, exports) {

module.exports = __WEBPACK_EXTERNAL_MODULE__1__;

/***/ }),
/* 2 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


const jaba = __webpack_require__(3);
const utils = __webpack_require__(6);
const esper = __webpack_require__(1);


function parser(code, options) {
	options = options || {};
	let opts = {locations: true, ranges: true};
	let cast = jaba(code, options);
	//let extra = babylon.parse("Test.main(null);", {plugins: ['estree', 'flow']});
	let extra = esper.plugin('lang-javascript').parser("Test.main(null);");
	cast.body = cast.body.concat(extra.body);
	return cast;
}


let plugin = module.exports = {
	name: 'lang-java',
	parser: parser,
	init: function(esper) {
		//esper.plugin('babylon');
		esper.languages.java = plugin;
	},
	setupEngine: function(esper, engine) {
		utils.javaifyEngine(engine);
	}
};


/***/ }),
/* 3 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var parser = __webpack_require__(4);
//var generate = require('babel-generator').default;
var transform = __webpack_require__(5).transform

function skope(node) {
	let scope = Object.create({});
	let classes = [];
	let methods = [];
	let scopes = [scope];
	function pushScope() {
		scope = Object.create(scope);
		scopes.push(scope)
		return scope;
	}
	function popScope() {
		let ret = scopes.pop();
		scope = scopes[scopes.length-1];
		return ret;
	}

	function process(node, parent) {
		let next = (n) => process(n, node);
		if ( !node.loc ) {
			console.log("Node of type `" + node.node + "` doesn't have loc.");
		}
		switch (node.node) {
			case "CompilationUnit":
				return node.types.map(next);
			case "TypeDeclaration":
				classes.push(node);
				node.scope = pushScope();
				node.bodyDeclarations.filter((d) => d.node == "FieldDeclaration").map(next);
				node.bodyDeclarations.filter((d) => d.node != "ClassField").map(next);
				classes.pop();
				popScope();
				return;
			case "MethodDeclaration":
				scope[node.name.identifier] = {node: node, type: node.type, kind: "ClassFeature", clazz: parent.name}
				node.scope = pushScope();
				methods.push(node);
				for ( let x of node.parameters ) {
					scope[x.name.identifier] = {node: node, type: node.type, kind: "Arg"}
				}
				//TODO: Put arguments into scope
				next(node.body);
				methods.pop();
				popScope();
				return;
			case "FieldDeclaration":
				for ( let frag of node.fragments ) {
					scope[frag.name.identifier] = {node: node, type: node.type, kind: "ClassFeature"}
				}
				return;
			case "MethodInvocation":
				node.scope = scope;
				if ( node.expression ) next(node.expression);
				next(node.name);
				node.arguments.map(next);
				//next(node.)
				return;
			case "Block":
				node.scope = pushScope();
				node.statements.map(next);
				popScope();
				return;
			case "TryStatement":
				//TODO: Deal with catch
				next(node.body);
				return;
			case "SimpleType":
			case "PrimitiveType":
			case "ArrayType":
			case "LineEmpty":
			case "BreakStatement":
			case "ContinueStatement":
			case "EndOfLineComment":
			case "TraditionalComment":
				return;
			case "WhileStatement":
				node.scope = pushScope()
				next(node.expression);
				next(node.body);
				popScope();
				return;
			case "ForStatement":
				//TOOO: Do all parts;
				node.scope = pushScope()
				node.initializers.map(next);
				next(node.expression);
				node.updaters.map(next);
				next(node.body);
				popScope();
				return;	
			case "VariableDeclarationStatement":
			case "VariableDeclarationExpression":
				for ( let frag of node.fragments ) {
					scope[frag.name.identifier] = {node: node, type: node.type, kind: "Local"}
				}
				break;
			case "ReturnStatement":
				node.bindType = methods[methods.length-1].returnType2;
				next(node.expression);
				break;
			case "SuperConstructorInvocation":
				node.refClass = classes[classes.length-1];
				if ( node.expression ) next(node.expression);
				node.arguments.map(next);
				break;
			case "SingleVariableDeclaration":
			case "ArrayAccess":
			case "ClassInstanceCreation":
			case "IfStatement":
			case "InfixExpression":
			case "ParenthesizedExpression":
			case "Assignment":
			case "SimpleName":
			case "NullLiteral":
			case "ExpressionStatement":
			case "QualifiedName":
			case "PrefixExpression":
			case "StringLiteral":
			case "CharacterLiteral":
			case "NumberLiteral":
			case "BooleanLiteral":
			case "ConditionalExpression":
			case "CastExpression":
			case "PostfixExpression":
			case "SuperMethodInvocation":
			case "ArrayCreation":
			case "SwitchStatement":
			case "AssertStatement":
			case "EnhancedForStatement":
			case "MethodReference":

				for ( var k in node ) {
					if ( node[k] && node[k].node ) next(node[k]);
				}
				node.scope = scope;
				break;
			default:
				console.log(node);
				throw new Error("Cant walk " + node.node);
		}
	}

	process(node);
}




function transpile(code) {
	let iast = parser.parse(code);
	skope(iast);
	let r = transform(iast)
	//let src = generate(r).code;
	//console.log(src);

	//r = require('babylon').parse(generate(r).code, {plugins: ['flow', 'classProperties', 'decorators']}).program;

	return r;
}

module.exports = transpile;


/***/ }),
/* 4 */
/***/ (function(module, exports) {

module.exports = {transform:"redacted"};

/***/ }),
/* 5 */
/***/ (function(module, exports) {

module.exports = {transform:"redacted"};

/***/ }),
/* 6 */
/***/ (function(module, exports, __webpack_require__) {

var esper = __webpack_require__(1);
var Value = esper.Value;
let stdlib = __webpack_require__(7);
let debug = () => {}

class JavaPrimitiveValue extends esper.PrimitiveValue {
	constructor(value) {
		super(value);
	}

	derivePrototype(realm) {
		if ( this.boundType == "int" ) return realm.globalScope.get('Integer');
		if ( this.boundType == "double" ) return realm.globalScope.get('Double');
		if ( this.boundType == "string" ) return realm.globalScope.get('JavaString');

		return super.derivePrototype(realm);
	}

	*divide(other) {
		if ( !this.boundType || this.boundType == "string" ) return yield * super.divide(other);
		let v = this.native / (yield * other.toPrimitiveNative());
		if ( this.boundType == "int" ) v = Math.floor(v);
		let n = new JavaPrimitiveValue(v, this.realm);
		n.boundType = this.boundType;
		return n;
	}

	*multiply(other) {
		if ( !this.boundType || this.boundType == "string"  ) return yield * super.multiply(other);
		let n = new JavaPrimitiveValue(this.native * (yield * other.toPrimitiveNative()), this.realm);
		n.boundType = this.boundType;
		return n;
	}

	*add(other) {
		if ( !this.boundType || this.boundType == "string"  ) return yield * super.add(other);
		let n = new JavaPrimitiveValue(this.native + (yield * other.toPrimitiveNative()), this.realm);
		n.boundType = this.boundType;
		return n;
	}

	*subtract(other) {
		if ( !this.boundType || this.boundType == "string"  ) return yield * super.subtract(other);
		let n = new JavaPrimitiveValue(this.native - (yield * other.toPrimitiveNative()), this.realm);
		n.boundType = this.boundType;
		return n;
	}


	*toStringValue() {
		if ( this.native != this.native ) return yield * super.toStringValue(); //NAN 
		if ( this.boundType == "double" ) {
			let s = String(this.native);
			if ( s.indexOf('.') == -1 ) s += '.0';
			return Value.fromNative(s);
		} else if ( this.boundType == "string" ) {
			return this;
		}
		return yield * super.toStringValue();
	}

	*doubleEquals(other) {
		let native = this.native;
		if ( other instanceof JavaPrimitiveValue ) {
			return Value.fromNative(this.native == other.native);
		}
		return yield * super.doubleEquals(other)

	}

	*toPrimitiveValue() {
		return this;
	}

	*toPrimitiveNative() {
		return this.native;
	}

	get debugString() {
		return "[JP:" + super.debugString + "]";
	}

}

class JavaCast extends esper.ObjectValue {
	*call(thiz, args, s) {
		debug("CAST", args[1], "to", args[0].toNative());
		if ( args[0].jsTypeName == "undefined" ) return args[1];
		let t = args[0].toNative();
		if ( t == "var" ) return args[1];
		if ( t == "int" || t == "double" || t == "string" || t == "bool" ) {
			let val = args[1].toNative();
			let out = new JavaPrimitiveValue(val);
			out.boundType = t;
			return out;
		}

		return args[1];
	}
}

function javaifyEngine(ev) {
	let rev = ev.realm.fromNative.bind(ev.realm);
	ev.realm.fromNative = (v,n) => {
		let r = new JavaPrimitiveValue(v);
		r.realm = ev.realm;
		let type = typeof(v);
		if ( typeof(n) == 'string' ) type = n;

		if ( typeof(n) == 'object' ) {
			if ( typeof(n.value) == "number" || n.type == "NumericLiteral" ) {
				let raw = n.raw;
				if ( raw && raw.indexOf(".") == -1 ) r.boundType = "int";
				else r.boundType = "double";
			} else if ( typeof(n.value) == "string" ) { 
				r.boundType = "string";
			}
			return r;
		}
		
		if ( type == "int" ) {
			r.boundType = "int";
			return r;
		}

		if ( type == "double" ) {
			r.boundType = "double";
			return r;
		}

		if ( type == "string" ) {
			r.boundType = "string";
			return r;
		}

		if ( type == "number" ) {
			r.boundType = "double";
			return r;
		}
		//console.log("Failed binding native", v, new Error().stack)
		
		return rev(v);
	}
	ev.addGlobal('cashew', {
		___JavaRuntime: false
	});
	ev.addGlobal('ArrayList', class ArrayList {
		constructor() {
			this.elements = [];
		}
		add(o) { this.elements.push(o); }
		remove(i) { return this.elements.splice(i, 1)[0]; }
		get(i) { return this.elements[i]; }
		set(i, v) { let old = this.elements[i]; this.elements[i] = v; return old; }
		size() { return this.elements.length; }
	});
	ev.addGlobal('JavaCast', new JavaCast(ev.realm));
	for ( let k in stdlib.f ) {
		let ptype = new stdlib.f[k](ev.realm);
		ev.realm.globalScope.add(k, ptype);
	}
	for ( let k in stdlib.o ) {
		let ptype = new stdlib.o[k](ev.realm);
		let obj = new esper.ObjectValue(ev.realm);
		obj.call = function*(thiz) { return thiz; }
		obj.setImmediate("prototype", ptype);
		ev.realm.globalScope.add(k, obj);
	}
}

module.exports = {
	JavaPrimitiveValue,
	JavaCast,
	javaifyEngine
}

/***/ }),
/* 7 */
/***/ (function(module, exports, __webpack_require__) {

var esper = __webpack_require__(1);
let EasyObjectValue = esper.EasyObjectValue;
let Value = esper.Value;
let debug = () => {};

class JavaObject extends EasyObjectValue {
	static *equals(thiz, args) {
		return thiz.serial == args[0].serial;
	}
	static *toString$(thiz, argz, s) { 
		let nam = thiz.getPrototype().getImmediate("constructor").getImmediate("name");
		return s.fromNative(nam.toNative() + "#" + nam.serial);
	}
}

class JavaString extends EasyObjectValue {
	static *equals(o) {
		return this.serial == o.serial;
	}
	static *length$(thiz, argz, s) { 
		return s.fromNative(thiz.native.length, 'int'); 
	}
	static *indexOf(thiz, argz, s) {
		let i = argz[0].toNative();
		return s.fromNative(thiz.native.indexOf(i), 'int'); 
	}
	static *substring(thiz, argz, s) { 
		return thiz.native.substring(
			argz[0].toNative(),
			argz.length < 2 ? esper.Value.undefined :argz[1].toNative()
		); 
	}
	static *compareTo(thiz, argz, s) {
		let a = thiz.toNative();
		let b = argz[0].toNative();
		if ( a == b ) return s.fromNative(0);
		return a > b ? s.fromNative(1) : s.fromNative(-1);
	}
	static *compareToIgnoreCase(thiz, argz, s) {
		let a = thiz.toNative().toLowerCase();
		let b = argz[0].toNative().toLowerCase();
		if ( a == b ) return s.fromNative(0);
		return a > b ? s.fromNative(1) : s.fromNative(-1);
	}
	static *toString$(thiz, argz, s) { return s.fromNative(thiz.native); }

}

class Integer extends EasyObjectValue {
	static *intValue$(thiz, args, s) { 
		return s.fromNative(Math.floor(thiz.native)); 
	}
	static *toString$(thiz, args, s) { 
		return s.fromNative(thiz.native);
	}
	*call(thiz, args, s) {
		return Value.fromNative(7);
	}
}

class Double extends EasyObjectValue {
	static *intValue$(thiz, args, s) {  
		return s.fromNative(Math.floor(thiz.native)); 
	}
	static *toString$(thiz, args, s) { 
		return yield * thiz.toStringValue(); 
	}
}

function getTypeKey(w) {
	if ( !w ) return 'V'
}

class JavaMethodDispatch extends EasyObjectValue {
	constructor(name, realm) {
		super(realm);
		this.name = name;
		this.realm = realm;
	}

	*call(thiz, args, s, n) {
		let target = undefined
		let w = '$V$';
		for ( let a of args ) {
			debug("ARG", a.boundType);
			switch ( a.boundType ) {
				case 'double': w += 'D'; break;
				case 'int': w += 'I'; break;
				case 'string': w += 'S'; break;
				default: w += 'V';
			}
		}

		function reduceBuiltins(s) {
			s = s.replace("LInteger_", "I");
			s = s.replace("LDouble_", "D");
			return s;
		}

		let canidates = [];
		for ( let m in thiz.properties ) {
			let parts = m.match(/^([^$]+)\$(.)\$(.*)/);
			if ( !parts ) continue;
			if ( parts[1] != this.name ) continue;
			let target = yield * thiz.get(m, s);
			if ( m == this.name + w) {
				canidates = [[target, m, 100]];
				break;
			}
			let score = 80;
			let wtest = '$' + parts[2] + '$' + parts[3];
			console.log("W",w,wtest);
			if ( wtest.length != w.length ) score -= 40;

			let a = reduceBuiltins(wtest);
			let b = reduceBuiltins(w);



			if ( a != b ) score -= 10;

			canidates.push([target, m, score]);
		}

		if ( canidates.length == 0 ) {
			debug("CALL FAILED", this.name)
			return Value.undef;
		}
		canidates.sort((a,b) => b[2] - a[2]);
		console.log("Found", w, canidates);
		return yield * canidates[0][0].call(thiz, args, s, n);
	}
}

function wrap(target, realm) {
	//debug("WRAP", target, Object.getOwnPropertyNames(target.properties));
	for ( let m of Object.getOwnPropertyNames(target.properties) ) {
		let parts = m.match(/^([^$]+)\$/);
		let v = target.getImmediate(m);
		if ( !parts ) continue;
		if ( Object.getOwnPropertyDescriptor(target.properties, parts[1]) ) continue;
		let dispatch = new JavaMethodDispatch(parts[1], realm);
		dispatch.superTarget = v.superTarget
		target.setImmediate(parts[1], dispatch);
	}
	//debug("= ", target, Object.getOwnPropertyNames(target.properties));
}

class JavaCreateClass extends EasyObjectValue {
	*call(thiz, args, s) {

		let name = yield * args[0].toStringNative();
		wrap(args[1], s.realm);
		wrap(yield * args[1].get('prototype', s.realm), s.realm);
		s.global.add(name, args[1]);
		args[1].call = JavaMethodDispatch.prototype.call;
		args[1].name = name;
		
		return args[0];
	}
}


class JavaMath extends EasyObjectValue {
	static *random(thiz, args, s) { return s.fromNative(0, 'double'); }
	static *sqrt(thiz, args, s) { 
		let v = yield * s.realm.Math.easyRef.sqrt(thiz, args, s);
		return s.fromNative(v.toNative(), 'double');
	}
	static *pow(thiz, args, s) { 
		let v = yield * s.realm.Math.easyRef.pow(thiz, args, s);
		return s.fromNative(v.toNative(), 'double');
	}
	static *abs(thiz, args, s) { 
		let v = yield * s.realm.Math.easyRef.abs(thiz, args, s);
		return s.fromNative(v.toNative(), 'int');
	}
}

class SystemOut extends EasyObjectValue {
	static *println(thiz, argz, s) {
		s.realm.print(argz[0].toNative());
	}
	static *print(thiz, argz, s) {
		s.realm.write(argz[0].toNative());
	}
}

class System extends EasyObjectValue {
	constructor(realm) {
		super(realm);
		this.out = new SystemOut(realm);
	}
	static *out$g(thiz, argz, s) { return this.out; }
}

module.exports = { o: {JavaObject}, f:{Math:JavaMath, JavaCreateClass, JavaString, Integer, Double, System} }

/***/ })
/******/ ]);
});
