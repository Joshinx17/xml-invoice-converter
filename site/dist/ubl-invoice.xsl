<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:inv="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
  xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
  xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
  exclude-result-prefixes="inv cac cbc">
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <xsl:template name="amount">
    <xsl:param name="value"/>
    <xsl:if test="normalize-space($value) != ''">
      <xsl:value-of select="format-number(number($value), '#,##0.00')"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="cac:Party" mode="address">
    <strong><xsl:value-of select="cac:PartyName/cbc:Name"/></strong>
    <div><xsl:value-of select="cac:PostalAddress/cbc:StreetName"/></div>
    <div>
      <xsl:value-of select="cac:PostalAddress/cbc:CityName"/>
      <xsl:if test="cac:PostalAddress/cbc:CityName and cac:PostalAddress/cac:Country/cbc:IdentificationCode">, </xsl:if>
      <xsl:value-of select="cac:PostalAddress/cac:Country/cbc:IdentificationCode"/>
    </div>
    <div class="trn">TRN: <xsl:value-of select="cac:PartyTaxScheme/cbc:CompanyID"/></div>
  </xsl:template>

  <xsl:template match="/">
    <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
    <html lang="en">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title>Invoice <xsl:value-of select="inv:Invoice/cbc:ID"/></title>
        <style>
          * { box-sizing: border-box; }
          body { margin: 0; background: #edf1f5; color: #243040; font: 15px/1.5 Arial, Helvetica, sans-serif; }
          .page { max-width: 820px; margin: 36px auto; padding: 48px; background: #fff; box-shadow: 0 8px 30px rgba(24, 42, 61, .12); }
          .header { display: flex; justify-content: space-between; gap: 30px; align-items: flex-start; border-bottom: 3px solid #19344f; padding-bottom: 24px; }
          h1 { margin: 0; color: #19344f; font-size: 36px; letter-spacing: .08em; }
          .meta { text-align: right; }
          .meta div { margin-bottom: 3px; }
          .label { color: #657284; }
          .parties { display: grid; grid-template-columns: 1fr 1fr; gap: 36px; margin: 32px 0 36px; }
          h2 { margin: 0 0 10px; color: #657284; font-size: 12px; letter-spacing: .12em; text-transform: uppercase; }
          .parties strong { display: block; margin-bottom: 4px; font-size: 17px; color: #19344f; }
          .trn { margin-top: 8px; }
          table { width: 100%; border-collapse: collapse; }
          th { padding: 12px 9px; background: #19344f; color: white; font-size: 12px; text-align: left; }
          td { padding: 13px 9px; border-bottom: 1px solid #dce3ea; vertical-align: top; }
          .number { text-align: right; white-space: nowrap; }
          .totals { width: min(100%, 370px); margin: 26px 0 0 auto; }
          .totals td { padding: 8px 6px; border-bottom: 0; }
          .totals .total td { border-top: 2px solid #19344f; padding-top: 14px; color: #19344f; font-weight: bold; font-size: 19px; }
          footer { margin-top: 55px; padding-top: 18px; border-top: 1px solid #dce3ea; color: #657284; font-size: 12px; }
          @media (max-width: 600px) { .page { margin: 0; padding: 24px; } .header { display: block; } .meta { text-align: left; margin-top: 12px; } .parties { grid-template-columns: 1fr; gap: 22px; } table { font-size: 12px; } th, td { padding-left: 5px; padding-right: 5px; } }
          @media print { @page { margin: 0; } body { background: white; } .page { max-width: none; margin: 0; box-shadow: none; } thead { display: table-header-group; } tr { break-inside: avoid; } }
        </style>
      </head>
      <body>
        <div class="page">
          <xsl:for-each select="inv:Invoice">
            <div class="header">
              <h1>INVOICE</h1>
              <div class="meta">
                <div><span class="label">Invoice # </span><strong><xsl:value-of select="cbc:ID"/></strong></div>
                <div><span class="label">Issue date: </span><xsl:value-of select="cbc:IssueDate"/></div>
                <div><span class="label">Type: </span><xsl:value-of select="cbc:InvoiceTypeCode"/></div>
                <div><span class="label">Currency: </span><xsl:value-of select="cbc:DocumentCurrencyCode"/></div>
              </div>
            </div>
            <div class="parties">
              <section><h2>From</h2><xsl:apply-templates select="cac:AccountingSupplierParty/cac:Party" mode="address"/></section>
              <section><h2>Bill to</h2><xsl:apply-templates select="cac:AccountingCustomerParty/cac:Party" mode="address"/></section>
            </div>
            <table class="items">
              <thead><tr><th>#</th><th>Description</th><th class="number">Qty</th><th class="number">Unit price</th><th class="number">VAT %</th><th class="number">Amount</th></tr></thead>
              <tbody>
                <xsl:for-each select="cac:InvoiceLine">
                  <tr>
                    <td><xsl:value-of select="position()"/></td>
                    <td><xsl:value-of select="cac:Item/cbc:Name"/></td>
                    <td class="number"><xsl:value-of select="cbc:InvoicedQuantity"/></td>
                    <td class="number"><xsl:call-template name="amount"><xsl:with-param name="value" select="cac:Price/cbc:PriceAmount"/></xsl:call-template></td>
                    <td class="number"><xsl:value-of select="cac:Item/cac:ClassifiedTaxCategory/cbc:Percent"/></td>
                    <td class="number"><xsl:call-template name="amount"><xsl:with-param name="value" select="cbc:LineExtensionAmount"/></xsl:call-template></td>
                  </tr>
                </xsl:for-each>
              </tbody>
            </table>
            <table class="totals">
              <tbody>
                <xsl:for-each select="cac:TaxTotal/cac:TaxSubtotal">
                  <tr><td>Taxable at <xsl:value-of select="cac:TaxCategory/cbc:Percent"/>%</td><td class="number"><xsl:call-template name="amount"><xsl:with-param name="value" select="cbc:TaxableAmount"/></xsl:call-template></td></tr>
                </xsl:for-each>
                <tr><td>Subtotal</td><td class="number"><xsl:call-template name="amount"><xsl:with-param name="value" select="cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount"/></xsl:call-template></td></tr>
                <tr><td>VAT</td><td class="number"><xsl:call-template name="amount"><xsl:with-param name="value" select="cac:TaxTotal/cbc:TaxAmount"/></xsl:call-template></td></tr>
                <tr class="total"><td>Total due</td><td class="number"><xsl:call-template name="amount"><xsl:with-param name="value" select="cac:LegalMonetaryTotal/cbc:PayableAmount"/></xsl:call-template><xsl:text> </xsl:text><xsl:value-of select="cbc:DocumentCurrencyCode"/></td></tr>
              </tbody>
            </table>
          </xsl:for-each>
          <footer>Thank you for your business. Please retain this invoice for your records.</footer>
        </div>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
