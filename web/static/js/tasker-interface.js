export default class TaskerInterface {
  constructor(config) {
    this.node = document.getElementById('elm-tasker')
    this.app = Elm.Tasker.embed(this.node, config)
  }

  start() {
    setTimeout(() => setupPorts(this.app), 0)
  }
}

function setupPorts(app) {
  // subscribe to Elm commands
  // app.ports.check.subscribe((param1, param2) => console.log(param1, param2))

  // send to Elm, received as subscription
  // app.ports.doSomething.send("string", 42)
}
