package workertest;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public final class Echo {

  @Parameter(names = "--in", required = true)
  private Path in;

  @Parameter(names = "--out", required = true)
  private Path out;

  private Echo() {}

  public static void main(String[] args) throws IOException {
    Echo e = new Echo();
    JCommander.newBuilder().addObject(e).build().parse(args);
    Files.write(e.out, Files.readAllLines(e.in));
  }
}
