import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

/** Renders one UBL invoice, or a folder of invoices, with a reusable XSLT transformer. */
public class InvoiceRenderer {
    public static void main(String[] args) {
        System.exit(run(args));
    }

    private static int run(String[] args) {
        if (args.length != 3) {
            usage();
            return 1;
        }

        Path input = Path.of(args[0]);
        Path stylesheet = Path.of(args[1]);
        Path outputFolder = Path.of(args[2]);
        if (!Files.isRegularFile(input) && !Files.isDirectory(input)) {
            System.err.println("Input does not exist or is not a file or folder: " + input);
            usage();
            return 1;
        }
        if (!Files.isRegularFile(stylesheet)) {
            System.err.println("Stylesheet does not exist or is not a file: " + stylesheet);
            usage();
            return 1;
        }

        List<Path> invoices = new ArrayList<>();
        try {
            if (Files.isDirectory(input)) {
                // Only direct children matching *.xml are rendered, in stable name order.
                try (var paths = Files.list(input)) {
                    paths.filter(Files::isRegularFile)
                            .filter(path -> path.getFileName().toString().endsWith(".xml"))
                            .sorted(Comparator.comparing(path -> path.getFileName().toString()))
                            .forEach(invoices::add);
                }
            } else {
                invoices.add(input);
            }
            Files.createDirectories(outputFolder);
        } catch (IOException error) {
            System.err.println("Could not prepare input or output: " + error.getMessage());
            return 1;
        }

        final Transformer transformer;
        try {
            transformer = TransformerFactory.newInstance()
                    .newTransformer(new StreamSource(stylesheet.toFile()));
        } catch (Exception error) {
            System.err.println("Could not load stylesheet " + stylesheet + ": " + error.getMessage());
            return 1;
        }

        boolean failed = false;
        for (Path invoice : invoices) {
            String name = invoice.getFileName().toString();
            int dot = name.lastIndexOf('.');
            String baseName = dot < 0 ? name : name.substring(0, dot);
            Path output = outputFolder.resolve(baseName + ".html");
            try (InputStream xml = Files.newInputStream(invoice);
                    OutputStream html = Files.newOutputStream(output)) {
                transformer.clearParameters();
                transformer.transform(new StreamSource(xml), new StreamResult(html));
                System.out.println("Rendered " + output);
            } catch (Exception error) {
                System.err.println("Failed to render " + invoice + ": " + error.getMessage());
                failed = true;
                // A failed transform may have written an incomplete HTML file.
                try {
                    Files.deleteIfExists(output);
                } catch (IOException cleanupError) {
                    System.err.println("Could not remove incomplete output " + output + ": "
                            + cleanupError.getMessage());
                }
            }
        }
        return failed ? 1 : 0;
    }

    private static void usage() {
        System.err.println("Usage: java InvoiceRenderer <invoice.xml | folder> <stylesheet.xsl> <output folder>");
    }
}
