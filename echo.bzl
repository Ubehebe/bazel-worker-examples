def _echo(ctx):
    args = ctx.actions.args()
    args.add("--in", ctx.file.input)
    args.add("--out", ctx.outputs.txt)
    if ctx.attr.maybe_worker:
        # It is impossible to know at analysis time if the action will be executed by a worker;
        # that is controlled at execution time by --strategy=EchoWorkerAware=<strategy>.
        # Thus this action must be set up in a way that is compatible with both worker and normal
        # execution. In both cases, there is some bazel magic:
        # - If it really is a worker, bazel gets rid of the @foo.worker_args argument and replaces
        # it with a --persistent_worker flag. The contents of the worker_arg_file will be available on
        # stdin as a WorkRequest proto, and the executable should write its result as a WorkResult
        # proto to stdout.
        # - If it really is not a worker, bazel inlines @foo.worker_args (replaces it with its own
        # contents).
        # See https://groups.google.com/forum/#!msg/bazel-discuss/oAEnuhYOPm8/ol7hf4KWJgAJ for more
        # information.
        worker_arg_file = ctx.actions.declare_file(ctx.attr.name + ".worker_args")
        ctx.actions.write(
            output = worker_arg_file,
            content = args,
        )
        startup_args = ctx.actions.args()
        startup_args.add("@" + worker_arg_file.path)
        ctx.actions.run(
            inputs = [ctx.file.input, worker_arg_file],
            outputs = [ctx.outputs.txt],
            executable = ctx.executable.executable,
            execution_requirements = {
                "supports-workers": "1",
            },
            arguments = [startup_args],
            mnemonic = ctx.attr.mnemonic,
        )
    else:
        # A non-worker action invocation. Since this action doesn't set supports-workers,
        # we know at analysis time it can't be invoked as a worker.
        ctx.actions.run(
            inputs = [ctx.file.input],
            outputs = [ctx.outputs.txt],
            executable = ctx.executable.executable,
            arguments = [args],
        )

    return []

echo = rule(
    implementation = _echo,
    attrs = {
        "input": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "maybe_worker": attr.bool(
            mandatory = True,  # just to be explicit
            doc = """whether to attempt to use a worker.
For this rule to run its action in a worker, this flag must be set AND the build must be invoked
with --strategy=EchoWorkerAware=worker.""",
        ),
        "executable": attr.label(
            executable = True,
            cfg = "host",
            doc = """the executable that powers the action (either //workertest:Echo or
//workertest:echo)""",
        ),
        "mnemonic": attr.string(),
    },
    outputs = {
        "txt": "%{name}.txt",
    },
)
