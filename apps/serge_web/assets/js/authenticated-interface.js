export default class AuthenticatedInterface {
  constructor() {
  }

  start() {
    canAddTeamAccess()
    canDeleteTeamAccess()
    autoCloseAlerts()
  }
}

function canAddTeamAccess() {
  $(document).on('click', '#add-team-access', function (event) {
    event.preventDefault()
    const time = new Date().getTime()
    const template = $(this)
      .data('template')
      .replace(/\[0\]/g, `[${time}]`)
      .replace(/_0_/g, `_${time}_`)

      $(this).parents('.team-accesses').after(template)
  })
}

function canDeleteTeamAccess() {
  $(document).on('click', '.delete-team-access', function (event) {
    event.preventDefault()
    $(this).parents('.team-access').remove()
  })
}

function autoCloseAlerts() {
  setTimeout(() => $('.alert-dismissible').alert('close'), 5000)
}
