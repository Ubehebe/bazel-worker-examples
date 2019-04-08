package workertest;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.google.devtools.build.lib.worker.WorkerProtocol.WorkRequest;
import com.google.devtools.build.lib.worker.WorkerProtocol.WorkResponse;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/** Powers the `echo()` Starlark rule. */
public final class Echo {

  @Parameter(names = "--in")
  private Path in;

  @Parameter(names = "--out")
  private Path out;

  @Parameter(names = "--persistent_worker")
  private boolean worker;

  private Echo() {}

  /**
   * There are three paths through this main method.
   *
   * <ul>
   *   <li>If this binary is invoked from the echo() action that does not set `supports-workers`,
   *       the args are delivered as regular command-line args, {@link #echo()} is called once, and
   *       the binary exits.
   *   <li>If this binary is invoked from the echo() action that sets `supports-workers`, but Bazel
   *       decides not to run it as a worker, there is a single command-line arg
   *       `@blah.worker_args`. The flag parsing library silently replaces this with the contents of
   *       `blah.worker_args` (see {@link JCommander.Builder#expandAtSign(Boolean)} {@link #echo()}
   *       is called once, and the binary exits.
   *   <li>If this binary is invoked from the echo() action that sets `supports-workers` and Bazel
   *       decides to run it as a worker, there is a single command-line arg `--persistent_worker`.
   *       The binary executes an {@link #workerMain() infinite loop}, reading {@link WorkRequest}
   *       protos from stdin and writing {@link WorkResponse} protos to stdout.
   * </ul>
   */
  public static void main(String[] args) throws IOException {
    Echo e = new Echo();
    JCommander.newBuilder().addObject(e).build().parse(args);
    if (e.worker) {
      workerMain();
    } else {
      e.echo();
    }
  }

  /**
   * If this is executing as a worker, its flags will be delivered via a WorkRequest proto on stdin,
   * and it should deliver its result via a WorkResult proto to stdout.
   */
  private static void workerMain() throws IOException {
    while (true) {
      WorkRequest workRequest = WorkRequest.parseDelimitedFrom(System.in);
      Echo e = new Echo();
      JCommander.newBuilder()
          .addObject(e)
          .build()
          .parse(workRequest.getArgumentsList().toArray(new String[] {}));
      e.echo();
      WorkResponse.getDefaultInstance().writeDelimitedTo(System.out);
    }
  }

  private void echo() throws IOException {
    Files.write(out, Files.readAllLines(in));
  }
}
