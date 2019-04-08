load(":echo.bzl", "echo")
load("//rules/test:diff_test.bzl", "diff_test")
load("@pip//:requirements.bzl", "requirement")

# Define the binaries that can power the echo rule. The Java and Python binaries do the same thing
# and have the same command-line API.

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

# Define the actions. 3 pathways per binary (see echo.bzl) x 2 binaries = 6 targets.

echo(
    name = "java_non_worker_1",
    executable = ":EchoJava",
    input = ":input",
)

echo(
    name = "java_non_worker_2",
    executable = ":EchoJava",
    input = ":input",
    mnemonic = "oops",  # mnemonic doesn't match --strategy in .bazelrc: not executed as worker
    use_worker_if_possible = True,
)

echo(
    name = "java_worker",
    executable = ":EchoJava",
    input = ":input",
    mnemonic = "EchoWorker",
    use_worker_if_possible = True,
)

echo(
    name = "python_non_worker_1",
    executable = ":echo_py",
    input = ":input",
)

echo(
    name = "python_non_worker_2",
    executable = ":echo_py",
    input = ":input",
    mnemonic = "oops",  # mnemonic doesn't match --strategy in .bazelrc: not executed as worker
    use_worker_if_possible = True,
)

echo(
    name = "python_worker",
    executable = ":echo_py",
    input = ":input",
    mnemonic = "EchoWorker",
    use_worker_if_possible = True,
)

# All of the actions should produce the same output.
diff_test(
    name = "diff_test",
    actual = [
        ":java_non_worker_1",
        ":java_non_worker_2",
        ":java_worker",
        ":python_non_worker_1",
        ":python_non_worker_2",
        ":python_worker",
    ],
    expected = ":input",
)
