from argparse import ArgumentParser
from os import write
from sys import stdin

from forked.worker_protocol_pb2 import WorkRequest, WorkResponse
from google.protobuf.internal.decoder import _DecodeVarint32
from google.protobuf.internal.encoder import _VarintBytes

parser = ArgumentParser(
    # Without this, the second path documented in main below fails.
    fromfile_prefix_chars='@'
)
parser.add_argument("--in")
parser.add_argument("--out")
parser.add_argument("--persistent_worker", action="store_true")


def _echo(args):
    with open(vars(args).get('in')) as input:
        with open(args.out, 'w') as output:
            output.write(input.read())


def _worker_main():
    # Bazel writes a length -delimited WorkRequest proto to this program's stdin, and expects this
    # program to write a length-delimited WorkResponse proto to its stdout. Unfortunately,
    # the python proto runtime doesn't have any apis for length-delimited reading/writing.
    # So we roll it ourselves. Adapted from
    # https://www.datadoghq.com/blog/engineering/protobuf-parsing-in-python.
    while True:
        varint32 = stdin.read(2)
        msg_len, num_read = _DecodeVarint32(varint32, 0)
        work_request = WorkRequest()
        stuff = stdin.read(msg_len)
        work_request.ParseFromString(stuff)
        args = parser.parse_args(work_request.arguments)
        _echo(args)
        response = WorkResponse()
        response.exit_code = 0
        response_serialized = response.SerializeToString()
        size = response.ByteSize()
        write(1, _VarintBytes(size))
        write(1, response_serialized)


if __name__ == "__main__":
    """Powers the echo Starlark rule.

There are three paths through this main method:
- If this binary is invoked from the echo() action that does not set `supports-workers`, the args
  are delivered as regular command-line args, _echo() is called once, and the binary exits.
- If this binary is invoked from the echo() action that sets `supports-workers`, but Bazel decides
  not to run it as a worker, there is a single command-line arg `@blah.worker_args`. argparse
  replaces this with the contents of `blah.worker_args` (see `fromfile_prefix_chars` param to
  ArgumentParser), _echo() is called once, and the binary exits.
- If this binary is invoked from the echo() action that sets `supports-workers` and Bazel decides to
  run it as a worker, there is a single command-line arg `--persistent_worker`. The binary executes
  an infinite loop (_worker_main), reading WorkRequest protos from stdin and writing WorkResponse
  protos to stdout.
  """
    args = parser.parse_args()
    if args.persistent_worker:
        _worker_main()
    else:
        _echo(args)
