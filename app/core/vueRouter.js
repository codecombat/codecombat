import VueRouter from 'vue-router'

let vueRouter

export default function getVueRouter () {
  if (typeof vueRouter === 'undefined') {
    vueRouter = new VueRouter({
      // Routing is currently driven by Backbone Router.  When we migrate away from backbone, switch to history
      mode: 'abstract',

      routes: [
        {
          path: '/diversity-equity-and-inclusion',
          component: () => import(/* webpackChunkName: "dei" */ 'app/views/dei/DEIView.vue')
        },
        { path: '/dei', redirect: '/diversity-equity-and-inclusion' }, // TODO: doesn't actually update to /diversity-equity-and-inclusion URL, just adds alias
        {
          path: '/editor/cinematic',
          component: () => import(/* webpackChunkName: "editor" */ '../../ozaria/site/components/cinematic/PageCinematicEditor/BaseCinematicList')
        },
        {
          // TODO: The cinematic editor route should use vue guards to check for admin access.
          // TODO: Once we have a base editor component, use the nested route structure.
          path: '/editor/cinematic/:slug',
          component: () => import(/* webpackChunkName: "editor" */ '../../ozaria/site/components/cinematic/PageCinematicEditor'),
          props: true
        },
        {
          path: '/editor/cutscene',
          component: () => import(/* webpackChunkName: "editor" */ '../../ozaria/site/components/cutscene/PageCutsceneEditorList')
        },
        {
          path: '/editor/cutscene/:slugOrId',
          component: () => import(/* webpackChunkName: "editor" */ '../../ozaria/site/components/cutscene/PageCutsceneEditor'),
          props: true
        },
        {
          path: '/editor/interactive/:slug?',
          component: () => import(/* webpackChunkName: "editor" */ '../../ozaria/site/components/interactive/PageInteractiveEditor'),
          props: true
        },
        {
          path: '/editor/archived-elements',
          component: () => import(/* webpackChunkName: "editor" */ '../../ozaria/site/components/archived-elements/ArchivedElementsEditor'),
          beforeEnter: (to, from, next) => {
            // TODO: Fix /editor redirect. The documentation says next('/editor') would redirect to /editor,
            // but it is not working as intended. Perhaps something to do with our use of Backbone and Vue together.
            // https://router.vuejs.org/guide/advanced/navigation-guards.html#per-route-guard
            next(me.isAdmin() ? true : '/editor')
          }
        },
        {
          path: '/funding',
          component: () => import(/* webpackChunkName: "pd" */ 'app/views/funding/FundingView.vue')
        },
        {
          path: '/school-administrator',
          component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/school-admin-dashboard/BaseSchoolAdminDashboard/index.vue'),
          children: [
            { path: '', component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/school-admin-dashboard/BaseMySchools/index.vue') },
            { path: 'teacher/:teacherId', component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/school-admin-dashboard/administered-teachers/BaseTeacherAllClasses/index.vue'), props: true },
            { path: 'teacher/:teacherId/classes', component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/school-admin-dashboard/administered-teachers/BaseTeacherAllClasses/index.vue'), props: true },
            { path: 'teacher/:teacherId/classes/:classroomId', component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/school-admin-dashboard/administered-teachers/BaseTeacherClassProgress/index.vue'), props: true },
            { path: 'teacher/:teacherId/classes/:classroomId/projects', component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/school-admin-dashboard/administered-teachers/BaseTeacherClassProjects/index.vue'), props: true },
            { path: 'teacher/:teacherId/licenses/', component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/school-admin-dashboard/administered-teachers/BaseTeacherLicenses/index.vue'), props: true },
            { path: 'licenses', component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/school-admin-dashboard/BaseSchoolAdminLicenses/index.vue') }
          ]
        },

        {
          path: '/teachers',
          component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/teacher-dashboard/BaseTeacherDashboard/index.vue'),
          children: [
            { path: '', component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/teacher-dashboard/BaseMyClasses/index.vue') },
            { path: 'classes', component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/teacher-dashboard/BaseMyClasses/index.vue') },
            { path: 'classes/:classroomId', component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/teacher-dashboard/BaseSingleClass/index.vue'), props: true },
            { path: 'projects/:classroomId', component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/teacher-dashboard/BaseStudentProjects/index.vue'), props: true },
            { path: 'licenses', component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/teacher-dashboard/BaseTeacherLicenses/index.vue') },
            { path: 'resources', component: () => import(/* webpackChunkName: "teachers" */ '../../ozaria/site/components/teacher-dashboard/BaseResourceHub/index.vue') },
            { path: 'professional-development', component: () => import(/* webpackChunkName: "pd" */ '../views/pd/PDView.vue') }
          ]
        },
        {
          path: '/cinematicplaceholder/:levelSlug?',
          component: () => import(/* webpackChunkName: "play" */ '../../ozaria/site/components/cinematic/CinematicPlaceholder'),
          props: (route) => {
            return {
              levelSlug: route.params.levelSlug
            }
          }
        },
        {
          path: '/sign-up/educator',
          component: () => import(/* webpackChunkName: "account" */ '../../ozaria/site/components/sign-up/PageEducatorSignup/index.vue')
        },
        {
          path: '/professional-development',
          component: () => import(/* webpackChunkName: "pd" */ 'app/views/pd/PDView.vue')
        },
        { path: '/pd', redirect: '/professional-development' }, // TODO: doesn't actually update to /professional-development URL, just adds alias
        {
          path: '/social-and-emotional-learning',
          component: () => import(/* webpackChunkName: "sel" */ 'app/views/sel/SELView.vue')
        },
        { path: '/sel', redirect: '/social-and-emotional-learning' }, // TODO: doesn't actually update to /social-and-emotional-learning URL, just adds alias

      ]
    })

    vueRouter.afterEach((to, from) => {
      // Fixes issue of page not scrolling to top on navigation change
      if (to.path !== from.path) {
        // If the user has navigated within the router, try and reset the scroll position.
        try {
          window.scrollTo(0, 0)
        } catch (e) {
          // Can fail silently. Handling browser compatibility
        }
      }
    })
  }

  return vueRouter
}
