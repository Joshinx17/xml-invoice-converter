# invoice-viewer

A small JDK-only renderer for UBL 2.1 invoices in PINT AE / Peppol style. It produces printable HTML with an XSLT 1.0 stylesheet. Java 11 or newer is required.

## Compile and render

Open `invoice-viewer` in VS Code. In the integrated terminal, run:

```sh
javac -d out src/InvoiceRenderer.java
java -cp out InvoiceRenderer invoices stylesheets/ubl-invoice.xsl output
```

The rendered file is `output/sample-invoice.html`. You can pass a single XML file instead of `invoices` to render just that file. When given a folder, the renderer processes its `*.xml` files in name order and continues after a file fails.

## Use the website

The `site/` directory contains a browser version of the viewer. Open the published Invoice Viewer site, choose one or more UBL XML files, or select **Try the sample invoice**. Select an invoice in the list to preview it, then use **Download HTML** or **Print / Save PDF**. Rendering happens in your browser; selected invoice files are not uploaded. The website includes a copy of `stylesheets/ubl-invoice.xsl` for browser rendering.

Open the HTML file in a browser. To save a PDF, press Ctrl+P (Cmd+P on macOS), choose **Save as PDF**, and enable **Background graphics**.

The HTML is a human-readable copy, not a legal e-invoice. Preserve and submit the original UBL XML for e-invoicing workflows.

## XML validation in VS Code

Install the Red Hat XML extension, then extract the OASIS UBL 2.1 schema package under `ubl/` so that `ubl/xsd/maindoc/UBL-Invoice-2.1.xsd` exists. `.vscode/settings.json` associates XML files in `invoices/` with that schema.
