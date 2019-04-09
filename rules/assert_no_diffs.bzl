def _assert_no_diffs(ctx):
    args = ctx.actions.args()
    args.add("-q")
    args.add("--from-file", ctx.file.expected)
    args.add_all(ctx.files.actual)
    ctx.actions.run_shell(
        inputs = [ctx.file.expected] + ctx.files.actual,
        outputs = [ctx.outputs.ok],
        command = """diff "$@" && touch %s""" % ctx.outputs.ok.path,
        arguments = [args],
    )

assert_no_diffs = rule(
    implementation = _assert_no_diffs,
    doc = """asserts that all of the actual files have the same content as the expected file.
If all the files are the same, the rule produces an empty output. Otherwise, the target
fails to build and the diff is printed to the console.""",
    # TODO: this should arguably be a test rule (so that bazel build :no_diffs succeeds but bazel test
    # :no_diffs fails). It's easier to run this logic directly in an action than to write a script that
    # runs it later.
    attrs = {
        "expected": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "actual": attr.label_list(
            mandatory = True,
            allow_files = True,
        ),
    },
    outputs = {
        "ok": "%{name}.ok",
    },
)
