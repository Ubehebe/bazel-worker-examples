def _echo(ctx):
    args = ctx.actions.args()
    args.add("--in", ctx.file.input)
    args.add("--out", ctx.outputs.txt)
    if ctx.attr.worker:
        # The ultimate decision to use a worker or not is controlled by the --strategy flag to bazel
        # build. This action must be invoked in a way that is compatible with both workers and
        # regular invocation.

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
            executable = ctx.executable._echo,
            execution_requirements = {
                "supports-workers": "1",
            },
            arguments = [startup_args],
            # There is a corresponding line in .bazelrc setting --strategy=EchoWorkerAware=worker.
            mnemonic = "EchoWorkerAware",
        )
    else:
        # A normal action invocation.
        ctx.actions.run(
            inputs = [ctx.file.input],
            outputs = [ctx.outputs.txt],
            executable = ctx.executable._echo,
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
        "worker": attr.bool(
            mandatory = True,  # just to be explicit
        ),
        "_echo": attr.label(
            default = "//workertest:Echo",
            executable = True,
            cfg = "host",
        ),
    },
    outputs = {
        "txt": "%{name}.txt",
    },
)
