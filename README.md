# Polyglot implementations of Bazel persistent workers

This repository contains implementations of Bazel persistent workers in different languages (so far
Java and Python). The actual work done by the workers is trivial; the goal is to compare the
complexity of the implementations across languages.

## Background

[Actions](https://docs.bazel.build/versions/master/skylark/rules.html#actions) are the fundamental
unit of execution during a Bazel build. (A typical action is running a compiler on a set of inputs
to produce a set of outputs.) By default, Bazel re-invokes the tool powering an action every time
the action needs to be run.

Some tools are expensive to invoke (a JVM) or would benefit from maintaining state between
invocations (a compiler that caches an AST). This is what persistent workers are for. When an action
is configured to run as a worker, Bazel invokes the tool once and keeps it running in the
background, communicating with it via stdin/stdout-based IO.

This repository defines a simple rule, `echo`, whose action can be powered by tools written in
different languages, and tools written in Java and Python that power the action.

## Implementation difficulties

The main difficulty in implementing a worker is lack of documentation. They are not documented on
[docs.bazel.build](https://docs.bazel.build) (though their existence is mentioned in a few places).
The best documentation seems to be
[this bazel-discuss thread](https://groups.google.com/forum/#!msg/bazel-discuss/oAEnuhYOPm8/ol7hf4KWJgAJ)
from 2016 and
[this Medium post](https://medium.com/@mmorearty/how-to-create-a-persistent-worker-for-bazel-7738bba2cabb)
from 2017.