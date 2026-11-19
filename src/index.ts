import { NitroModules } from 'react-native-nitro-modules'
import type { KeyShortcuts } from './specs/KeyShortcuts.nitro'

export type { KeyShortcut, KeyShortcuts } from './specs/KeyShortcuts.nitro'

let instance: KeyShortcuts | null = null

/** The one app-wide shortcut registry. Throws if the native side isn't linked. */
export const getKeyShortcuts = (): KeyShortcuts => {
  if (!instance) {
    instance = NitroModules.createHybridObject<KeyShortcuts>('KeyShortcuts')
  }
  return instance
}

// Created at import so its native init drops shortcuts a reloaded runtime left behind.
try {
  getKeyShortcuts()
} catch {}
