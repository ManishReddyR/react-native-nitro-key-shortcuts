import { NitroModules } from 'react-native-nitro-modules';
let instance = null;
/** The one app-wide shortcut registry. Throws if the native side isn't linked. */
export const getKeyShortcuts = () => {
    if (!instance) {
        instance = NitroModules.createHybridObject('KeyShortcuts');
    }
    return instance;
};
// Created at import so its native init drops shortcuts a reloaded runtime left behind.
try {
    getKeyShortcuts();
}
catch { }
