*&---------------------------------------------------------------------*
*& Report ZFI_FI96_REPORT
*&---------------------------------------------------------------------*
*& Financial Document Consolidated Report
*&---------------------------------------------------------------------*

REPORT zfi_fi96_report.

TABLES: bkpf, bseg.

TYPE-POOLS: slis.

*---------------------------------------------------------------------*
* Selection Screen
*---------------------------------------------------------------------*

SELECT-OPTIONS:

  s_bukrs FOR bkpf-bukrs OBLIGATORY,
  s_gjahr FOR bkpf-gjahr OBLIGATORY,
  s_belnr FOR bkpf-belnr,
  s_budat FOR bkpf-budat,
  s_kunnr FOR bseg-kunnr,
  s_lifnr FOR bseg-lifnr.

*---------------------------------------------------------------------*
* Final Output Structure
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_final,

         bukrs      TYPE t001-bukrs,
         butxt      TYPE t001-butxt,

         belnr      TYPE bkpf-belnr,
         gjahr      TYPE bkpf-gjahr,
         blart      TYPE bkpf-blart,
         budat      TYPE bkpf-budat,

         buzei      TYPE bseg-buzei,
         koart      TYPE bseg-koart,
         shkzg      TYPE bseg-shkzg,
         dmbtr      TYPE bseg-dmbtr,

         kunnr      TYPE bseg-kunnr,
         kunn_name  TYPE kna1-name1,

         lifnr      TYPE bseg-lifnr,
         lifnr_name TYPE lfa1-name1,

         matnr      TYPE bseg-matnr,
         mtart      TYPE mara-mtart,
         maktx      TYPE makt-maktx,

       END OF ty_final.

*---------------------------------------------------------------------*
* Internal Table and Work Area
*---------------------------------------------------------------------*

DATA:

  gt_final TYPE TABLE OF ty_final,
  gs_final TYPE ty_final.

*---------------------------------------------------------------------*
* ALV Data
*---------------------------------------------------------------------*

DATA:

  gt_fieldcat TYPE slis_t_fieldcat_alv,
  gs_fieldcat TYPE slis_fieldcat_alv.

*---------------------------------------------------------------------*
* Selection Screen Validation
*---------------------------------------------------------------------*

AT SELECTION-SCREEN.

  "Validate Company Code

  SELECT SINGLE bukrs
    FROM t001
    WHERE bukrs IN @s_bukrs
    INTO @DATA(lv_bukrs).

  IF sy-subrc <> 0.

    MESSAGE 'Invalid Company Code' TYPE 'E'.

  ENDIF.


  "Validate Accounting Document

  IF s_belnr[] IS NOT INITIAL.

    SELECT SINGLE belnr
      FROM bkpf
      WHERE belnr IN @s_belnr
      INTO @DATA(lv_belnr).

    IF sy-subrc <> 0.

      MESSAGE 'Invalid Accounting Document Number' TYPE 'E'.

    ENDIF.

  ENDIF.


  "Validate Customer

  IF s_kunnr[] IS NOT INITIAL.

    SELECT SINGLE kunnr
      FROM kna1
      WHERE kunnr IN @s_kunnr
      INTO @DATA(lv_kunnr).

    IF sy-subrc <> 0.

      MESSAGE 'Invalid Customer Number' TYPE 'E'.

    ENDIF.

  ENDIF.


  "Validate Vendor

  IF s_lifnr[] IS NOT INITIAL.

    SELECT SINGLE lifnr
      FROM lfa1
      WHERE lifnr IN @s_lifnr
      INTO @DATA(lv_lifnr).

    IF sy-subrc <> 0.

      MESSAGE 'Invalid Vendor Number' TYPE 'E'.

    ENDIF.

  ENDIF.


  "Validate Posting Date

  IF s_budat[] IS NOT INITIAL.

    READ TABLE s_budat INDEX 1 INTO DATA(ls_budat).

    IF ls_budat-low IS NOT INITIAL
       AND ls_budat-high IS NOT INITIAL
       AND ls_budat-low > ls_budat-high.

      MESSAGE 'Posting Date From cannot be greater than To'
              TYPE 'E'.

    ENDIF.

  ENDIF.

* Start of Selection
*---------------------------------------------------------------------*

START-OF-SELECTION.

  PERFORM get_data.

  PERFORM get_customer_vendor.

  PERFORM display_alv.


*---------------------------------------------------------------------*
* Form GET_DATA
*---------------------------------------------------------------------*

FORM get_data.

  SELECT

    bkpf~bukrs,
    t001~butxt,
    bkpf~belnr,
    bkpf~gjahr,
    bkpf~blart,
    bkpf~budat,

    bseg~buzei,
    bseg~koart,
    bseg~shkzg,
    bseg~dmbtr,

    bseg~kunnr,
    bseg~lifnr,
    bseg~matnr,

    mara~mtart,
    makt~maktx

    FROM bkpf

    INNER JOIN bseg
      ON bkpf~bukrs = bseg~bukrs
     AND bkpf~belnr = bseg~belnr
     AND bkpf~gjahr = bseg~gjahr

    INNER JOIN t001
      ON bkpf~bukrs = t001~bukrs

    LEFT OUTER JOIN mara
      ON bseg~matnr = mara~matnr

    LEFT OUTER JOIN makt
      ON bseg~matnr = makt~matnr
     AND makt~spras = @sy-langu

    INTO CORRESPONDING FIELDS OF TABLE @gt_final

    WHERE bkpf~bukrs IN @s_bukrs
      AND bkpf~gjahr IN @s_gjahr
      AND bkpf~belnr IN @s_belnr
      AND bkpf~budat IN @s_budat
      AND bseg~kunnr IN @s_kunnr
      AND bseg~lifnr IN @s_lifnr.


  IF gt_final IS INITIAL.

    MESSAGE 'No Data Found for the Given Selection Criteria.'
            TYPE 'I'.

    RETURN.

  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
* Form GET_CUSTOMER_VENDOR
*---------------------------------------------------------------------*

FORM get_customer_vendor.

  LOOP AT gt_final INTO gs_final.

    "Customer Name

    IF gs_final-kunnr IS NOT INITIAL.

      SELECT SINGLE name1
        FROM kna1
        WHERE kunnr = @gs_final-kunnr
        INTO @gs_final-kunn_name.

    ENDIF.


    "Vendor Name

    IF gs_final-lifnr IS NOT INITIAL.

      SELECT SINGLE name1
        FROM lfa1
        WHERE lifnr = @gs_final-lifnr
        INTO @gs_final-lifnr_name.

    ENDIF.


    MODIFY gt_final FROM gs_final
      INDEX sy-tabix.

  ENDLOOP.

ENDFORM.


*---------------------------------------------------------------------*
* Form DISPLAY_ALV
*---------------------------------------------------------------------*

FORM display_alv.

*---------------------------------------------------------------------*
* Company Code
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'BUKRS'.
  gs_fieldcat-seltext_m = 'Company Code'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Company Name
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'BUTXT'.
  gs_fieldcat-seltext_m = 'Company Name'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Accounting Document
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'BELNR'.
  gs_fieldcat-seltext_m = 'Accounting Document'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Fiscal Year
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'GJAHR'.
  gs_fieldcat-seltext_m = 'Fiscal Year'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Document Type
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'BLART'.
  gs_fieldcat-seltext_m = 'Document Type'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Posting Date
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'BUDAT'.
  gs_fieldcat-seltext_m = 'Posting Date'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Line Item
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'BUZEI'.
  gs_fieldcat-seltext_m = 'Line Item'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Account Type
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'KOART'.
  gs_fieldcat-seltext_m = 'Account Type'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Debit/Credit Indicator
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'SHKZG'.
  gs_fieldcat-seltext_m = 'Debit/Credit'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Amount
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'DMBTR'.
  gs_fieldcat-seltext_m = 'Amount'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Customer Number
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'KUNNR'.
  gs_fieldcat-seltext_m = 'Customer Number'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Customer Name
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'KUNN_NAME'.
  gs_fieldcat-seltext_m = 'Customer Name'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Vendor Number
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'LIFNR'.
  gs_fieldcat-seltext_m = 'Vendor Number'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Vendor Name
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'LIFNR_NAME'.
  gs_fieldcat-seltext_m = 'Vendor Name'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Material Number
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'MATNR'.
  gs_fieldcat-seltext_m = 'Material Number'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Material Type
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'MTART'.
  gs_fieldcat-seltext_m = 'Material Type'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Material Description
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'MAKTX'.
  gs_fieldcat-seltext_m = 'Material Description'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* Display ALV
*---------------------------------------------------------------------*

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'

    EXPORTING

      i_callback_program = sy-repid

      i_grid_title =
        'Financial Document Consolidated Report'

      it_fieldcat =
        gt_fieldcat

    TABLES

      t_outtab =
        gt_final

    EXCEPTIONS

      program_error = 1
      OTHERS        = 2.


  IF sy-subrc <> 0.

    MESSAGE 'Error while displaying ALV'
            TYPE 'E'.

  ENDIF.

ENDFORM.
