# SAP FI - Financial Document Consolidated Report

## Overview

This project implements a custom SAP ABAP Financial Document Consolidated Report using standard SAP FI and master data tables.

The report consolidates financial document header, line-item, company code, customer, vendor, and material information into an ALV-based output.
## Technologies

- SAP ABAP
- SAP FI
- Eclipse ADT
- SQL
- Function ALV
- Object-Oriented ALV
- ABAP CDS
- OData V4
- SAP Fiori Elements
- SAP Fiori Elements integration was prepared through CDS, OData Service Definition, and OData V4 Service Binding. Browser-based Fiori preview was not included in the final implementation due to environment connectivity limitations.
## Features

- Mandatory Company Code and Fiscal Year selection
- Optional Accounting Document, Posting Date, Customer, and Vendor filters
- Selection-screen validations
- Financial document data retrieval
- Company code information
- Customer information
- Vendor information
- Material information
- Function ALV output
- Object-Oriented ALV output
- Financial summary
- Debit/Credit analysis
- High-value transaction analysis
- Exception/data-quality handling
- ABAP CDS view
- OData V4 Service Definition
- OData V4 Service Binding
## SAP Tables Used

| Table | Purpose |
|---|---|
| BKPF | Financial Document Header |
| BSEG | Financial Document Line Items |
| T001 | Company Code |
| KNA1 | Customer Master |
| LFA1 | Vendor Master |
| MARA | Material Master |
| MAKT | Material Description |
## Architecture

BKPF
BSEG
T001
KNA1
LFA1
MARA
MAKT
   |
   v
ZFI_FI96_REPORT
   |
   +--> Function ALV

ZFI_FI96_REPORT_OO
   |
   +--> OO ALV
   +--> Financial Summary
   +--> Debit/Credit Analysis
   +--> Exception Handling

Standard SAP Tables
   |
   v
ZFI_CDS_FIN_DOC
   |
   v
ZFI_SD_FIN_DOC
   |
   v
ZFI_SB_FIN_DOC
   |
   v
OData V4
   |
   v
Fiori Elements
