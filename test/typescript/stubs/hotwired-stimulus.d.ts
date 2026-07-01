declare module "@hotwired/stimulus" {
  export class Controller {
    static targets: string[]
    static values: Record<string, unknown>

    dispatch(name: string, options?: Record<string, unknown>): Event
  }
}
