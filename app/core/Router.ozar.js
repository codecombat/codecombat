/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS201: Simplify complex destructure assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CocoRouter;
const dynamicRequire = require('lib/dynamicRequire');
const locale = require('locale/locale');
const globalVar = require('core/globalVar');

const go = (path, options) => (function() { return this.routeDirectly(path, arguments, options); });

// This can be wrapped around existing route functions,
// to restrict the new teacher dashboard only for admins (using flag newTeacherDashboardActive)
const teacherProxyRoute = originalRoute => (function() {
  // if sessionStorage.getItem('newTeacherDashboardActive') == 'active'
  return go('core/SingletonAppVueComponentView').apply(this, arguments);
});
  // originalRoute.apply(@, arguments)

const redirect = path => (function() {
  delete window.alreadyLoadedView;
  return this.navigate(path + document.location.search, { trigger: true, replace: true });
});

const utils = require('./utils');
const ViewLoadTimer = require('core/ViewLoadTimer');

module.exports = (CocoRouter = (function() {
  CocoRouter = class CocoRouter extends Backbone.Router {
    static initClass() {
  
      this.prototype.routes = {
        ''() {
          if (window.serverConfig.picoCTF) {
            return this.routeDirectly('play/CampaignView', ['picoctf'], {});
          }
          if (utils.getQueryVariable('hour_of_code')) {
            delete window.alreadyLoadedView;
            return this.navigate("/play?hour_of_code=true", {trigger: true, replace: true});
          }
          if (!utils.isOzaria && !me.isAnonymous() && !me.isStudent() && !me.isTeacher() && !me.isAdmin() && !me.hasSubscription() && !me.isAPIClient()) {
            delete window.alreadyLoadedView;
            return this.navigate("/premium", {trigger: true, replace: true});
          }
          return this.routeDirectly('HomeView', []);
        },
  
        'about': go('AboutView'),
  
        'account': go('account/MainAccountView'),
        'account/settings': go('account/AccountSettingsView'),
        'account/unsubscribe': go('account/UnsubscribeView'),
        'account/payments': go('account/PaymentsView'),
        'account/subscription': go('account/SubscriptionView', { redirectStudents: true, redirectTeachers: true }),
        'account/invoices': go('account/InvoicesView'),
        'account/prepaid': go('account/PrepaidView'),
  
        'licensor': go('LicensorView'),
  
        'admin': go('admin/MainAdminView'),
        'admin/clas': go('admin/CLAsView'),
        'admin/classroom-content': go('admin/AdminClassroomContentView'),
        'admin/classroom-levels': go('admin/AdminClassroomLevelsView'),
        'admin/partial-unit-release'() {
          return this.routeDirectly('views/admin/PartialUnitReleaseView', [], { vueRoute: true, baseTemplate: 'base-empty' });
        },
        'admin/classrooms-progress': go('admin/AdminClassroomsProgressView'),
        'admin/design-elements': go('admin/DesignElementsView'),
        'admin/files': go('admin/FilesView'),
        'admin/analytics': go('admin/AnalyticsView'),
        'admin/analytics/subscriptions': go('admin/AnalyticsSubscriptionsView'),
        'admin/level-hints': go('admin/AdminLevelHintsView'),
        'admin/level-sessions': go('admin/LevelSessionsView'),
        'admin/school-counts': go('admin/SchoolCountsView'),
        'admin/school-licenses': go('admin/SchoolLicensesView'),
        'admin/sub-cancellations': go('admin/AdminSubCancellationsView'),
        'admin/base': go('admin/BaseView'),
        'admin/demo-requests': go('admin/DemoRequestsView'),
        'admin/trial-requests': go('admin/TrialRequestsView'),
        'admin/user-code-problems': go('admin/UserCodeProblemsView'),
        'admin/pending-patches': go('admin/PendingPatchesView'),
        'admin/codelogs': go('admin/CodeLogsView'),
        'admin/skipped-contacts': go('admin/SkippedContactsView'),
        'admin/outcomes-report-result': go('admin/OutcomeReportResultView'),
        'admin/outcomes-report': go('admin/OutcomesReportView'),
  
        'announcements': go('core/SingletonAppVueComponentView'),
        // Removing route, leaving plumbing.  Unclear how much we'd rewrite this, given a new endorsement.
        // 'apcsp(/*subpath)': go('teachers/DynamicAPCSPView')
  
        'artisans': go('artisans/ArtisansView'),
  
        'artisans/level-tasks': go('artisans/LevelTasksView'),
        'artisans/solution-problems': go('artisans/SolutionProblemsView'),
        'artisans/thang-tasks': go('artisans/ThangTasksView'),
        'artisans/level-concepts': go('artisans/LevelConceptMap'),
        'artisans/level-guides': go('artisans/LevelGuidesView'),
        'artisans/student-solutions': go('artisans/StudentSolutionsView'),
        'artisans/tag-test': go('artisans/TagTestView'),
        'artisans/bulk-level-editor': go('artisans/BulkLevelEditView'),
        'artisans/sandbox': go('artisans/SandboxView'),
        'artisans/bulk-level-editor/:campaign': go('artisans/BulkLevelEditView'),
  
        'careers': () => { return window.location.href = 'https://jobs.lever.co/codecombat'; },
  
        'cla': go('CLAView'),
  
        'clans': go('clans/ClansView'),
        'clans/:clanID': go('clans/ClanDetailsView'),
  
        'community'() { return this.navigate("/contribute", {trigger: true, replace: true}); },
  
        'contribute': go('contribute/MainContributeView'),
        'contribute/adventurer': go('contribute/AdventurerView'),
        'contribute/ambassador': go('contribute/AmbassadorView'),
        'contribute/archmage': go('contribute/ArchmageView'),
        'contribute/artisan': go('contribute/ArtisanView'),
        'contribute/diplomat': go('contribute/DiplomatView'),
        'contribute/scribe': go('contribute/ScribeView'),
  
        'courses': redirect('/students'), // Redirected 9/3/16
        'Courses': redirect('/students'), // Redirected 9/3/16
        'courses/students': redirect('/students'), // Redirected 9/3/16
        'courses/teachers': redirect('/teachers/classes'),
        'courses/purchase': redirect('/teachers/licenses'),
        'courses/enroll(/:courseID)': redirect('/teachers/licenses'),
        'courses/update-account': redirect('students/update-account'), // Redirected 9/3/16
        'courses/:classroomID'() { return this.navigate(`/students/${arguments[0]}`, {trigger: true, replace: true}); }, // Redirected 9/3/16
        'courses/:courseID/:courseInstanceID'() { return this.navigate(`/students/${arguments[0]}/${arguments[1]}`, {trigger: true, replace: true}); }, // Redirected 9/3/16
  
        'dei': go('core/SingletonAppVueComponentView'),
        'diversity-equity-and-inclusion': go('core/SingletonAppVueComponentView'),
        'db/*path': 'routeToServer',
        'docs/components': go('editor/docs/ComponentsDocumentationView'),
        'docs/systems': go('editor/docs/SystemsDocumentationView'),
  
        'editor': go('CommunityView'),
  
        'editor/achievement': go('editor/achievement/AchievementSearchView'),
        'editor/achievement/:articleID': go('editor/achievement/AchievementEditView'),
        'editor/article': go('editor/article/ArticleSearchView'),
        'editor/article/preview': go('editor/article/ArticlePreviewView'),
        'editor/article/:articleID': go('editor/article/ArticleEditView'),
        'editor/announcement': go('editor/announcement/AnnouncementSearchView'),
        'editor/announcement/:announcementId': go('editor/announcement/AnnouncementEditView'),
        'editor/cinematic(/*subpath)': go('core/SingletonAppVueComponentView'),
        'editor/cutscene(/*subpath)': go('core/SingletonAppVueComponentView'),
        'editor/interactive(/*subpath)': go('core/SingletonAppVueComponentView'),
        'editor/level': go('editor/level/LevelSearchView'),
        'editor/level/:levelID': go('editor/level/LevelEditView'),
        'editor/thang': go('editor/thang/ThangTypeSearchView'),
        'editor/thang/:thangID': go('editor/thang/ThangTypeEditView'),
        'editor/campaign/:campaignID(/:campaignPage)': go('editor/campaign/CampaignEditorView'),
        'editor/poll': go('editor/poll/PollSearchView'),
        'editor/poll/:articleID': go('editor/poll/PollEditView'),
        'editor/verifier(/:levelID)': go('editor/verifier/VerifierView'),
        'editor/i18n-verifier(/:levelID)': go('editor/verifier/i18nVerifierView'),
        'editor/course': go('editor/course/CourseSearchView'),
        'editor/course/:courseID': go('editor/course/CourseEditView'),
        'editor/resource': go('editor/resource/ResourceSearchView'),
        'editor/resource/:resourceID': go('editor/resource/ResourceEditView'),
        'editor/archived-elements': go('core/SingletonAppVueComponentView'),
        'editor/podcast': go('editor/podcast/PodcastSearchView'),
        'editor/podcast/:podcastId': go('editor/podcast/PodcastEditView'),
        'editor/chat': go('editor/chat/ChatSearchView'),
        'editor/chat/:chatID': go('editor/chat/ChatEditView'),
  
        'etc': redirect('/teachers/demo'),
        'demo': redirect('/teachers/demo'),
        'quote': redirect('/teachers/demo'),
  
        'file/*path': 'routeToServer',
  
        'funding': go('core/SingletonAppVueComponentView'),
  
        'github/*path': 'routeToServer',
  
        'hoc'(queryString) {
          if (queryString == null) { queryString = ''; }
          // Load the tracking image without it disrupting the page layout.
          const hocImg = new Image();
          hocImg.src = 'https://code.org/api/hour/begin_codecombat_ozaria.png';
          if (queryString) {
            queryString = '&' + queryString;
          }
          return this.navigate(`/play/chapter-1-sky-mountain?hour_of_code=true${queryString}`, { trigger: true });
        },
  
        'home': go('HomeView'),
  
        'i18n': go('i18n/I18NHomeView'),
        'i18n/thang/:handle': go('i18n/I18NEditThangTypeView'),
        'i18n/component/:handle': go('i18n/I18NEditComponentView'),
        'i18n/level/:handle': go('i18n/I18NEditLevelView'),
        'i18n/achievement/:handle': go('i18n/I18NEditAchievementView'),
        'i18n/campaign/:handle': go('i18n/I18NEditCampaignView'),
        'i18n/poll/:handle': go('i18n/I18NEditPollView'),
        'i18n/course/:handle': go('i18n/I18NEditCourseView'),
        'i18n/cinematic/:handle': go('i18n/I18NEditCinematicView'),
        'i18n/product/:handle': go('i18n/I18NEditProductView'),
        'i18n/article/:handle': go('i18n/I18NEditArticleView'),
        'i18n/interactive/:handle': go('i18n/I18NEditInteractiveView'),
        'i18n/cutscene/:handle': go('i18n/I18NEditCutsceneView'),
        'i18n/resource_hub_resource/:handle': go('i18n/I18NEditResourceHubResourceView'),
  
        'identify': go('user/IdentifyView'),
        'il-signup': go('account/IsraelSignupView'),
  
        'legal': go('LegalView'),
  
        'logout': 'logout',
  
        'minigames/conditionals': go('minigames/ConditionalMinigameView'),
  
        'mobile'() {
          return this.routeDirectly('views/landing-pages/mobile/PageMobileView', [], { vueRoute: true, baseTemplate: 'base-empty' });
        },
  
        'outcomes-report(/*subpath)': go('core/SingletonAppVueComponentView'),
  
        'paypal/subscribe-callback': go('play/CampaignView'),
        'paypal/cancel-callback': go('account/SubscriptionView'),
  
        'play/level/:levelID'(levelID) {
          const props = {
            levelID
          };
          return this.routeDirectly('ozaria/site/play/PagePlayLevel', [], {vueRoute: true, baseTemplate: 'base-empty', propsData: props});
        },
        // TODO move to vue router after support for empty template is added there
        'play/:campaign'(campaign) {
          const props = {
            campaign
          };
          return this.routeDirectly('ozaria/site/play/PageUnitMap', [], {vueRoute: true, baseTemplate: 'base-empty', propsData: props});
        },
  
        'play/intro/:introLevelIdOrSlug'(introLevelIdOrSlug) {
          const props = {
            introLevelIdOrSlug
          };
          return this.routeDirectly('introLevel', [], {vueRoute: true, baseTemplate: 'base-empty', propsData: props});
        },
  
        // 'play(/)': go('play/CampaignView', { redirectStudents: true, redirectTeachers: true }) # extra slash is to get Facebook app to work
        // 'play/ladder/:levelID/:leagueType/:leagueID': go('ladder/LadderView')
        // 'play/ladder/:levelID': go('ladder/LadderView')
        // 'play/ladder': go('ladder/MainLadderView')
        // 'play/level/:levelID': go('play/level/PlayLevelView')
        // 'play/video/level/:levelID': go('play/level/PlayLevelVideoView')
        'play/game-dev-level/:sessionID': go('play/level/PlayGameDevLevelView'),
        // 'play/web-dev-level/:sessionID': go('play/level/PlayWebDevLevelView')
        'play/game-dev-level/:levelID/:sessionID'(levelID, sessionID, queryString) {
          return this.navigate(`play/game-dev-level/${sessionID}?${queryString}`, { trigger: true, replace: true });
        },
        // 'play/web-dev-level/:levelID/:sessionID': (levelID, sessionID, queryString) ->
        //   @navigate("play/web-dev-level/#{sessionID}?#{queryString}", { trigger: true, replace: true })
        // 'play/:map': go('play/CampaignView')
  
        // These are admin-only routes since they are only used internally for testing -> interactive/, cinematic/, cutscene/, ozaria/avatar-selector
        'interactive/:interactiveIdOrSlug(?code-language=:codeLanguage)'(interactiveIdOrSlug, codeLanguage) {
          const props = {
            interactiveIdOrSlug,
            codeLanguage // This will also come from intro level page later
          };
          if (me.isAdmin()) { return this.routeDirectly('interactive', [], {vueRoute: true, baseTemplate: 'base-empty', propsData: props}); }
        },
  
        'cinematic/:cinematicIdOrSlug'(cinematicIdOrSlug) {
          const props = {
            cinematicIdOrSlug,
          };
          if (me.isAdmin()) { return this.routeDirectly('cinematic', [], {vueRoute: true, baseTemplate: 'base-empty', propsData: props}); }
        },
  
        'cutscene/:cutsceneId'(cutsceneId) {
          const props = {
            cutsceneId,
          };
          if (me.isAdmin()) { return this.routeDirectly('cutscene', [], { vueRoute: true, baseTemplate: 'base-empty', propsData: props }); }
        },
  
        'ozaria/avatar-selector'() {
          if (me.isAdmin()) { return this.routeDirectly('ozaria/site/avatarSelector', [], { vueRoute: true, baseTemplate: 'base-empty' }); }
        },
  
        'preview': go('HomeView'),
  
        'privacy': go('PrivacyView'),
  
        'professional-development': go('core/SingletonAppVueComponentView'),
        'pd': go('core/SingletonAppVueComponentView'),
        'efficacy': go('core/SingletonAppVueComponentView'),
  
        'sel': go('core/SingletonAppVueComponentView'),
        'social-and-emotional-learning': go('core/SingletonAppVueComponentView'),
        'schools': go('HomeView'),
        'seen': go('HomeView'),
  
        'students': go('courses/CoursesView', { redirectTeachers: true }),
        'students/update-account': go('courses/CoursesUpdateAccountView', { redirectTeachers: true }),
        'students/project-gallery/:courseInstanceID': go('courses/ProjectGalleryView'),
        'students/assessments/:classroomID': go('courses/StudentAssessmentsView'),
        'students/videos/:courseID/:courseName': go('courses/CourseVideosView'),
        'students/:classroomID': go('courses/ClassroomView', { redirectTeachers: true, studentsOnly: true }),
        'students/:courseID/:courseInstanceID': go('courses/CourseDetailsView', { redirectTeachers: true, studentsOnly: true }),
  
        'teachers': teacherProxyRoute(redirect('/teachers/classes')),
        'teachers/classes': teacherProxyRoute(go('courses/TeacherClassesView', { redirectStudents: true, teachersOnly: true })),
        // Added for new teacher dashboard. Can be changed.
        'teachers/projects/:classroomId': go('core/SingletonAppVueComponentView'),
        'teachers/classes/:classroomID/:studentID': go('teachers/TeacherStudentView', { redirectStudents: true, teachersOnly: true }),
        'teachers/classes/:classroomID': teacherProxyRoute(go('courses/TeacherClassView', { redirectStudents: true, teachersOnly: true })),
        'teachers/courses': redirect('/teachers'), // Redirected 8/20/2019
        'teachers/units': redirect('/teachers'), // Redirected 9/10/2020
        'teachers/course-solution/:courseID/:language': go('teachers/TeacherCourseSolutionView', { redirectStudents: true }),
        'teachers/campaign-solution/:courseID/:language': go('teachers/TeacherCourseSolutionView', { redirectStudents: true, campaignMode: true }),
        'teachers/demo': redirect('/teachers/quote'),
        'teachers/enrollments': redirect('/teachers/licenses'),
        'teachers/hour-of-code': () => { return window.location.href = 'https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing'; },
        // Redundant linking in case of external linking to our hoc resources:
        'teachers/resources/hoc2019':  () => { return window.location.href = 'https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing'; },
        'teachers/resources/hoc2020':  () => { return window.location.href = 'https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing'; },
        'teachers/licenses': teacherProxyRoute(go('courses/EnrollmentsView', { redirectStudents: true, teachersOnly: true })),
        'teachers/freetrial': go('teachers/RequestQuoteView', { redirectStudents: true }),
        'teachers/quote': go('teachers/RequestQuoteView', { redirectStudents: true }),
        'teachers/resources': teacherProxyRoute(go('teachers/ResourceHubView', { redirectStudents: true })),
        'teachers/professional-development': teacherProxyRoute(go('pd/PDView', { redirectStudents: true })),
        // Removing route, leaving plumbing.  Unclear how much we'd rewrite this, given a new endorsement.
        // 'teachers/resources/ap-cs-principles': go('teachers/ApCsPrinciplesView', { redirectStudents: true })
        'teachers/resources/:name': go('teachers/MarkdownResourceView', { redirectStudents: true }),
        'teachers/signup'() {
          if (me.isAnonymous()) { return this.routeDirectly('teachers/CreateTeacherAccountView', []); }
          if (me.isStudent() && !me.isAdmin()) { return this.navigate('/students', {trigger: true, replace: true}); }
          return this.navigate('/teachers/update-account', {trigger: true, replace: true});
        },
        'teachers/update-account'() {
          if (me.isAnonymous()) { return this.navigate('/teachers/signup', {trigger: true, replace: true}); }
          if (me.isStudent() && !me.isAdmin()) { return this.navigate('/students', {trigger: true, replace: true}); }
          return this.routeDirectly('teachers/ConvertToTeacherAccountView', []);
        },
  
        'school-administrator(/*subpath)': go('core/SingletonAppVueComponentView'),
        'cinematicplaceholder/:levelSlug': go('core/SingletonAppVueComponentView'),
  
        'sign-up/educator': go('core/SingletonAppVueComponentView'),
  
        'test(/*subpath)': go('TestView'),
  
        'user/:slugOrID': go('user/MainUserView'),
        'certificates/:slugOrID': go('user/CertificatesView'),
        'certificates/:id/anon': go('user/AnonCertificatesView'),
  
        'user/:userID/verify/:verificationCode': go('user/EmailVerifiedView'),
        'user/:userID/opt-in/:verificationCode': go('user/UserOptInView'),
  
        'users/switch-account': go('core/SingletonAppVueComponentView'),
        'users/switch-account/*path': go('core/SingletonAppVueComponentView'),
  
        'podcast': go('core/SingletonAppVueComponentView'),
        'podcast/*path': go('core/SingletonAppVueComponentView'),
  
        'libraries': go('core/SingletonAppVueComponentView'),
        'library/*path': go('core/SingletonAppVueComponentView'),
  
        'api-dashboard': go('core/SingletonAppVueComponentView'),
  
        '*name/': 'removeTrailingSlash',
        '*name': go('NotFoundView')
      };
    }

    _routeToRegExp(route) {
      return new RegExp(super._routeToRegExp(route), 'i'); // make all routes case insensitive
    }

    initialize() {
      // http://nerds.airbnb.com/how-to-add-google-analytics-page-tracking-to-57536
      this.bind('route', this._trackPageView);
      Backbone.Mediator.subscribe('router:navigate', this.onNavigate, this);
      this.initializeSocialMediaServices = _.once(this.initializeSocialMediaServices);

      // Lazily require and load VueRouter because it currently loads all of its dependencies
      // in a single Webpack bundle.  The app initialization logic assumes that all Views are
      // loaded lazily and thus will not be initialized as part of the initial page load.
      //
      // Because Vue router and its dependencies are loaded in a single bundle any CocoViews
      // that are loaded via the Vue router are initialized too early.  Delaying loading of
      // Vue router delays initialization of dependent CocoViews until an appropriate time.
      //
      // TODO Integrate webpack bundle loading with vueRouter and load this normally
      return this.vueRouter = require('app/core/vueRouter').default();
    }

    routeToServer(e) {
      return window.location.href = window.location.href;
    }

    removeTrailingSlash(e) {
      return this.navigate(e, {trigger: true});
    }

    routeDirectly(path, args, options) {
      if (args == null) { args = []; }
      if (options == null) { options = {}; }
      this.vueRouter.push(`/${Backbone.history.getFragment()}`).catch(e => console.error('vue router push warning:', e));

      if (window.alreadyLoadedView) {
        path = window.alreadyLoadedView;
      }

      if (!options.recursive) { this.viewLoad = new ViewLoadTimer(); }
      if (options.redirectStudents && me.isStudent() && !me.isAdmin()) {
        return this.redirectHome();
      }
      if (options.redirectTeachers && me.isTeacher() && !me.isAdmin()) {
        return this.redirectHome();
      }
      if (options.teachersOnly && !(me.isTeacher() || me.isAdmin())) {
        return this.routeDirectly('teachers/RestrictedToTeachersView');
      }
      if (options.studentsOnly && !(me.isStudent() || me.isAdmin())) {
        return this.routeDirectly('courses/RestrictedToStudentsView');
      }
      const leavingMessage = _.result(globalVar.currentView, 'onLeaveMessage');
      if (leavingMessage) {
        // Custom messages don't work any more, main browsers just show generic ones. So, this could be refactored.
        if (!confirm(leavingMessage)) {
          return this.navigate(this.path, {replace: true});
        } else {
          globalVar.currentView.onLeaveMessage = _.noop; // to stop repeat confirm calls
        }
      }

      // TODO: Combine these two?
      if (features.playViewsOnly && !(_.string.startsWith(document.location.pathname, '/play') || (document.location.pathname === '/admin'))) {
        delete window.alreadyLoadedView;
        return this.navigate('/play', { trigger: true, replace: true });
      }
      if (features.playOnly && !/^(views)?\/?play/.test(path)) {
        delete window.alreadyLoadedView;
        path = 'play/CampaignView';
      }

      if (!_.string.startsWith(path, 'views/')) { path = `views/${path}`; }
      return Promise.all([
        dynamicRequire[path](), // Load the view file
        // The locale load is already initialized by `application`, just need the promise
        locale.load(me.get('preferredLanguage', true))
      ]).then((...args1) => {
        let view;
        const [ViewClass] = Array.from(args1[0]);
        if (!ViewClass) { return go('NotFoundView'); }

        const SingletonAppVueComponentView = require('views/core/SingletonAppVueComponentView').default;
        if ((ViewClass === SingletonAppVueComponentView) && globalVar.currentView instanceof SingletonAppVueComponentView) {
          // The SingletonAppVueComponentView maintains its own Vue app with its own routing layer.  If it
          // is already routed we do not need to route again
          console.debug("Skipping route in Backbone - delegating to Vue app");
          return;
        } else if (options.vueRoute) {  // Routing to a vue component using VueComponentView
          const vueComponentView = require('views/core/VueComponentView');
          view = new vueComponentView(ViewClass.default, options, ...Array.from(args));
        } else {
          const Klass = ViewClass.default ? ViewClass.default : ViewClass;
          view = new Klass(options, ...Array.from(args));  // options, then any path fragment args
        }

        view.render();

        if (window.alreadyLoadedView) {
          console.log("Need to merge view");
          delete window.alreadyLoadedView;
          this.mergeView(view);
        } else {
          this.openView(view);
        }

        this.viewLoad.setView(view);
        return this.viewLoad.record();
    }).catch(err => console.log(err));
    }

    redirectHome() {
      delete window.alreadyLoadedView;
      const homeUrl = (() => { switch (false) {
        case !me.isStudent(): return '/students';
        case !me.isTeacher(): return '/teachers';
        default: return '/';
      } })();
      return this.navigate(homeUrl, {trigger: true, replace: true});
    }

    openView(view) {
      this.closeCurrentView();
      $('#page-container').empty().append(view.el);
      this.activateTab();
      return this.didOpenView(view);
    }

    mergeView(view) {
      if (view.mergeWithPrerendered == null) {
        return this.openView(view);
      }

      const target = $('#page-container>div');
      view.mergeWithPrerendered(target);
      view.setElement(target[0]);
      return this.didOpenView(view);
    }

    didOpenView(view) {
      globalVar.currentView = view;
      view.afterInsert();
      view.didReappear();
      this.path = document.location.pathname + document.location.search;
      return this.trigger('did-load-route');
    }

    closeCurrentView() {
      if (globalVar.currentView != null ? globalVar.currentView.reloadOnClose : undefined) {
        return document.location.reload();
      }
      __guardMethod__(currentModal, 'hide', o => o.hide());
      if (globalVar.currentView == null) { return; }
      globalVar.currentView.modalClosed();
      globalVar.currentView.destroy();
      $('.popover').popover('hide');
      $('#flying-focus').css({top: 0, left: 0}); // otherwise it might make the page unnecessarily tall
      return _.delay((function() {
        $('html')[0].scrollTop = 0;
        return $('body')[0].scrollTop = 0;
      }), 10);
    }

    initializeSocialMediaServices() {
      if (application.testing || application.demoing || !me.useSocialSignOn()) { return; }
      application.facebookHandler.loadAPI();
      application.gplusHandler.loadAPI();
      return require('core/services/twitter')();
    }

    activateTab() {
      const base = _.string.words(document.location.pathname.slice(1), '/')[0];
      try {
        return $(`ul.nav li.${base}`).addClass('active');
      } catch (e) {
        return console.warn(e);  // Possibly a hash that would not match a valid element
      }
    }

    _trackPageView() {
      return (window.tracker != null ? window.tracker.trackPageView() : undefined);
    }

    onNavigate(e, recursive) {
      let view;
      if (recursive == null) { recursive = false; }
      if (!recursive) { this.viewLoad = new ViewLoadTimer(); }
      if (_.isString(e.viewClass)) {
        dynamicRequire[e.viewClass]().then(viewClass => {
          return this.onNavigate(_.assign({}, e, {viewClass}), true);
        });
        return;
      }

      const manualView = e.view || e.viewClass;
      if ((e.route === document.location.pathname) && !manualView) {
        return document.location.reload();
      }
      this.navigate(e.route, {trigger: !manualView});
      this._trackPageView();
      if (!manualView) { return; }
      if (e.viewClass) {
        const args = e.viewArgs || [];
        const Klass = e.viewClass.default ? e.viewClass.default : e.viewClass;
        view = new Klass(...Array.from(args || []));
        view.render();
        this.openView(view);
        this.viewLoad.setView(view);
      } else {
        this.openView(e.view);
        this.viewLoad.setView(e.view);
      }
      return this.viewLoad.record();
    }

    navigate(fragment, options) {
      super.navigate(fragment, options);
      return Backbone.Mediator.publish('router:navigated', {route: fragment});
    }

    reload() {
      return document.location.reload();
    }

    logout() {
      me.logout();
      return this.navigate('/', { trigger: true });
    }
  };
  CocoRouter.initClass();
  return CocoRouter;
})());

function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}