
objc_library(
    name = "MimeTypes",
    enable_modules = True,
    module_name = "MimeTypes",
    srcs = glob([
        "Sources/*.m",
        "Sources/*.h",
    ], allow_empty=True),
    hdrs = glob([
        "PublicHeaders/**/*.h",
    ]),
    includes = [
        "PublicHeaders",
    ],
    sdk_frameworks = [
      "Foundation",
    ],
    visibility = [
        "//visibility:public",
    ],
)
