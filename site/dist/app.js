const fileInput = document.getElementById('file-input');
const drop = document.getElementById('drop');
const filesList = document.getElementById('files');
const count = document.getElementById('count');
const stage = document.getElementById('stage');
const previewName = document.getElementById('preview-name');
const downloadButton = document.getElementById('download');
const printButton = document.getElementById('print');
const invoices = [];
let selected = -1;
let processorPromise;

function parseXml(text, name) {
  const document = new DOMParser().parseFromString(text, 'application/xml');
  const error = document.getElementsByTagName('parsererror')[0];
  if (error) throw new Error(`${name}: ${error.textContent.trim().split('\n')[0]}`);
  if (document.documentElement.namespaceURI !== 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2' || document.documentElement.localName !== 'Invoice') {
    throw new Error(`${name}: Expected a UBL 2.1 Invoice XML document.`);
  }
  return document;
}

async function getProcessor() {
  if (!('XSLTProcessor' in window)) throw new Error('This browser does not support XSLT. Try a current Chrome, Edge, Firefox, or Safari browser.');
  if (!processorPromise) processorPromise = fetch('ubl-invoice.xsl').then(response => {
    if (!response.ok) throw new Error('Could not load the invoice stylesheet.');
    return response.text();
  }).then(text => {
    const stylesheet = parseXmlStylesheet(text);
    const processor = new XSLTProcessor();
    processor.importStylesheet(stylesheet);
    return processor;
  });
  return processorPromise;
}

function parseXmlStylesheet(text) {
  const document = new DOMParser().parseFromString(text, 'application/xml');
  if (document.getElementsByTagName('parsererror').length) throw new Error('The invoice stylesheet is invalid XML.');
  return document;
}

async function renderInvoice(text, name) {
  const xml = parseXml(text, name);
  const processor = await getProcessor();
  processor.clearParameters();
  const result = processor.transformToDocument(xml);
  if (!result || !result.documentElement) throw new Error(`${name}: The stylesheet produced no invoice.`);
  return '<!doctype html>\n' + result.documentElement.outerHTML;
}

function showFiles() {
  count.textContent = invoices.length;
  filesList.replaceChildren();
  if (!invoices.length) {
    const empty = document.createElement('li'); empty.className = 'empty'; empty.textContent = 'No invoices added yet.'; filesList.append(empty); return;
  }
  invoices.forEach((invoice, index) => {
    const item = document.createElement('li');
    const button = document.createElement('button'); button.type = 'button'; button.className = index === selected ? 'active' : '';
    const dot = document.createElement('span'); dot.className = 'status-dot' + (invoice.error ? ' error' : '');
    const name = document.createElement('span'); name.className = 'file-name'; name.textContent = invoice.name;
    button.append(dot, name); button.addEventListener('click', () => selectInvoice(index)); item.append(button);
    if (invoice.error) { const error = document.createElement('p'); error.className = 'error-text'; error.textContent = invoice.error; item.append(error); }
    filesList.append(item);
  });
}

function selectInvoice(index) {
  selected = index; showFiles();
  const invoice = invoices[index];
  previewName.textContent = invoice.name;
  downloadButton.disabled = printButton.disabled = Boolean(invoice.error);
  stage.replaceChildren();
  if (invoice.error) {
    const error = document.createElement('div'); error.className = 'error-panel'; error.textContent = invoice.error; stage.append(error);
  } else {
    const frame = document.createElement('iframe'); frame.title = `Preview of ${invoice.name}`; frame.setAttribute('sandbox', 'allow-same-origin allow-modals'); frame.srcdoc = invoice.html; stage.append(frame);
  }
}

async function addFiles(files) {
  const xmlFiles = Array.from(files).filter(file => file.name.toLowerCase().endsWith('.xml'));
  for (const file of xmlFiles) {
    let invoice;
    try { invoice = { name: file.name, html: await renderInvoice(await file.text(), file.name) }; }
    catch (error) { invoice = { name: file.name, error: error.message || 'Could not render this invoice.' }; }
    invoices.push(invoice);
  }
  if (xmlFiles.length) selectInvoice(invoices.length - xmlFiles.length);
}

fileInput.addEventListener('change', event => { addFiles(event.target.files); fileInput.value = ''; });
for (const eventName of ['dragenter', 'dragover']) drop.addEventListener(eventName, event => { event.preventDefault(); drop.classList.add('drag'); });
for (const eventName of ['dragleave', 'drop']) drop.addEventListener(eventName, event => { event.preventDefault(); drop.classList.remove('drag'); });
drop.addEventListener('drop', event => addFiles(event.dataTransfer.files));
document.getElementById('sample').addEventListener('click', async () => {
  try { const response = await fetch('sample-invoice.xml'); if (!response.ok) throw new Error('Could not load the sample invoice.'); await addFiles([new File([await response.blob()], 'sample-invoice.xml', { type: 'application/xml' })]); }
  catch (error) { stage.innerHTML = ''; const message = document.createElement('div'); message.className = 'error-panel'; message.textContent = error.message; stage.append(message); }
});
downloadButton.addEventListener('click', () => {
  const invoice = invoices[selected]; if (!invoice || invoice.error) return;
  const url = URL.createObjectURL(new Blob([invoice.html], { type: 'text/html;charset=utf-8' }));
  const link = document.createElement('a'); link.href = url; link.download = invoice.name.replace(/\.xml$/i, '') + '.html'; link.click();
  setTimeout(() => URL.revokeObjectURL(url), 60000);
});
printButton.addEventListener('click', () => { const frame = stage.querySelector('iframe'); if (frame) frame.contentWindow.print(); });
