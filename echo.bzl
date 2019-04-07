def _echo(ctx):
    args = ctx.actions.args()
    args.add("--in", ctx.file.input)
    args.add("--out", ctx.outputs.txt)
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
