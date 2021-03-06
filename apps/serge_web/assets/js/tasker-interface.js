import Elm from '../elm/Tasker/Main'

export default class TaskerInterface {
  constructor(config) {
    this.node = document.getElementById('elm-tasker')
    this.app = Elm.Tasker.Main.embed(this.node, config)
  }

  start() {
    setupPorts(this.app)
  }
}

function setupPorts(app) {
  app.ports.getTimeZone.subscribe(function () {
    const { timeZone } = Intl.DateTimeFormat().resolvedOptions()
    app.ports.setTimeZone.send(timeZone)
  })
}
