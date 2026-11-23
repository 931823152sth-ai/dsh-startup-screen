// Host half of the startup-screen plugin.
//
// Nothing runs on the host: the plugin exists so the loader enables a row
// whose package declares `dsh.client`, which is what makes the browser half
// (dsh/client.js) part of the web boot graph. Everything visible happens in
// the client bundle.
export const name = 'startup-screen'
export const inject = []
export function apply(ctx) {
  // no host-side behaviour
}
