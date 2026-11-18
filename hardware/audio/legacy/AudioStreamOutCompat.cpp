#include <hardware_legacy/AudioHardwareInterface.h>

namespace android_audio_legacy {

// Oreo's legacy header declares this virtual method, but libaudiohw_legacy
// does not define it. Match the unsupported default used by the other optional
// timing method; do not report fabricated presentation timestamps.
// A platform implementation, if one is added later, takes precedence.
__attribute__((weak)) status_t AudioStreamOut::getPresentationPosition(
        uint64_t *, struct timespec *)
{
    return INVALID_OPERATION;
}

}  // namespace android_audio_legacy
