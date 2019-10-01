#esprima = require 'esprima'
#Syntax = esprima.Syntax

module.exports = execution =
  # Based on Esprima Harmony's Syntax map for Mozilla's Parser AST
  # https://github.com/ariya/esprima/blob/harmony/esprima.js#L118
  ArrayExpression: 1
  ArrayPattern: 1
  ArrowFunctionExpression: 1
  AssignmentExpression: 1
  BinaryExpression: 1
  BlockStatement: 1
  BreakStatement: 1
  CallExpression: 1
  CatchClause: 1
  ClassBody: 1
  ClassDeclaration: 1
  ClassExpression: 1
  ClassHeritage: 1
  ComprehensionBlock: 1
  ComprehensionExpression: 1
  ConditionalExpression: 1
  ContinueStatement: 1
  DebuggerStatement: 1
  DoWhileStatement: 1
  EmptyStatement: 1
  ExportDeclaration: 1
  ExportBatchSpecifier: 1
  ExportSpecifier: 1
  ExpressionStatement: 1
  ForInStatement: 1
  ForOfStatement: 1
  ForStatement: 1
  FunctionDeclaration: 1
  FunctionExpression: 1
  Identifier: 1
  IfStatement: 1
  ImportDeclaration: 1
  ImportSpecifier: 1
  LabeledStatement: 1
  Literal: 1
  LogicalExpression: 1
  MemberExpression: 1
  MethodDefinition: 1
  ModuleDeclaration: 1
  NewExpression: 1
  ObjectExpression: 1
  ObjectPattern: 1
  Program: 1
  Property: 1
  ReturnStatement: 1
  SequenceExpression: 1
  SpreadElement: 1
  SwitchCase: 1
  SwitchStatement: 1
  TaggedTemplateExpression: 1
  TemplateElement: 1
  TemplateLiteral: 1
  ThisExpression: 1
  ThrowStatement: 1
  TryStatement: 1
  UnaryExpression: 1
  UpdateExpression: 1
  VariableDeclaration: 1
  VariableDeclarator: 1
  WhileStatement: 1
  WithStatement: 1
  YieldExpression: 1

  # What about custom execution costs for different operators and functions and other things?