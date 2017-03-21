mongoose = require 'mongoose'
log = require 'winston'
config = require '../../server_config'
jsonSchema = require '../../app/schemas/models/cla_submission'

CLASubmissionSchema = new mongoose.Schema {}, {strict: false, minimize: false, read:config.mongo.readpref}

CLASubmissionSchema.statics.jsonSchema = jsonSchema

module.exports = CLASubmission = mongoose.model 'CLASubmission', CLASubmissionSchema, 'cla.submissions'
