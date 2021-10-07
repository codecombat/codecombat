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
            { path: ':idOrSlug', component: () => import(/* webpackChunkName: "LeagueView" */ 'app/views/landing-pages/league/PageLeagueGlobal') }
          ]
        },
        {
          path: '/live-classes',
          component: () => import(/* webpackChunkName: "ParentsView" */ 'app/views/landing-pages/parents/PageParents'),
          props: (route) => ({ showPremium: false, type: route.query.type || 'live-classes' })
        },
        {
          path: '/school-administrator',
          component: () => import(/* webpackChunkName: "teachers" */ 'app/views/school-administrator/SchoolAdministratorComponent'),
          children: [
            { path: '', component: () => import(/* webpackChunkName: "teachers" */ 'app/views/school-administrator/teachers/SchoolAdminTeacherListView') },
            { path: 'teacher/:teacherId', component: () => import(/* webpackChunkName: "teachers" */ 'app/views/school-administrator/dashboard/SchoolAdminDashboardTeacherView') },
            { path: 'teacher/:teacherId/classroom/:classroomId', component: () => import(/* webpackChunkName: "teachers" */ 'app/views/courses/TeacherClassView.vue') },
            { path: 'teacher/:teacherId/classroom/:classroomId/:studentId', component: () => import(/* webpackChunkName: "teachers" */ 'app/views/teachers/classes/TeacherStudentView.vue') }
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
          component: () => import(/* webpackChunkName: "onlineClassesSuccessComponent" */'app/views/payment/PaymentOnlineClassesSuccessView'),
        },
        {
          path: '/payments/home-subscriptions-success',
          component: () => import(/* webpackChunkName: "homeSubscriptionSuccessComponent" */'app/views/payment/PaymentHomeSubscriptionsSuccessView'),
        },
        {
          path: '/payments/:slug',
          component: () => import(/* webpackChunkName: "paymentComponent" */'app/views/payment/PaymentComponentView'),
        },
      ]
    })
  }

  return vueRouter
}
