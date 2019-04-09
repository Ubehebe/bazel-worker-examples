load("@pip//:requirements.bzl", "requirement")

# Executables that want to run as bazel persistent workers read WorkRequest protos from stdin and
# write WorkResult protos to stdout. @io_bazel publishes java_proto_library and cc_proto_library
# targets for these protos, but no py_proto_library yet. (Also, py_proto_library isn't mature.) In
# the meantime, run protoc manually to generate the python gencode. Based on
# https://stackoverflow.com/questions/50930301/bazel-py-proto-library-is-not-defined.
genrule(
    name = "worker_protocol_gencode",
    srcs = [
        "@io_bazel//src/main/protobuf:worker_protocol.proto",
    ],
    outs = [
        "worker_protocol_pb2.py",
    ],
    cmd = """$(location @com_google_protobuf//:protoc) --python_out=$(@D) $(<)
genfile=$$(find . | grep \.py$$)
cp $$genfile $@""",
    tools = ["@com_google_protobuf//:protoc"],
)

py_library(
    name = "worker_protocol",
    srcs = [
        ":worker_protocol_gencode",
    ],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        requirement("protobuf"),
    ],
)