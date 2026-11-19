#include <jni.h>
#include "NitroKeyShortcutsOnLoad.hpp"

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
  return margelo::nitro::keyshortcuts::initialize(vm);
}
