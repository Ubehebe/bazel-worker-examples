from argparse import ArgumentParser
from os import write
from sys import stdin

from forked.worker_protocol_pb2 import WorkRequest, WorkResponse
from google.protobuf.internal.decoder import _DecodeVarint32
from google.protobuf.internal.encoder import _VarintBytes

parser = ArgumentParser()
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
    args = parser.parse_args()
    if args.persistent_worker:
        _worker_main()
    else:
        _echo(args)
