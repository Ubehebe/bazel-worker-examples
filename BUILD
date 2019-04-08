load(":echo.bzl", "echo")
load("//rules/test:diff_test.bzl", "diff_test")
load("@pip//:requirements.bzl", "requirement")

# The java binary that powers the echo rule.
java_binary(
    name = "EchoJava",
    srcs = [
        "Echo.java",
    ],
    main_class = "workertest.Echo",
    deps = [
        "@io_bazel//src/main/protobuf:worker_protocol_java_proto",
        "@jcommander//jar",
    ],
)

py_binary(
    name = "echo_py",
    srcs = [
        "echo.py",
    ],
    main = "echo.py",
    deps = [
        "//forked:worker_protocol",
        requirement("protobuf"),
    ],
)

# Generate some fake input.
genrule(
    name = "input",
    srcs = [],
    outs = ["input.txt"],
    cmd = """echo "hello world" > $@""",
)

echo(
    name = "java_non_worker_1",
    executable = ":EchoJava",
    input = ":input",
    maybe_worker = False,
)

echo(
    name = "java_non_worker_2",
    executable = ":EchoJava",
    input = ":input",
    maybe_worker = True,
    mnemonic = "oops",  # mnemonic doesn't match --strategy in .bazelrc: not executed as worker
)

echo(
    name = "java_worker",
    executable = ":EchoJava",
    input = ":input",
    maybe_worker = True,
    mnemonic = "EchoWorker",
)

echo(
    name = "python_non_worker",
    executable = ":echo_py",
    input = ":input",
    maybe_worker = False,
)

echo(
    name = "python_worker",
    executable = ":echo_py",
    input = ":input",
    maybe_worker = True,
    mnemonic = "EchoWorker",
)

diff_test(
    name = "diff_test",
    actual = [
        ":java_non_worker_1",
        ":java_non_worker_2",
        ":java_worker",
        ":python_non_worker",
        ":python_worker",
    ],
    expected = ":input",
)
