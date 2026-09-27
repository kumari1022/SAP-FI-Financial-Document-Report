REPORT zfi_fi96_report_oo.

TABLES: bkpf, bseg.

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

PARAMETERS:
  p_amount TYPE bseg-dmbtr DEFAULT 100000.

*---------------------------------------------------------------------*
* Local Class Definition
*---------------------------------------------------------------------*

CLASS lcl_report DEFINITION.

  PUBLIC SECTION.

    METHODS:
      get_data,
      get_customer_vendor,
      calculate_summary,
      display_summary,
      display_high_value,
      display_exceptions,
      display_alv.

  PRIVATE SECTION.

    TYPES:

      BEGIN OF ty_final,

        bukrs       TYPE t001-bukrs,
        butxt       TYPE t001-butxt,

        belnr       TYPE bkpf-belnr,
        gjahr       TYPE bkpf-gjahr,
        blart       TYPE bkpf-blart,
        budat       TYPE bkpf-budat,

        buzei       TYPE bseg-buzei,
        koart       TYPE bseg-koart,
        shkzg       TYPE bseg-shkzg,
        dmbtr       TYPE bseg-dmbtr,

        kunnr       TYPE bseg-kunnr,
        kunn_name   TYPE kna1-name1,

        lifnr       TYPE bseg-lifnr,
        lifnr_name  TYPE lfa1-name1,

        matnr       TYPE bseg-matnr,
        mtart       TYPE mara-mtart,
        maktx       TYPE makt-maktx,

        high_value  TYPE char3,
        issue       TYPE char255,

      END OF ty_final.

    TYPES:

      BEGIN OF ty_doc_key,
        bukrs TYPE bkpf-bukrs,
        belnr TYPE bkpf-belnr,
        gjahr TYPE bkpf-gjahr,
      END OF ty_doc_key.

    DATA:
      gt_data TYPE TABLE OF ty_final,
      gs_data TYPE ty_final.

    DATA:
      gv_total_documents TYPE i,
      gv_total_records   TYPE i,
      gv_total_amount    TYPE bseg-dmbtr,
      gv_debit_amount    TYPE bseg-dmbtr,
      gv_credit_amount   TYPE bseg-dmbtr,
      gv_debit_count     TYPE i,
      gv_credit_count    TYPE i,
      gv_high_value      TYPE i,
      gv_exceptions      TYPE i.

    DATA:
      go_alv TYPE REF TO cl_salv_table.

ENDCLASS.

*---------------------------------------------------------------------*
* Selection Screen Validation
*---------------------------------------------------------------------*

AT SELECTION-SCREEN.

  DATA:
    lv_bukrs TYPE t001-bukrs,
    lv_belnr TYPE bkpf-belnr,
    lv_kunnr TYPE kna1-kunnr,
    lv_lifnr TYPE lfa1-lifnr.

  IF s_budat[] IS NOT INITIAL.

    LOOP AT s_budat ASSIGNING FIELD-SYMBOL(<ls_date>).

      IF <ls_date>-low IS NOT INITIAL
         AND <ls_date>-high IS NOT INITIAL
         AND <ls_date>-low > <ls_date>-high.

        MESSAGE
          'Posting Date From cannot be greater than To'
          TYPE 'E'.

      ENDIF.

    ENDLOOP.

  ENDIF.

  IF s_bukrs[] IS NOT INITIAL.

    READ TABLE s_bukrs INDEX 1
      ASSIGNING FIELD-SYMBOL(<ls_bukrs>).

    IF sy-subrc = 0.

      lv_bukrs = <ls_bukrs>-low.

      SELECT SINGLE bukrs
        FROM t001
        WHERE bukrs = @lv_bukrs
        INTO @DATA(lv_check_bukrs).

      IF sy-subrc <> 0.

        MESSAGE
          'Invalid Company Code'
          TYPE 'E'.

      ENDIF.

    ENDIF.

  ENDIF.

  IF s_belnr[] IS NOT INITIAL.

    READ TABLE s_belnr INDEX 1
      ASSIGNING FIELD-SYMBOL(<ls_belnr>).

    IF sy-subrc = 0.

      lv_belnr = <ls_belnr>-low.

      SELECT SINGLE belnr
        FROM bkpf
        WHERE belnr IN @s_belnr
          AND bukrs IN @s_bukrs
          AND gjahr IN @s_gjahr
        INTO @DATA(lv_check_belnr).

      IF sy-subrc <> 0.

        MESSAGE
          'Accounting Document not found'
          TYPE 'E'.

      ENDIF.

    ENDIF.

  ENDIF.

  IF s_kunnr[] IS NOT INITIAL.

    READ TABLE s_kunnr INDEX 1
      ASSIGNING FIELD-SYMBOL(<ls_kunnr>).

    IF sy-subrc = 0.

      lv_kunnr = <ls_kunnr>-low.

      SELECT SINGLE kunnr
        FROM kna1
        WHERE kunnr = @lv_kunnr
        INTO @DATA(lv_check_kunnr).

      IF sy-subrc <> 0.

        MESSAGE
          'Invalid Customer Number'
          TYPE 'E'.

      ENDIF.

    ENDIF.

  ENDIF.

  IF s_lifnr[] IS NOT INITIAL.

    READ TABLE s_lifnr INDEX 1
      ASSIGNING FIELD-SYMBOL(<ls_lifnr>).

    IF sy-subrc = 0.

      lv_lifnr = <ls_lifnr>-low.

      SELECT SINGLE lifnr
        FROM lfa1
        WHERE lifnr = @lv_lifnr
        INTO @DATA(lv_check_lifnr).

      IF sy-subrc <> 0.

        MESSAGE
          'Invalid Vendor Number'
          TYPE 'E'.

      ENDIF.

    ENDIF.

  ENDIF.

*---------------------------------------------------------------------*
* Class Implementation
*---------------------------------------------------------------------*

CLASS lcl_report IMPLEMENTATION.

*---------------------------------------------------------------------*
* Get Main Data
*---------------------------------------------------------------------*

  METHOD get_data.

    CLEAR gt_data.

    SELECT
      h~bukrs,
      c~butxt,
      h~belnr,
      h~gjahr,
      h~blart,
      h~budat,

      i~buzei,
      i~koart,
      i~shkzg,
      i~dmbtr,

      i~kunnr,
      k~name1 AS kunn_name,

      i~lifnr,
      v~name1 AS lifnr_name,

      i~matnr,
      m~mtart,
      t~maktx

      FROM bkpf AS h

      INNER JOIN bseg AS i
        ON h~bukrs = i~bukrs
       AND h~belnr = i~belnr
       AND h~gjahr = i~gjahr

      INNER JOIN t001 AS c
        ON h~bukrs = c~bukrs

      LEFT OUTER JOIN kna1 AS k
        ON i~kunnr = k~kunnr

      LEFT OUTER JOIN lfa1 AS v
        ON i~lifnr = v~lifnr

      LEFT OUTER JOIN mara AS m
        ON i~matnr = m~matnr

      LEFT OUTER JOIN makt AS t
        ON i~matnr = t~matnr
       AND t~spras = @sy-langu

      WHERE h~bukrs IN @s_bukrs
        AND h~gjahr IN @s_gjahr
        AND h~belnr IN @s_belnr
        AND h~budat IN @s_budat
        AND i~kunnr IN @s_kunnr
        AND i~lifnr IN @s_lifnr

      INTO CORRESPONDING FIELDS OF TABLE @gt_data.

    IF gt_data IS INITIAL.

      MESSAGE
        'No Data Found for the Given Selection Criteria.'
        TYPE 'I'.

      RETURN.

    ENDIF.

  ENDMETHOD.

*---------------------------------------------------------------------*
* Customer / Vendor / Material Analysis
*---------------------------------------------------------------------*

  METHOD get_customer_vendor.

    LOOP AT gt_data ASSIGNING FIELD-SYMBOL(<ls_data>).

      CLEAR:
        <ls_data>-high_value,
        <ls_data>-issue.

*---------------------------------------------------------------------*
* High Value Transaction
*---------------------------------------------------------------------*

      IF p_amount > 0
         AND <ls_data>-dmbtr >= p_amount.

        <ls_data>-high_value = 'YES'.

        gv_high_value = gv_high_value + 1.

      ELSE.

        <ls_data>-high_value = 'NO'.

      ENDIF.

*---------------------------------------------------------------------*
* Data Quality Checks
*---------------------------------------------------------------------*

      IF <ls_data>-koart = 'D'
         AND <ls_data>-kunnr IS INITIAL.

        <ls_data>-issue =
          'Customer Number Missing'.

      ENDIF.

      IF <ls_data>-koart = 'K'
         AND <ls_data>-lifnr IS INITIAL.

        IF <ls_data>-issue IS INITIAL.

          <ls_data>-issue =
            'Vendor Number Missing'.

        ELSE.

          CONCATENATE
            <ls_data>-issue
            ' | Vendor Number Missing'
            INTO <ls_data>-issue.

        ENDIF.

      ENDIF.

      IF <ls_data>-dmbtr = 0.

        IF <ls_data>-issue IS INITIAL.

          <ls_data>-issue =
            'Zero Amount'.

        ELSE.

          CONCATENATE
            <ls_data>-issue
            ' | Zero Amount'
            INTO <ls_data>-issue.

        ENDIF.

      ENDIF.

      IF <ls_data>-matnr IS NOT INITIAL
         AND <ls_data>-maktx IS INITIAL.

        IF <ls_data>-issue IS INITIAL.

          <ls_data>-issue =
            'Material Description Missing'.

        ELSE.

          CONCATENATE
            <ls_data>-issue
            ' | Material Description Missing'
            INTO <ls_data>-issue.

        ENDIF.

      ENDIF.

      IF <ls_data>-issue IS NOT INITIAL.

        gv_exceptions = gv_exceptions + 1.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

*---------------------------------------------------------------------*
* Calculate Financial Summary
*---------------------------------------------------------------------*

  METHOD calculate_summary.

    DATA:
      lt_doc_keys TYPE HASHED TABLE OF ty_doc_key
                  WITH UNIQUE KEY bukrs belnr gjahr,

      ls_doc_key TYPE ty_doc_key.

    CLEAR:
      gv_total_documents,
      gv_total_records,
      gv_total_amount,
      gv_debit_amount,
      gv_credit_amount,
      gv_debit_count,
      gv_credit_count.

    gv_total_records = lines( gt_data ).

    LOOP AT gt_data INTO DATA(ls_data).

      gv_total_amount =
        gv_total_amount + ls_data-dmbtr.

      CLEAR ls_doc_key.

      ls_doc_key-bukrs = ls_data-bukrs.
      ls_doc_key-belnr = ls_data-belnr.
      ls_doc_key-gjahr = ls_data-gjahr.

      INSERT ls_doc_key INTO TABLE lt_doc_keys.

      IF ls_data-shkzg = 'S'.

        gv_debit_amount =
          gv_debit_amount + ls_data-dmbtr.

        gv_debit_count =
          gv_debit_count + 1.

      ELSEIF ls_data-shkzg = 'H'.

        gv_credit_amount =
          gv_credit_amount + ls_data-dmbtr.

        gv_credit_count =
          gv_credit_count + 1.

      ENDIF.

    ENDLOOP.

    gv_total_documents = lines( lt_doc_keys ).

  ENDMETHOD.

*---------------------------------------------------------------------*
* Display Financial Summary
*---------------------------------------------------------------------*

  METHOD display_summary.

    DATA:
      lo_summary TYPE REF TO cl_salv_table.

    TYPES:
      BEGIN OF ty_summary,

        total_documents TYPE i,
        total_line_items TYPE i,
        total_amount TYPE bseg-dmbtr,
        debit_amount TYPE bseg-dmbtr,
        credit_amount TYPE bseg-dmbtr,
        debit_count TYPE i,
        credit_count TYPE i,
        high_value_count TYPE i,
        exception_count TYPE i,

      END OF ty_summary.

    DATA:
      gt_summary TYPE TABLE OF ty_summary,
      gs_summary TYPE ty_summary.

    gs_summary-total_documents =
      gv_total_documents.

    gs_summary-total_line_items =
      gv_total_records.

    gs_summary-total_amount =
      gv_total_amount.

    gs_summary-debit_amount =
      gv_debit_amount.

    gs_summary-credit_amount =
      gv_credit_amount.

    gs_summary-debit_count =
      gv_debit_count.

    gs_summary-credit_count =
      gv_credit_count.

    gs_summary-high_value_count =
      gv_high_value.

    gs_summary-exception_count =
      gv_exceptions.

    APPEND gs_summary TO gt_summary.

    TRY.

        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lo_summary
          CHANGING
            t_table      = gt_summary ).

        lo_summary->get_columns( )->set_optimize(
          abap_true ).

        lo_summary->get_display_settings( )->set_list_header(
          'Financial Summary' ).

        lo_summary->get_functions( )->set_all(
          abap_true ).

        lo_summary->display( ).

      CATCH cx_salv_msg INTO DATA(lx_error).

        MESSAGE lx_error->get_text( ) TYPE 'I'.

    ENDTRY.

  ENDMETHOD.

*---------------------------------------------------------------------*
* High Value Transactions
*---------------------------------------------------------------------*

  METHOD display_high_value.

    DATA:
      lt_high_value TYPE TABLE OF ty_final,
      lo_high       TYPE REF TO cl_salv_table.

    LOOP AT gt_data INTO DATA(ls_data).

      IF ls_data-high_value = 'YES'.

        APPEND ls_data TO lt_high_value.

      ENDIF.

    ENDLOOP.

    IF lt_high_value IS INITIAL.

      MESSAGE
        'No High Value Transactions Found'
        TYPE 'I'.

      RETURN.

    ENDIF.

    TRY.

        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lo_high
          CHANGING
            t_table      = lt_high_value ).

        lo_high->get_columns( )->set_optimize(
          abap_true ).

        lo_high->get_display_settings( )->set_list_header(
          'High Value Transactions' ).

        lo_high->get_functions( )->set_all(
          abap_true ).

        lo_high->display( ).

      CATCH cx_salv_msg INTO DATA(lx_error).

        MESSAGE lx_error->get_text( ) TYPE 'I'.

    ENDTRY.

  ENDMETHOD.

*---------------------------------------------------------------------*
* Exception / Data Quality Report
*---------------------------------------------------------------------*

  METHOD display_exceptions.

    DATA:
      lt_exception TYPE TABLE OF ty_final,
      lo_exception TYPE REF TO cl_salv_table.

    LOOP AT gt_data INTO DATA(ls_data).

      IF ls_data-issue IS NOT INITIAL.

        APPEND ls_data TO lt_exception.

      ENDIF.

    ENDLOOP.

    IF lt_exception IS INITIAL.

      MESSAGE
        'No Data Quality Exceptions Found'
        TYPE 'I'.

      RETURN.

    ENDIF.

    TRY.

        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lo_exception
          CHANGING
            t_table      = lt_exception ).

        lo_exception->get_columns( )->set_optimize(
          abap_true ).

        lo_exception->get_display_settings( )->set_list_header(
          'Exception / Data Quality Report' ).

        lo_exception->get_functions( )->set_all(
          abap_true ).

        lo_exception->display( ).

      CATCH cx_salv_msg INTO DATA(lx_error).

        MESSAGE lx_error->get_text( ) TYPE 'I'.

    ENDTRY.

  ENDMETHOD.

*---------------------------------------------------------------------*
* Main Detailed ALV
*---------------------------------------------------------------------*

  METHOD display_alv.

    DATA:
      lo_columns TYPE REF TO cl_salv_columns_table.

    IF gt_data IS INITIAL.

      MESSAGE
        'No Data Found for the Given Selection Criteria.'
        TYPE 'I'.

      RETURN.

    ENDIF.

    TRY.

        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = go_alv
          CHANGING
            t_table      = gt_data ).

        lo_columns =
          go_alv->get_columns( ).

        lo_columns->set_optimize(
          abap_true ).

        go_alv->get_functions( )->set_all(
          abap_true ).

        go_alv->get_display_settings( )->set_list_header(
          'Financial Document Consolidated Report' ).

        go_alv->display( ).

      CATCH cx_salv_msg INTO DATA(lx_error).

        MESSAGE lx_error->get_text( ) TYPE 'I'.

    ENDTRY.

  ENDMETHOD.

ENDCLASS.

*---------------------------------------------------------------------*
* Start of Selection
*---------------------------------------------------------------------*

DATA go_report TYPE REF TO lcl_report.

START-OF-SELECTION.

  CREATE OBJECT go_report.

  go_report->get_data( ).

  go_report->get_customer_vendor( ).

  go_report->calculate_summary( ).

  go_report->display_summary( ).

  go_report->display_high_value( ).

  go_report->display_exceptions( ).

  go_report->display_alv( ).
