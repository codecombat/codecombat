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
          props: { type: 'parents', showPremium: true }
        },
        {
          path: '/live-classes',
          component: () => import(/* webpackChunkName: "ParentsView" */ 'app/views/landing-pages/parents/PageParents'),
          props: (route) => ({ showPremium: false, type: route.query.type })
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
        }
      ]
    })
  }

  return vueRouter
}
