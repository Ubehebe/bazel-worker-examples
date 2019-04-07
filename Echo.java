package workertest;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.google.devtools.build.lib.worker.WorkerProtocol.WorkRequest;
import com.google.devtools.build.lib.worker.WorkerProtocol.WorkResponse;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public final class Echo {

  @Parameter(names = "--in")
  private Path in;

  @Parameter(names = "--out")
  private Path out;

  @Parameter(names = "--persistent_worker")
  private boolean worker;

  private Echo() {}

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

  public static void main(String[] args) throws IOException {
    Echo e = new Echo();
    JCommander.newBuilder().addObject(e).build().parse(args);
    if (e.worker) {
      workerMain();
    } else {
      e.echo();
    }
  }

  private void echo() throws IOException {
    Files.write(out, Files.readAllLines(in));
  }
}
