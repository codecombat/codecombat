/* eslint import/no-absolute-path: 0 */
import VueRouter from 'vue-router'

let vueRouter

export default function getVueRouter () {
  if (typeof vueRouter === 'undefined') {
    vueRouter = new VueRouter({
      // Routing is currently driven by Backbone Router.  When we migrate away from backbone, switch to history
      mode: 'abstract',

      routes: [
        {
          path: '/parents',
          component: () => import(/* webpackChunkName: "ParentsView" */ 'app/views/landing-pages/parents/PageParents'),
          props: (route) => ({ showPremium: true, type: route.query.type })
        },
        {
          path: '/league',
          component: () => import(/* webpackChunkName: "LeagueView" */ 'app/views/landing-pages/league/PageLeague'),
          children: [
            // Stub pages
            { path: '', component: () => import(/* webpackChunkName: "LeagueView" */ 'app/views/landing-pages/league/PageLeagueGlobal') },
            {
              path: 'ladders',
              name: 'LaddersList',
              component: () => import(/* webpackChunkName: "mainLadderViewV2" */'app/views/ladder/MainLadderViewV2'),
              meta: { toTop: true }
            },
            { path: ':idOrSlug', component: () => import(/* webpackChunkName: "LeagueView" */ 'app/views/landing-pages/league/PageLeagueGlobal') }
          ]
        },
        {
          path: '/live-classes',
          component: () => import(/* webpackChunkName: "ParentsView" */ 'app/views/landing-pages/parents/PageParents'),
          props: (route) => ({ showPremium: false, type: route.query.type || 'live-classes' })
        },
        {
          path: '/live',
          component: () => import(/* webpackChunkName: "ParentsView" */ 'app/views/landing-pages/parents/PageParents'),
          props: (route) => ({ showPremium: false, type: route.query.type || 'direct-mail' })
        },
        {
          path: '/school-administrator',
          component: () => import(/* webpackChunkName: "teachers" */ 'app/views/school-administrator/SchoolAdministratorComponent'),
          children: [
            { path: '', component: () => import(/* webpackChunkName: "teachers" */ 'app/views/school-administrator/teachers/SchoolAdminTeacherListView') },
            { path: 'teacher/:teacherId', component: () => import(/* webpackChunkName: "teachers" */ 'app/views/school-administrator/dashboard/SchoolAdminDashboardTeacherView') },
            { path: 'teacher/:teacherId/classroom/:classroomId', component: () => import(/* webpackChunkName: "teachers" */ 'app/views/courses/TeacherClassViewV2.vue') },
            { path: 'teacher/:teacherId/classroom/:classroomId/:studentId', component: () => import(/* webpackChunkName: "teachers" */ 'app/views/teachers/classes/TeacherStudentView.vue') },
            { path: 'licenses/stats', component: () => import(/* webpackChunkName: 'LicenseStats' */ 'app/views/school-administrator/dashboard/LicenseTableView.vue') }
          ]
        },
        {
          path: '/api-dashboard',
          component: () => import(/* webpackChunkName: "apiViews" */ 'app/views/api/components/ApiDashboard')
        },
        {
          path: '/admin/clan',
          component: () => import(/* webpackChunkName: "admin" */ 'app/views/admin/PageClanSearch'),
        },
        {
          path: '/admin/clan/:clanId',
          component: () => import(/* webpackChunkName: "admin" */ 'app/views/admin/PageClanEdit'),
        },
        {
          path: '/outcomes-report/:kind/:country?/:idOrSlug',
          component: () => import(/* webpackChunkName: "outcomesReport" */ 'app/views/outcomes-report/PageOutcomesReport'),
        },
        // Warning: In production debugging of third party iframe!
        {
          path: '/temporary-debug-timetap',
          component: () => import(/* webpackChunkName: "thirdPartyDebugging" */ 'app/components/timetap/TimeTapDebugPage')
        },
        {
          path: '/payments/manage-billing',
          component: () => import(/* webpackChunkName: "manageBillingComponent"  */'app/views/payment/ManageBillingView'),
        },
        {
          path: '/payments/online-classes-success',
          component: () => import(/* webpackChunkName: "onlineClassesSuccessComponent" */'app/views/payment/online-class/SuccessView'),
        },
        {
          path: '/payments/home-subscriptions-success',
          component: () => import(/* webpackChunkName: "homeSubscriptionSuccessComponent" */'app/views/payment/HomeSubscriptionsSuccessView'),
          props: (route) => ({ ...route.query, ...route.params })
        },
        {
          path: '/payments/tecmilenio-success',
          component: () => import(/* webpackChunkName: "tecmilenioSuccessComponent" */'app/views/payment/student-license/TecmilenioSuccessView')
        },
        {
          path: '/payments/:slug',
          component: () => import(/* webpackChunkName: "paymentComponent" */'app/views/payment/PaymentComponentView'),
        },
        {
          path: '/ed-link/login-redirect',
          component: () => import(/* webpackChunkName: "edLinkRedirectView" */'app/views/user/EdLinkRedirectView'),
          props: (route) => ({ ...route.query, ...route.params })
        },
        {
          path: '/teachers/licenses',
          component: () => import(/* webpackChunkName: "paymentStudentLicenses" */'app/views/payment/v2/StudentLicensesMainComponent')
        },
        {
          path: '/teachers/licenses/join',
          component: () => import(/* webpackChunkName: "teachers" */'app/views/teachers/JoinLicensesByCode.vue')
        },
        {
          path: '/teachers/resources',
          component: () => import(/* webpackChunkName: "teachers" */ 'app/views/teachers/teacher-dashboard/BaseResourceHub/index.vue'),
        },
        {
          path: '/teachers/resources_new',
          component: () => import(/* webpackChunkName: "teachers_new" */ 'app/views/teachers/teacher-dashboard/BaseResourceHub/index.vue'),
        },
        {
          path: '/libraries',
          component: () => import(/* webpackChunkName: "libraryMain" */ 'app/views/library/LibraryMainView')
        },
        {
          path: '/library/:libraryId/login',
          component: () => import(/* webpackChunkName: "libraryLogin" */ 'app/views/library/LibraryLoginView'),
          props: (route) => ({ ...route.query, ...route.params })
        },
        {
          path: '/podcast',
          name: 'AllPodcasts',
          component: () => import(/* webpackChunkName: "podcastMain" */'/app/views/podcast/PodcastHomeView')
        },
        {
          path: '/podcast/:handle',
          name: 'PodcastSingle',
          component: () => import(/* webpackChunkName: "podcastSingle" */'/app/views/podcast/SinglePodcastView')
        },
        {
          path: '/users/switch-account',
          name: 'UserSwitchAccount',
          component: () => import(/* webpackChunkName: "userSwitchAccount" */'/app/views/user/SwitchAccountView')
        },
        {
          path: '/users/switch-account/:confirmingUserId/:requestingConfirmUserId/confirm',
          name: 'UserSwitchAccount',
          component: () => import(/* webpackChunkName: "userSwitchAccountConfirm" */'/app/views/user/SwitchAccountConfirmationView'),
          props: (route) => ({ ...route.query, ...route.params })
        }
      ],
      scrollBehavior(to) {
        const scroll = {}
        if (to.meta?.toTop) scroll.top = 0
        return scroll
      }
    })
  }

  return vueRouter
}
