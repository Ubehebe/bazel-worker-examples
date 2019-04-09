package workertest;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.converters.FileConverter;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

public final class Echo {

  @Parameter(names = "--input", required = true, converter = FileConverter.class)
  private File input;

  private Echo() {}

  public static void main(String[] args) throws IOException {
    Echo e = new Echo();
    JCommander.newBuilder().addObject(e).build().parse(args);
    Files.readAllLines(e.input.toPath()).forEach(System.out::println);
  }
}
