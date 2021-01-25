/*!
 * jaba
 * 
 * Compiled: Mon Jan 25 2021 06:27:45 GMT-0800 (PST)
 * Target  : web (umd)
 * Profile : modern
 * Version : 7d9aa3c
 * 
 * 
 * 
 */
(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory(require("esper"));
	else if(typeof define === 'function' && define.amd)
		define(["esper"], factory);
	else if(typeof exports === 'object')
		exports["esper-plugin-lang-cpp"] = factory(require("esper"));
	else
		root["esper-plugin-lang-cpp"] = factory(root["esper"]);
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
/******/ 	return __webpack_require__(__webpack_require__.s = 8);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */,
/* 1 */
/***/ (function(module, exports) {

module.exports = __WEBPACK_EXTERNAL_MODULE__1__;

/***/ }),
/* 2 */,
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
		if ( !node.loc && node.node != "LineEmpty" && node.node != "TraditionalComment" ) {
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
			case "LambdaExpression":
			case "Function":
				methods.push(node);
				next(node.body);
				methods.pop();
				return;
			case "Global":
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
				if ( node.expression ) next(node.expression);
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
			case "FieldAccess":
			case "TypeDeclarationStatement":
			case "EmptyStatement":
			case "InitializerList":
			case "ThisExpression":

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




function transpile(code, options) {
	let tcode = code.replace(/\/\*.*?\*\//g, function(m) {
		return new Array(m.length - 1).join(' ');
	})
	let iast = parser.parse(tcode, options);
	skope(iast);
	let r = transform(iast)
	//let src = generate(r).code;
	//console.log("CODE", src);

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
var ArrayValue = esper.ArrayValue
let debug = () => {}


class JavaPrimitiveValue extends esper.PrimitiveValue {
	constructor(value) {
		super(value);
	}

	derivePrototype(realm) {
		if(['cpp', 'java'].indexOf(realm.options.language) != -1){
			if ( this.boundType == "int" ) return realm.globalScope.get('Integer');
			if ( this.boundType == "double" ) return realm.globalScope.get('Double');
			if ( this.boundType == "string" ) return realm.globalScope.get('JavaString');
		}

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
		if ( !this.boundType ) return yield * super.add(other);
		if ( this.boundType == "string" ) return yield * esper.StringValue.prototype.add.call(this, other);
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
		if ( t == "var" || t == "auto" ) return args[1];
		if ( t == "String" ) t = "string";
		if ( t == "int" || t == "double" || t == "string" || t == "bool" ) {
			let val = args[1].toNative();
			let out = new JavaPrimitiveValue(val);
			out.boundType = t;
			return out;
		}
		debug("CAST FAILED", t);
		return args[1];
	}
}

function javaifyEngine(ev) {
	let fpn = Value.fromPrimativeNative.bind(Value);
	Value.fromPrimativeNative = (v) => {
		let type = typeof(v)
		let r = new JavaPrimitiveValue(v);
		if (type == "int") {
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
		return fpn(v)
	}
	let rev = ev.realm.fromNative.bind(ev.realm);
	ev.realm.fromNative = (v,n) => {
		if(['cpp', 'java'].indexOf(ev.realm.options.language) != -1) {
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
		}
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

	let amake = ArrayValue.make.bind(ArrayValue);
	ArrayValue.make = function(vals, realm) {
		if(realm.options.language == 'cpp') {
			let av = amake(vals, realm);
			av.setPrototype(new stdlib.p.CPPListProto(ev.realm));

			let l = vals.length
			if(l > 0) {av.setImmediate('x', vals[0]); av.properties.x.enumerable = false;}
			if(l > 1) {av.setImmediate('y', vals[1]); av.properties.y.enumerable = false;}
			if(l > 2) {av.setImmediate('z', vals[2]); av.properties.z.enumerable = false;}
			return av;
		}
		else {
			return amake(vals, realm);
		}
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
let EasyNativeFunction = esper.EasyNativeFunction
let ArrayValue = esper.ArrayValue;
let CompletionRecord = esper.CompletionRecord;
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
	*get(name, thiz) {
		let idx = Number(name);
		if ( !isNaN(idx) ) {
			return Value.fromNative(thiz.native[idx]);
		}
		return yield * super.get(name, thiz);
	}
	static *equals(o) {
		return this.serial == o.serial;
	}
	static *length$(thiz, argz, s) { 
		return s.fromNative(thiz.native.length, 'int'); 
	}
	static *size$(thiz, argz, s) {
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
		return s.fromNative(thiz.native.toString());
	}
	*call(thiz, args, s) {
		return thiz;
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

class InitializerList extends EasyObjectValue {
	// Hack for CodeCombat x-y-z coordinate literals
	*call(thiz, args, s) {
		let result = ArrayValue.make(args, s.realm);
		for ( let i = 0; i < args.length; ++i ) {
			if ( i == 0 ) yield * result.set("x", args[i]);
			if ( i == 1 ) yield * result.set("y", args[i]);
			if ( i == 2 ) yield * result.set("z", args[i]);
		}
		return result;
	}
}

function getTypeKey(w) {
	if ( !w ) return 'V'
}

function *dispatch(name, thiz, args, s, extra) {
	let target = undefined
	let w = '$V$';
	for ( let a of args ) {
		debug("ARG", a.boundType, a.debugString);
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
		debug("?",m,'vs',name);
		if ( !parts ) continue;
		if ( parts[1] != name ) continue;
		let target = yield * thiz.get(m, s);
		if ( m == name + w) {
			canidates = [[target, m, 100]];
			break;
		}
		let score = 80;
		let wtest = '$' + parts[2] + '$' + parts[3];
		debug("W",w,wtest);
		if ( wtest.length != w.length ) score -= 40;

		let a = reduceBuiltins(wtest);
		let b = reduceBuiltins(w);



		if ( a != b ) score -= 10;

		canidates.push([target, m, score]);
	}

	if ( canidates.length == 0 ) {
		debug("CALL FAILED", name)
		return Value.undef;
	}
	canidates.sort((a,b) => b[2] - a[2]);
	debug("Found", w, canidates[0][0].name);
	return yield * canidates[0][0].call(thiz, args, s, extra);
}

class JavaMethodDispatch extends EasyObjectValue {
	constructor(name, realm) {
		super(realm);
		this.name = name;
		this.realm = realm;
	}

	*call(thiz, args, s, extra) {
		return yield * dispatch(this.name, thiz, args, s, extra);
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
		let target = args[1];
		wrap(target, s.realm);
		wrap(yield * target.get('prototype', s.realm), s.realm);
		s.global.add(name, target);
		target.name = name;
		target.call = function*(thiz, args, s) {
			let pt = yield * target.makeThisForNew();
			debug("-> Invoke ctor", name);
			yield * dispatch(name, pt, args, s);
			return pt;
		}
		
		//let ctor = yield * target.get('constructor', s.realm);
		//target.setImmediate(name + '$V$', ctor);

		return args[0];
	}
}

class JavaCreateDefault extends EasyObjectValue {
	*call(thiz, args, s) {
		let typ = yield * args[0].toStringNative();
		switch ( typ ) {
			case "int":
			case "float":
			case "double":
				return s.fromNative(0, typ);
			default:
				if ( s.realm.options.language != "cpp" ) {
					return Value.undef;
				}
				let callee = s.get(typ);
				if ( callee ) {
					let thiz = yield * callee.makeThisForNew(s.realm);
					let result = yield * callee.call(thiz, [], s);
					return thiz;
				}
				return Value.undef;
		} 
		
	}
}

class JavaNewInstance extends EasyObjectValue {
	*call(thiz, args, s) {
		if ( s.realm.options.language != "cpp" ) {
			return args[0]
		}
		let object = ArrayValue.make(args, s.realm);
		return new esper.plugins.pointers.PointerValue(object, 0, s.realm);
		
	}
}

function *getLength(v) {
	let m = yield * v.get('length');
	return yield * m.toUIntNative();
}

class CPPListProto extends EasyObjectValue {
	constructor(realm) {
		super(realm);
	}

	static *size$e(thiz) {
		return yield * getLength(thiz);
	}

	static *push_back$e(thiz, args) {
		let l = yield * getLength(thiz);
		for ( let i = 0; i < args.length; ++i ) {
			yield * thiz.set(l + i, args[i]);
		}
		let nl = Value.fromNative(l + args.length);
		yield * thiz.set('length', nl);
		return Value.fromNative(l + args.length);
	}

	static *pop$e(thiz) {
		let l = yield * getLength(thiz);
		if (l < 1) return Value.undef;
		let poped = yield * thiz.get('0');
		for( let i = 0; i < l-1; i++) {
			let next = yield * thiz.get('' + (i+1));
			yield * thiz.set(i, next);
		}
		delete thiz.properties[l-1];
		yield * thiz.set('length', Value.fromNative(l-1))
		return poped;
	}

	static *pop_back$e(thiz) {
		let l = yield * getLength(thiz);
		if (l < 1) return Value.undef;
		let poped = yield * thiz.get('' + (l-1));
		delete thiz.properties[l-1];
		yield * thiz.set('length', Value.fromNative(l-1));
		return poped;
	}
}
CPPListProto.prototype.wellKnownName = '%CPPListPrototype%';

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

module.exports = {
	o: {JavaObject},
	p: {CPPListProto},
	f:{Math:JavaMath, JavaCreateClass, JavaCreateDefault, JavaNewInstance, JavaString, Integer, Double, System, InitializerList} 
}


/***/ }),
/* 8 */
/***/ (function(module, exports, __webpack_require__) {

var esper_ref = __webpack_require__(1);
var plugin = __webpack_require__(9);
esper_ref._registerPlugin(plugin);

/***/ }),
/* 9 */
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
	name: 'lang-cpp',
	parser: parser,
	init: function(esper) {
		//esper.plugin('babylon');
		esper.languages.cpp = plugin;
	},
	setupEngine: function(esper, engine) {
		utils.javaifyEngine(engine);
	}
};


/***/ })
/******/ ]);
});