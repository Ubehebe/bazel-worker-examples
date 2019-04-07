load(":echo.bzl", "echo")
load("//rules/test:diff_test.bzl", "diff_test")

# The binary that powers the echo rule.
java_binary(
    name = "Echo",
    srcs = [
        "Echo.java",
    ],
    main_class = "workertest.Echo",
    deps = [
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
    name = "echo",
    input = ":input",
    worker = False,
)

diff_test(
    name = "diff_test",
    actual = "echo.txt",
    expected = "input.txt",
)
