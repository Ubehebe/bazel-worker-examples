# Polyglot implementations of Bazel persistent workers

This repository contains implementations of Bazel persistent workers in different languages (so far
Java and Python). The actual work done by the workers is trivial; the goal is to compare the
complexity of the implementations across languages.

## Background

By default, Bazel runs actions by invoking an executable with arguments and waiting for it to
finish, much like you would invoke a command-line tool. For executables that are expensive (like
booting a JVM) or would benefit from maintaining state between runs (like a compiler that caches an
AST), this is wasteful. Bazel has a feature called persistent workers for this situation. Instead of
invoking a one-off executable to fulfill an action, Bazel can keep long-lived workers around,
and they can maintain state to speed up the build.

Persistent workers are not documented on docs.bazel.build, though their existence is mentioned in
a few places. The best resources seem to be [this bazel-discuss thread](https://groups.google.com/forum/#!msg/bazel-discuss/oAEnuhYOPm8/ol7hf4KWJgAJ)
from 2016 and [this Medium post](https://medium.com/@mmorearty/how-to-create-a-persistent-worker-for-bazel-7738bba2cabb)
from 2017. The rest of this readme uses concepts from these resources.

## What this repo is

This repository defines a simple rule, [echo](echo.bzl), that can be powered by a tool written in any
language. The tool is intentionally trivial: it copies the contents of a file given by an `--in`
flag to a file given by the `--out` flag.

This repo includes two implementations of the tool, in Java and Python. It runs them in several
worker and non-worker configurations, and checks that the output from each is identical. (I welcome
pull requests adding more languages; see below.) Since the email and blog post mentioned above are
mostly JVM-centric, I figured I would learn about persistent workers by implementing one in a different
language. So I did. Here's what I learned.

## Python implementation difficulties

### Protobuf toolchain

Bazel sends a [WorkRequest](https://github.com/bazelbuild/bazel/blob/master/src/main/protobuf/worker_protocol.proto)
proto to the worker over stdin, and expects the worker to write a corresponding WorkResponse proto
to its stdout when it is done. So the language the worker is written in needs to have APIs for
reading and writing protocol buffers. Although protoc (the proto compiler) has built-in support for
Python code generation, Bazel has not shipped a py_proto_library rule, the standard way of exposing
proto gencode. (Compare [java_proto_library](https://docs.bazel.build/versions/master/be/java.html#java_proto_library),
[cc_proto_library](https://docs.bazel.build/versions/master/be/c-cpp.html#cc_proto_library), etc.)

As a workaround, I had to invoke protoc manually, via a genrule [here](forked/BUILD).

### Protobuf APIs

The description of the worker protocol as "reading protos from stdin" and "writing protos to stdout"
hides an important detail. The protobuf wire format is not self-delimiting; consumers need to know
exactly how many bytes to read before attempting to parse the bytes as a proto. Bazel uses a common
technique of writing a single varint giving the size of the serialized WorkRequest before writing
the WorkRequest itself. The Java protobuf API has convenient methods for doing this automatically:
[parseDelimitedFrom](https://developers.google.com/protocol-buffers/docs/reference/java/com/google/protobuf/Parser#parseDelimitedFrom-java.io.InputStream-)
and [writeDelimitedTo](https://developers.google.com/protocol-buffers/docs/reference/java/com/google/protobuf/MessageLite#writeDelimitedTo-java.io.OutputStream-).
But the Python protobuf API has nothing equivalent.

As a workaround, I used private APIs in the Python protobuf library to read and write the varint manually
([here](echo.py#L21)).

### @argfile convention

In certain circumstances (specifically, when a tool has been designed for both worker and
traditional execution, but is being run traditionally), a tool can receive an `@argfile` argument.
What is this syntax? The `argfile` contains the tool's "real" arguments, but what is responsible
for replacing `@argfile` with the arguments it contains? Does Bazel do this? Is it shell magic?
(It's hard to Google for, or even know what to call this syntax.)

It turns out that it's just a convention, and it is the responsibility of the tool to read the
`argfile` and do the "real" argument parsing. The convention seems to be popular in the Java world
(e.g. [javac](https://docs.oracle.com/javase/8/docs/technotes/tools/windows/javac.html#BHCJEIBB)),
and is enabled by default in the flag-parsing library I used for the Java tool (jCommander). But in
argparse, the standard Python flag-parsing library, it needs to be explicitly enabled.

## Conclusions

- The persistent worker feature is valuable for many kinds of tools. It needs documentation
  that reflects its value.
- Workers in languages other than Java/C++ would be significantly easier to implement if the worker
  protocol didn't require protos. WorkRequest and WorkResult are very simple protos and could
  probably be serialized as JSON.