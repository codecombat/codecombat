export function getDisplayPermission (permission) {
  const display = permission?.toLowerCase()
  return $.i18n.t(`teacher_dashboard.${display}`)
}
