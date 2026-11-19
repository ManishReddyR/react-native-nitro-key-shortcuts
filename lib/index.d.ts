import type { KeyShortcuts } from './specs/KeyShortcuts.nitro';
export type { KeyShortcut, KeyShortcuts } from './specs/KeyShortcuts.nitro';
/** The one app-wide shortcut registry. Throws if the native side isn't linked. */
export declare const getKeyShortcuts: () => KeyShortcuts;
