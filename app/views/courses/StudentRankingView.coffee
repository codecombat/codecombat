helper = require 'lib/coursesHelper'
require('app/styles/courses/student-ranking-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/courses/student-ranking-view'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'collections/CocoCollection'
Campaign = require 'models/Campaign'
#Level = require 'models/Level'
utils = require 'core/utils'
#require 'three'
#UserPollsRecord = require 'models/UserPollsRecord'
#Poll = require 'models/Poll'
#CourseInstance = require 'models/CourseInstance'
#api = require 'core/api'
Classroom = require 'models/Classroom'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
Levels = require 'collections/Levels'
store = require 'core/store'

require('vendor/scripts/jquery-ui-1.11.1.custom')
require('vendor/styles/jquery-ui-1.11.1.custom.css')
fetchJson = require 'core/api/fetch-json'
Users = require 'collections/Users'

require 'lib/game-libraries'

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (model, student) ->
    super()
    @url = "/db/user/#{student}/level.sessions?project=state.complete,levelID,state.difficulty,playtime,state.topScores,codeLanguage,level"

class CampaignsCollection extends CocoCollection
  # We don't send all of levels, just the parts needed in countLevels
  url: '/db/campaign/-/overworld?project=slug,adjacentCampaigns,name,fullName,description,i18n,color,levels'
  model: Campaign

module.exports = class StrudentRankingView extends RootView
  id: 'campaign-view'
  template: template

  
  constructor: (options, @terrain) ->

    @courseInstanceID = utils.getQueryVariable('course-instance')
    if (@courseInstanceID != '5cd4352deed476002dd14019' && @courseInstanceID != '5cd57c5216f64600245afedd') && @courseInstanceID !='5ce01f45da3b2900357d7ed7'
      application.router.redirectHome()

    super options
    @terrain = 'picoctf' if window.serverConfig.picoCTF
    @editorMode = options?.editorMode
    @requiresSubscription = not me.isPremium()
    if @editorMode
      @terrain ?= 'dungeon'
    @levelStatusMap = {}
    @levelPlayCountMap = {}
    @levelDifficultyMap = {}
    @levelScoreMap = {}
    @meId = me.id
    
    @students = new Users()
    @studentsID = []
    @playTime = []
    @studentsLevelsCompleted = []
    @sessions = []
    @courseInstances = new CocoCollection([], { url: "/db/user/#{me.id}/course_instances", model: CourseInstance})
    @supermodel.loadCollection(@courseInstances, { cache: false })
    @supermodel.addPromiseResource(store.dispatch('courses/fetch'))
    @store = store
    
    @campaign = new Campaign({_id:@terrain})
    @campaign = @supermodel.loadModel(@campaign).model
    @courseLevelsFake = {}
    @courseInstance = new CourseInstance(_id: @courseInstanceID)
    jqxhr = @courseInstance.fetch()
    @supermodel.trackRequest(jqxhr)
    new Promise(jqxhr.then).then(=>
      @courseID = @courseInstance.get('courseID')

      @course = new Course(_id: @courseID)
      @supermodel.trackRequest @course.fetch()
      if @courseInstance.get('classroomID')
        classroomID = @courseInstance.get('classroomID')
        @classroom = new Classroom(_id: classroomID)
        @supermodel.trackRequest @classroom.fetch()
        @listenTo @classroom, 'sync', =>
          @fetchSession()
          @fetchStudents()
      )
    


  fetchSession: ()->
    #It is not appropriate to do this. This is a temporary solution.
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42e0b1ec72d00279cddaf'), 'your_sessions', {cache: false}, 1).model)#Alana
    @studentsID.push('5cd42e0b1ec72d00279cddaf')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42b9d9df7ff002b3ba3ed'), 'your_sessions', {cache: false}, 1).model)#Alexandre
    @studentsID.push('5cd42b9d9df7ff002b3ba3ed')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42a3e783ffb0039306479'), 'your_sessions', {cache: false}, 1).model)#Brian
    @studentsID.push('5cd42a3e783ffb0039306479')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42d73cc8f94004ccbda21'), 'your_sessions', {cache: false}, 1).model)#Caroline
    @studentsID.push('5cd42d73cc8f94004ccbda21')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42d370d42cf0024b8e2a0'), 'your_sessions', {cache: false}, 1).model)#Cláudio
    @studentsID.push('5cd42d370d42cf0024b8e2a0')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42ad51ec72d00279cd132'), 'your_sessions', {cache: false}, 1).model)#Davi
    @studentsID.push('5cd42ad51ec72d00279cd132')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42a8b697c92003ce2bd5c'), 'your_sessions', {cache: false}, 1).model)#Débora
    @studentsID.push('5cd42a8b697c92003ce2bd5c')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42f1715f63b002dd42cbc'), 'your_sessions', {cache: false}, 1).model)#Felipe
    @studentsID.push('5cd42f1715f63b002dd42cbc')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42e36c75fba003f06e933'), 'your_sessions', {cache: false}, 1).model)#Francerley
    @studentsID.push('5cd42e36c75fba003f06e933')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42c5615f63b002dd42192'), 'your_sessions', {cache: false}, 1).model)#Francisco
    @studentsID.push('5cd42c5615f63b002dd42192')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42bc615f63b002dd41ec5'), 'your_sessions', {cache: false}, 1).model)#João
    @studentsID.push('5cd42bc615f63b002dd41ec5')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd4353956eba9004c82af45'), 'your_sessions', {cache: false}, 1).model)#Kayllane
    @studentsID.push('5cd4353956eba9004c82af45')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd429a39df7ff002b3b9c03'), 'your_sessions', {cache: false}, 1).model)#Khawe
    @studentsID.push('5cd429a39df7ff002b3b9c03')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd44e8b15f63b002dd4b01a'), 'your_sessions', {cache: false}, 1).model)#Kildere
    @studentsID.push('5cd44e8b15f63b002dd4b01a')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42c298797f30022639473'), 'your_sessions', {cache: false}, 1).model)#Livia
    @studentsID.push('5cd42c298797f30022639473')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42d547610750045a80c0f'), 'your_sessions', {cache: false}, 1).model)#Luis
    @studentsID.push('5cd42d547610750045a80c0f')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42d4c1ec72d00279cd9db'), 'your_sessions', {cache: false}, 1).model)#Lydia
    @studentsID.push('5cd42d4c1ec72d00279cd9db')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42d7ab9d8db00286a8013'), 'your_sessions', {cache: false}, 1).model)#Vinicius
    @studentsID.push('5cd42d7ab9d8db00286a8013')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42bb1db1a5f00420ffa73'), 'your_sessions', {cache: false}, 1).model)#Wenddel
    @studentsID.push('5cd42bb1db1a5f00420ffa73')
    @sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5cd42ac21ec72d00279cd100'), 'your_sessions', {cache: false}, 1).model)#Wystefani
    @studentsID.push('5cd42ac21ec72d00279cd100')

    #@sessions.push(@supermodel.loadCollection(new LevelSessionsCollection(LevelSession,'5a217768db5a1a00850eb52d'), 'your_sessions', {cache: false}, 1).model)#TESTE
    #@studentsID.push('5a217768db5a1a00850eb52d')
  
  fetchStudents: () ->
    Promise.all(@students.fetchForClassroom(@classroom, {removeDeleted: true, data: {project: 'firstName,lastName,name,email,coursePrepaid,coursePrepaidID,deleted'}}))
    .then =>

  onLoaded: ->
    @updateClassroomSessions()
    return if @fullyRendered
    @render()

  updateClassroomSessions: ->
    if @classroom
      usuario = 0
      for session_ in @sessions
        playtime = 0
        for session in session_.models # O PROBLEMA ESTÁ AQUI!!!!!!!! 
          unless @levelStatusMap[session.get('levelID')] is 'complete'
            @levelStatusMap[session.get('levelID')] = if session.get('state')?.complete then 'complete' else 'started'
          if @levelStatusMap[session.get('levelID')] is 'complete'
            playtime += session.get('playtime')

        count = total: 0, completed: 0
        for level, levelIndex in _.values($.extend true, {}, @getLevels() ? {})
          completed = @levelStatusMap[level.slug] is 'complete'
          started = @levelStatusMap[level.slug] is 'started'
          ++count.total if (level.unlockedInSameCampaign or not level.locked) and (started or completed or not (level.locked and level.practice and level.slug.substring(level.slug.length - 2) in ['-a', '-b', '-c', '-d']))
          ++count.completed if completed

        @studentsLevelsCompleted.push(count.completed)
        @playTime.push(playtime)
        usuario++
        @levelStatusMap = {}


  onSessionsLoaded: (e) ->
    @render()
    

 
  getLevels: () ->
    return @courseLevelsFake if @courseLevels?
    @campaign?.get('levels')

  