@AbapCatalog.sqlViewName: 'ZVFI_FIN_DOC'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Financial Document Consolidated CDS View'

define view ZFI_CDS_FIN_DOC
  as select from bkpf as h

    inner join bseg as i
      on  h.bukrs = i.bukrs
      and h.belnr = i.belnr
      and h.gjahr = i.gjahr

    inner join t001 as c
      on h.bukrs = c.bukrs

    left outer join kna1 as k
      on i.kunnr = k.kunnr

    left outer join lfa1 as v
      on i.lifnr = v.lifnr

    left outer join mara as m
      on i.matnr = m.matnr

    left outer join makt as t
      on  i.matnr = t.matnr
      and t.spras = $session.system_language

{
  key h.bukrs as CompanyCode,

  key h.belnr as AccountingDocument,

  key h.gjahr as FiscalYear,

  key i.buzei as LineItem,

      c.butxt as CompanyName,

      h.blart as DocumentType,

      h.budat as PostingDate,

      i.koart as AccountType,

      i.shkzg as DebitCreditIndicator,

      @Semantics.amount.currencyCode: 'Currency'
      i.dmbtr as Amount,

      h.waers as Currency,

      i.kunnr as CustomerNumber,

      k.name1 as CustomerName,

      i.lifnr as VendorNumber,

      v.name1 as VendorName,

      i.matnr as MaterialNumber,

      m.mtart as MaterialType,

      t.maktx as MaterialDescription
}
