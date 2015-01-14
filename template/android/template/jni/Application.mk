APP_ABI := ::foreach (PLATFORM.ARCH_ABIS)::::__current__:: ::end::
APP_PLATFORM := android-::PLATFORM.MINIMUM_SDK_VERSION::