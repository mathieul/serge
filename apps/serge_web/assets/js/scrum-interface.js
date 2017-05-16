import Elm from '../elm/Scrum/Main'

export default class ScrumInterface {
  constructor(config) {
    this.node = document.getElementById('elm-scrum')
    this.app = Elm.Scrum.Main.embed(this.node, config)
  }

  start() {
    setupPorts(this.app)
  }
}

function setupPorts(app) {
}
