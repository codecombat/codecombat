import Vue from 'vue'
import VueRouter from 'vue-router'

import SchoolAdminDashboard from 'app/views/school-administrator/SchoolAdministratorDashboardComponent'
import SchoolAdminDashboardTeacherListView from 'app/views/school-administrator/teachers/DashboardTeacherListView'
import SchoolAdminTeacherView from 'views/school-administrator/teachers/SchoolAdminDashboardTeacherView'

Vue.use(VueRouter)

export default function () {
  return new VueRouter({
    mode: 'history',

    routes: [
      { path: '/school-administrator', component: SchoolAdminDashboard, children: [
          { path: '', component: SchoolAdminDashboardTeacherListView },
          { path: 'teacher/:id', component: SchoolAdminTeacherView }
        ] }
    ]
  })
}
