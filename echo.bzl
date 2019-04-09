def _echo(ctx):
    args = ctx.actions.args()
    args.add("--input", ctx.file.input)
    ctx.actions.run_shell(
        inputs = [ctx.file.input],
        outputs = [ctx.outputs.txt],
        command = """%s > %s "$@" """ % (ctx.executable._echo.path, ctx.outputs.txt.path),
        tools = [ctx.executable._echo],
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
