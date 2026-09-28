/**
 * dsh-notification — host half.
 *
 * Intentionally empty. This plugin has no host-side behaviour at all: no
 * services, no routes, no subprocesses, no HTTP egress. The module exists only
 * so the loader row mounts the package, which is what lets its browser half be
 * picked up through the `dsh.client` declaration in package.json.
 */

export const inject = [];

export function apply() {}
