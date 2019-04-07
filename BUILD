load(":echo.bzl", "echo")
load("//rules/test:diff_test.bzl", "diff_test")

# The java binary that powers the echo rule.
java_binary(
    name = "Echo",
    srcs = [
        "Echo.java",
    ],
    main_class = "workertest.Echo",
    deps = [
        "@io_bazel//src/main/protobuf:worker_protocol_java_proto",
        "@jcommander//jar",
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
    name = "java_non_worker",
    executable = ":Echo",
    input = ":input",
    maybe_worker = False,
)

echo(
    name = "java_worker",
    executable = ":Echo",
    input = ":input",
    maybe_worker = True,
)

diff_test(
    name = "java_non_worker_diff_test",
    actual = ":java_non_worker",
    expected = "input.txt",
)

diff_test(
    name = "worker_diff_test",
    actual = ":java_worker",
    expected = "input.txt",
)
