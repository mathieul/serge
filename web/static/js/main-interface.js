export default class OnlineInterface {
  constructor(config) {
    this.node = document.getElementById('elm-main')
    // this.app = Elm.Main.embed(this.node, config)
    this.app = Elm.Main.embed(this.node)
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
  // app.ports.initApplication.send(null)
}
