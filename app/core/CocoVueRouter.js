import VueRouter from 'vue-router'

import SchoolAdminDashboard from 'app/views/school-administrator/SchoolAdministratorDashboardComponent'
import SchoolAdminDashboardTeacherListView from 'app/views/school-administrator/teachers/SchoolAdminTeacherListView'
import SchoolAdminTeacherView from 'app/views/school-administrator/dashboard/SchoolAdminDashboardTeacherView'

import TeacherClassView from 'views/teachers/class/TeacherClassView'

Vue.use(VueRouter)

let vueRouter;

export default function () {
  if (typeof vueRouter === 'undefined') {
    vueRouter = new VueRouter({
      mode: 'history',

      routes: [
        {
          path: '/school-administrator', component: SchoolAdminDashboard, children: [
            { path: '', component: SchoolAdminDashboardTeacherListView },
            { path: 'teacher/:id', component: SchoolAdminTeacherView },
            { path: 'teacher/:id/classroom/:classroomId', component: TeacherClassView },
          ]
        }
      ]
    })
  }

  return vueRouter
}
