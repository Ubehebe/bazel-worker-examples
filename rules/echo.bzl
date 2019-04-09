def _echo(ctx):
    args = ctx.actions.args()
    args.add("--in", ctx.file.input)
    args.add("--out", ctx.outputs.out)
    if ctx.attr.use_worker_if_possible:
        # It is impossible to know at analysis time if this action will be executed by a worker;
        # that is controlled at execution time by --strategy=<mnemonic>=<strategy>.
        # This action is set up in a way that is compatible with both worker and normal execution.
        # - If this action executes as a worker, bazel replaces the @foo.worker_args argument with a
        # --persistent_worker flag. The contents of foo.worker_args are written to stdin as a
        # WorkRequest proto, preceded by a varint representing the proto's length. The executable
        # should write its result as a WorkResult proto to stdout, again preceded by its length.
        # - If this action does not execute as a worker, the executable receives @foo.worker_args as
        # its sole argument. The executable should read the "real" flags out of the foo.worker_args
        # file (many flag-parsing libraries have an API to do this automatically).
        worker_arg_file = ctx.actions.declare_file(ctx.attr.name + ".worker_args")
        ctx.actions.write(
            output = worker_arg_file,
            content = args,
        )
        ctx.actions.run(
            inputs = [ctx.file.input, worker_arg_file],
            outputs = [ctx.outputs.out],
            executable = ctx.executable.executable,
            execution_requirements = {
                "supports-workers": "1",
            },
            arguments = ["@" + worker_arg_file.path],
            mnemonic = ctx.attr.mnemonic,
        )
    else:
        # A non-worker action invocation. Since this action doesn't set supports-workers, we know at
        # analysis time it can't be invoked as a worker.
        ctx.actions.run(
            inputs = [ctx.file.input],
            outputs = [ctx.outputs.out],
            executable = ctx.executable.executable,
            arguments = [args],
        )

    return []

echo = rule(
    implementation = _echo,
    doc = """trivial action that copies an input file to an output.

Can be executed either as a persistent worker or conventionally. Targets must pass in the executable
to run, and can optionally specify action's mnemonic.""",
    attrs = {
        "input": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "use_worker_if_possible": attr.bool(
            doc = """whether to attempt to use a worker.
For this rule to run its action in a worker, this flag must be set AND the build must be invoked
with --strategy=<mnemonic>=worker, where <mnemonic> is the value of this target's mnemonic attr.""",
        ),
        "executable": attr.label(
            executable = True,
            cfg = "host",
            doc = "the executable that powers the action (either //:EchoJava or //:echo_py)",
        ),
        "mnemonic": attr.string(
            doc = """mnemonic to use for the action.
This is exposed so that tests can run the action with different mnemonics without needing separate
bazel --strategy=<mnemonic>=<strategy> invocations (bazel build ... will run them all).""",
        ),
    },
    outputs = {
        "out": "%{name}.out",
    },
)
