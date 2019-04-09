load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

BAZEL_VERSION = "0.24.0"  # enforced by check_bazel_version below

git_repository(
    name = "bazel_skylib",
    remote = "https://github.com/bazelbuild/bazel-skylib.git",
    tag = "0.8.0",
)

git_repository(
    name = "com_google_protobuf",
    commit = "35c9a5fef3f787bbda72295c526f4a357b02fec0",
    remote = "https://github.com/protocolbuffers/protobuf.git",
)

git_repository(
    name = "io_bazel",
    remote = "https://github.com/bazelbuild/bazel.git",
    tag = BAZEL_VERSION,
)

# There's nothing node-related in this repository. rules_nodejs defines a handy check_bazel_version
# function, used below.
git_repository(
    name = "build_bazel_rules_nodejs",
    remote = "https://github.com/bazelbuild/rules_nodejs.git",
    tag = "0.27.8",
)

git_repository(
    name = "io_bazel_rules_python",
    commit = "9bc2cd89f4d342c6dae2ee6fae4861ebbae69f85",
    remote = "https://github.com/bazelbuild/rules_python.git",
)

load("@build_bazel_rules_nodejs//:defs.bzl", "check_bazel_version")

check_bazel_version(BAZEL_VERSION)

load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

protobuf_deps()

load("@io_bazel_rules_python//python:pip.bzl", "pip_import")

pip_import(
    name = "pip",
    requirements = "//:requirements.txt",
)

load("@pip//:requirements.bzl", "pip_install")

pip_install()

maven_jar(
    name = "jcommander",
    artifact = "com.beust:jcommander:1.72",
)
