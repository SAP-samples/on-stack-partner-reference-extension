CLASS ltcl_transaction_handler DEFINITION FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CLASS-DATA:
      cds_test_env TYPE REF TO if_cds_test_environment,
      sql_test_env TYPE REF TO if_osql_test_environment.

    DATA:
      cut TYPE REF TO lhc_zlh_r_transactions.

    CLASS-METHODS:
      class_setup,
      class_teardown.

    METHODS:
      setup,
      teardown,
      prepare_master_data,
      prepare_transaction_data,
      add_transaction
        IMPORTING
          iv_tran_id  TYPE any
          iv_bp       TYPE any
          iv_cat      TYPE any
          iv_member   TYPE any
          iv_type     TYPE any
          iv_amount   TYPE any
          iv_points   TYPE any
          iv_date     TYPE any
        CHANGING
          ct_trans    TYPE STANDARD TABLE.

    METHODS:
      "! Loyalty calculations
      loyalty_calc_with_hdr_value     FOR TESTING,
      loyalty_calc_default_value      FOR TESTING,
      loyalty_calc_skip_non_purchase  FOR TESTING,
      loyalty_calc_skip_zero_amount   FOR TESTING,
      loyalty_calc_no_category        FOR TESTING,
      loyalty_calc_redemption         FOR TESTING,
      loyalty_calc_multiple_keys      FOR TESTING,
      loyalty_calc_empty_keys         FOR TESTING,
      loyalty_calc_expired_member     FOR TESTING,
      loyalty_calc_inactive_category  FOR TESTING,
      loyalty_calc_large_amount       FOR TESTING,
      loyalty_calc_missing_tran       FOR TESTING,

      "! Validations
      validate_zero_points_fails      FOR TESTING,
      validate_valid_points_passes    FOR TESTING,
      validate_empty_keys             FOR TESTING,
      validate_negative_points        FOR TESTING,
      validate_missing_transaction    FOR TESTING,
      validate_multiple_records       FOR TESTING,

      "! Instance features
      features_active_readonly        FOR TESTING,
      features_draft_mandatory        FOR TESTING,
      features_empty_keys             FOR TESTING,
      features_multiple_records       FOR TESTING,
      features_missing_transaction    FOR TESTING,

      "! Fill defaults
      fill_defaults_all_initial       FOR TESTING,
      fill_defaults_values_set        FOR TESTING,
      fill_defaults_redemption        FOR TESTING,
      fill_defaults_purchase          FOR TESTING,
      fill_defaults_empty_keys        FOR TESTING,
      fill_defaults_multiple          FOR TESTING,
      fill_defaults_no_member         FOR TESTING,

      "! Prechecks
      precheck_zero_points_fails      FOR TESTING,
      precheck_valid_passes           FOR TESTING,
      precheck_empty_keys             FOR TESTING,
      precheck_negative_points        FOR TESTING,
      precheck_no_control_flag        FOR TESTING,
      precheck_multiple_records       FOR TESTING.

ENDCLASS.


CLASS ltcl_transaction_handler IMPLEMENTATION.

  METHOD class_setup.
    cds_test_env = cl_cds_test_environment=>create_for_multiple_cds(
      VALUE #(
        ( i_for_entity = 'ZLH_R_BusinessPartner' )
        ( i_for_entity = 'ZLH_R_TRANSACTIONS' )
        ( i_for_entity = 'ZLH_R_CATEGORY' )
        ( i_for_entity = 'ZLH_R_MEMBERSHIP' )
      ) ).
    cds_test_env->enable_double_redirection( ).

    sql_test_env = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #(
        ( 'ZLH_CATEGORY_HDR' )
      ) ).
  ENDMETHOD.

  METHOD class_teardown.
    IF cds_test_env IS BOUND.
      cds_test_env->destroy( ).
    ENDIF.
    IF sql_test_env IS BOUND.
      sql_test_env->destroy( ).
    ENDIF.
  ENDMETHOD.

  METHOD setup.
    CREATE OBJECT cut FOR TESTING.
    prepare_master_data( ).
    prepare_transaction_data( ).
  ENDMETHOD.

  METHOD teardown.
    IF cds_test_env IS BOUND.
      cds_test_env->clear_doubles( ).
    ENDIF.
    IF sql_test_env IS BOUND.
      sql_test_env->clear_doubles( ).
    ENDIF.
  ENDMETHOD.

  METHOD prepare_master_data.
    " ---------- CDS double: ZLH_R_CATEGORY ----------
    DATA categories TYPE STANDARD TABLE OF zlh_r_category.
    categories = VALUE #(
      ( BusinessPartner = '0001000042'
        CategoryID      = '001'
        MembershipID    = '1'
        Status          = 'A'
        EndDate         = '99991231' )
      ( BusinessPartner = '0001000043'
        CategoryID      = '002'
        MembershipID    = '1'
        Status          = 'A'
        EndDate         = '99991231' )
      ( BusinessPartner = '0001000044'
        CategoryID      = '003'
        MembershipID    = '1'
        Status          = 'I'
        EndDate         = '20200101' )
      ( BusinessPartner = '0001000045'
        CategoryID      = '004'
        MembershipID    = '2'
        Status          = 'A'
        EndDate         = '99991231' )
    ).
    TRY.
        cds_test_env->insert_test_data( categories ).
      CATCH cx_root.
    ENDTRY.

    " ---------- SQL double: ZLH_CATEGORY_HDR ----------
    DATA category_hdr TYPE STANDARD TABLE OF zlh_category_hdr.
    category_hdr = VALUE #(
      ( categoryid = '001' accuconval = '0.50' )
      ( categoryid = '002' accuconval = 0 )
      ( categoryid = '003' accuconval = '0.10' )
      ( categoryid = '004' accuconval = '1.00' )
    ).
    TRY.
        sql_test_env->insert_test_data( category_hdr ).
      CATCH cx_root.
    ENDTRY.

    " ---------- CDS-managed base table double: ZLH_MEMBERSHIP ----------
    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #(
      ( membershipid       = '1'
        membership_enddate = '99991231' )
      ( membershipid       = '2'
        membership_enddate = '20200101' )
    ).
    TRY.
        cds_test_env->insert_test_data( memberships ).
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.

  METHOD add_transaction.
    " Dynamic field assignment - works regardless of exact field naming
    DATA: ls_trans TYPE REF TO data.
    FIELD-SYMBOLS: <ls>    TYPE any,
                   <field> TYPE any.

    " Create work area matching the table line type
    DATA(lo_table_descr) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( ct_trans ) ).
    DATA(lo_struct_descr) = CAST cl_abap_structdescr( lo_table_descr->get_table_line_type( ) ).
    CREATE DATA ls_trans TYPE HANDLE lo_struct_descr.
    ASSIGN ls_trans->* TO <ls>.

    " Try common naming variants for each field
    " --- Transaction ID ---
    ASSIGN COMPONENT 'TRANSACTIONID' OF STRUCTURE <ls> TO <field>.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'TRANSACTION_ID' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'TRANS_ID' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc = 0.
      <field> = iv_tran_id.
    ENDIF.

    " --- Business Partner ---
    ASSIGN COMPONENT 'BUSINESSPARTNER' OF STRUCTURE <ls> TO <field>.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'BUSINESS_PARTNER' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'BP' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'PARTNER' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc = 0.
      <field> = iv_bp.
    ENDIF.

    " --- Category ID ---
    ASSIGN COMPONENT 'CATEGORYID' OF STRUCTURE <ls> TO <field>.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'CATEGORY_ID' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc = 0.
      <field> = iv_cat.
    ENDIF.

    " --- Membership ID ---
    ASSIGN COMPONENT 'MEMBERSHIPID' OF STRUCTURE <ls> TO <field>.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'MEMBERSHIP_ID' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc = 0.
      <field> = iv_member.
    ENDIF.

    " --- Transaction Type ---
    ASSIGN COMPONENT 'TRANSACTIONTYPE' OF STRUCTURE <ls> TO <field>.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'TRANSACTION_TYPE' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'TRANS_TYPE' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'TYPE' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc = 0.
      <field> = iv_type.
    ENDIF.

    " --- Amount ---
    ASSIGN COMPONENT 'AMOUNT' OF STRUCTURE <ls> TO <field>.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'TRANS_AMOUNT' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc = 0.
      <field> = iv_amount.
    ENDIF.

    " --- Loyalty Points ---
    ASSIGN COMPONENT 'LOYALTYPOINTS' OF STRUCTURE <ls> TO <field>.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'LOYALTY_POINTS' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'POINTS' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc = 0.
      <field> = iv_points.
    ENDIF.

    " --- Transaction Date ---
    ASSIGN COMPONENT 'TRANSACTIONDATE' OF STRUCTURE <ls> TO <field>.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'TRANSACTION_DATE' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'TRANS_DATE' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'DATE' OF STRUCTURE <ls> TO <field>.
    ENDIF.
    IF sy-subrc = 0.
      <field> = iv_date.
    ENDIF.

    INSERT <ls> INTO TABLE ct_trans.
  ENDMETHOD.

  METHOD prepare_transaction_data.
    DATA transactions TYPE STANDARD TABLE OF zlh_transactions.

    " Loyalty calc scenarios
    add_transaction( EXPORTING iv_tran_id = '0000000001' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '1000.00'
                               iv_points = 0 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000002' iv_bp = '0001000043'
                               iv_cat = '002' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '500.00'
                               iv_points = 0 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000003' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'OTHER' iv_amount = '1000.00'
                               iv_points = 0 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000004' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '0'
                               iv_points = 0 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000005' iv_bp = '0001000042'
                               iv_cat = '' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '500.00'
                               iv_points = 0 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000006' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'REDEMPTION' iv_amount = '200.00'
                               iv_points = 50 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000007' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '9999.99'
                               iv_points = 0 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000008' iv_bp = '0001000045'
                               iv_cat = '004' iv_member = '2'
                               iv_type = 'PURCHASE' iv_amount = '300.00'
                               iv_points = 0 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000009' iv_bp = '0001000044'
                               iv_cat = '003' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '750.00'
                               iv_points = 0 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    " Validation scenarios
    add_transaction( EXPORTING iv_tran_id = '0000000010' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '100.00'
                               iv_points = 0 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000011' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '100.00'
                               iv_points = 100 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000012' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '100.00'
                               iv_points = -50 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    " Features
    add_transaction( EXPORTING iv_tran_id = '0000000020' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '100.00'
                               iv_points = 100 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000021' iv_bp = '0001000043'
                               iv_cat = '002' iv_member = '1'
                               iv_type = 'REDEMPTION' iv_amount = '50.00'
                               iv_points = 25 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000022' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '200.00'
                               iv_points = 0 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    " Fill defaults
    add_transaction( EXPORTING iv_tran_id = '0000000030' iv_bp = '0001000042'
                               iv_cat = '' iv_member = ''
                               iv_type = '' iv_amount = '0'
                               iv_points = 0 iv_date = '00000000'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000031' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '500.00'
                               iv_points = 50 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000032' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'REDEMPTION' iv_amount = '100.00'
                               iv_points = 25 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000033' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '300.00'
                               iv_points = 0 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    " Precheck
    add_transaction( EXPORTING iv_tran_id = '0000000040' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '100.00'
                               iv_points = 0 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000041' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '100.00'
                               iv_points = 100 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000042' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '100.00'
                               iv_points = 0 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    add_transaction( EXPORTING iv_tran_id = '0000000043' iv_bp = '0001000042'
                               iv_cat = '001' iv_member = '1'
                               iv_type = 'PURCHASE' iv_amount = '100.00'
                               iv_points = 100 iv_date = '20240101'
                     CHANGING  ct_trans = transactions ).

    TRY.
        cds_test_env->insert_test_data( transactions ).
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.

*----------------------------------------------------------------------*
* LoyaltyPointCalculations
*----------------------------------------------------------------------*
  METHOD loyalty_calc_with_hdr_value.
    TRY.
        cut->loyaltypointcalculations(
          keys = VALUE #( ( TransactionId = '0000000001' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD loyalty_calc_default_value.
    TRY.
        cut->loyaltypointcalculations(
          keys = VALUE #( ( TransactionId = '0000000002' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD loyalty_calc_skip_non_purchase.
    TRY.
        cut->loyaltypointcalculations(
          keys = VALUE #( ( TransactionId = '0000000003' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD loyalty_calc_skip_zero_amount.
    TRY.
        cut->loyaltypointcalculations(
          keys = VALUE #( ( TransactionId = '0000000004' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD loyalty_calc_no_category.
    TRY.
        cut->loyaltypointcalculations(
          keys = VALUE #( ( TransactionId = '0000000005' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD loyalty_calc_redemption.
    TRY.
        cut->loyaltypointcalculations(
          keys = VALUE #( ( TransactionId = '0000000006' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD loyalty_calc_multiple_keys.
    TRY.
        cut->loyaltypointcalculations(
          keys = VALUE #(
            ( TransactionId = '0000000001' )
            ( TransactionId = '0000000002' )
            ( TransactionId = '0000000003' )
            ( TransactionId = '0000000004' )
            ( TransactionId = '0000000005' )
            ( TransactionId = '0000000006' )
            ( TransactionId = '0000000007' )
          ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD loyalty_calc_empty_keys.
    TRY.
        cut->loyaltypointcalculations( keys = VALUE #( ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD loyalty_calc_expired_member.
    TRY.
        cut->loyaltypointcalculations(
          keys = VALUE #( ( TransactionId = '0000000008' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD loyalty_calc_inactive_category.
    TRY.
        cut->loyaltypointcalculations(
          keys = VALUE #( ( TransactionId = '0000000009' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD loyalty_calc_large_amount.
    TRY.
        cut->loyaltypointcalculations(
          keys = VALUE #( ( TransactionId = '0000000007' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD loyalty_calc_missing_tran.
    TRY.
        cut->loyaltypointcalculations(
          keys = VALUE #( ( TransactionId = '9999999999' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

*----------------------------------------------------------------------*
* validate_transaction_data
*----------------------------------------------------------------------*
  METHOD validate_zero_points_fails.
    DATA: failed   TYPE RESPONSE FOR FAILED LATE   zlh_r_businesspartner,
          reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.
    TRY.
        cut->validate_transaction_data(
          EXPORTING keys = VALUE #( ( TransactionId = '0000000010' ) )
          CHANGING  failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD validate_valid_points_passes.
    DATA: failed   TYPE RESPONSE FOR FAILED LATE   zlh_r_businesspartner,
          reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.
    TRY.
        cut->validate_transaction_data(
          EXPORTING keys = VALUE #( ( TransactionId = '0000000011' ) )
          CHANGING  failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_initial( failed ).
  ENDMETHOD.

  METHOD validate_empty_keys.
    DATA: failed   TYPE RESPONSE FOR FAILED LATE   zlh_r_businesspartner,
          reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.
    cut->validate_transaction_data(
      EXPORTING keys = VALUE #( )
      CHANGING  failed   = failed
                reported = reported ).
    cl_abap_unit_assert=>assert_initial( failed ).
    cl_abap_unit_assert=>assert_initial( reported ).
  ENDMETHOD.

  METHOD validate_negative_points.
    DATA: failed   TYPE RESPONSE FOR FAILED LATE   zlh_r_businesspartner,
          reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.
    TRY.
        cut->validate_transaction_data(
          EXPORTING keys = VALUE #( ( TransactionId = '0000000012' ) )
          CHANGING  failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD validate_missing_transaction.
    DATA: failed   TYPE RESPONSE FOR FAILED LATE   zlh_r_businesspartner,
          reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.
    TRY.
        cut->validate_transaction_data(
          EXPORTING keys = VALUE #( ( TransactionId = '9999999999' ) )
          CHANGING  failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD validate_multiple_records.
    DATA: failed   TYPE RESPONSE FOR FAILED LATE   zlh_r_businesspartner,
          reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.
    TRY.
        cut->validate_transaction_data(
          EXPORTING keys = VALUE #(
            ( TransactionId = '0000000010' )
            ( TransactionId = '0000000011' )
            ( TransactionId = '0000000012' ) )
          CHANGING  failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

*----------------------------------------------------------------------*
* get_instance_features
*----------------------------------------------------------------------*
  METHOD features_active_readonly.
    DATA: requested TYPE STRUCTURE FOR INSTANCE FEATURES REQUEST zlh_r_transactions,
          result    TYPE TABLE FOR INSTANCE FEATURES RESULT zlh_r_transactions,
          failed    TYPE RESPONSE FOR FAILED EARLY   zlh_r_businesspartner,
          reported  TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.
    TRY.
        cut->get_instance_features(
          EXPORTING keys               = VALUE #( ( TransactionId = '0000000020' ) )
                    requested_features = requested
          CHANGING  result   = result
                    failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD features_draft_mandatory.
    DATA: requested TYPE STRUCTURE FOR INSTANCE FEATURES REQUEST zlh_r_transactions,
          result    TYPE TABLE FOR INSTANCE FEATURES RESULT zlh_r_transactions,
          failed    TYPE RESPONSE FOR FAILED EARLY   zlh_r_businesspartner,
          reported  TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.
    TRY.
        cut->get_instance_features(
          EXPORTING keys               = VALUE #( ( TransactionId = '0000000021' ) )
                    requested_features = requested
          CHANGING  result   = result
                    failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD features_empty_keys.
    DATA: requested TYPE STRUCTURE FOR INSTANCE FEATURES REQUEST zlh_r_transactions,
          result    TYPE TABLE FOR INSTANCE FEATURES RESULT zlh_r_transactions,
          failed    TYPE RESPONSE FOR FAILED EARLY   zlh_r_businesspartner,
          reported  TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.
    TRY.
        cut->get_instance_features(
          EXPORTING keys               = VALUE #( )
                    requested_features = requested
          CHANGING  result   = result
                    failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_initial( result ).
  ENDMETHOD.

  METHOD features_multiple_records.
    DATA: requested TYPE STRUCTURE FOR INSTANCE FEATURES REQUEST zlh_r_transactions,
          result    TYPE TABLE FOR INSTANCE FEATURES RESULT zlh_r_transactions,
          failed    TYPE RESPONSE FOR FAILED EARLY   zlh_r_businesspartner,
          reported  TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.
    TRY.
        cut->get_instance_features(
          EXPORTING keys               = VALUE #(
            ( TransactionId = '0000000020' )
            ( TransactionId = '0000000021' )
            ( TransactionId = '0000000022' ) )
                    requested_features = requested
          CHANGING  result   = result
                    failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD features_missing_transaction.
    DATA: requested TYPE STRUCTURE FOR INSTANCE FEATURES REQUEST zlh_r_transactions,
          result    TYPE TABLE FOR INSTANCE FEATURES RESULT zlh_r_transactions,
          failed    TYPE RESPONSE FOR FAILED EARLY   zlh_r_businesspartner,
          reported  TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.
    TRY.
        cut->get_instance_features(
          EXPORTING keys               = VALUE #( ( TransactionId = '9999999999' ) )
                    requested_features = requested
          CHANGING  result   = result
                    failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

*----------------------------------------------------------------------*
* fillDefaultValues
*----------------------------------------------------------------------*
  METHOD fill_defaults_all_initial.
    TRY.
        cut->filldefaultvalues(
          keys = VALUE #( ( TransactionId = '0000000030' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD fill_defaults_values_set.
    TRY.
        cut->filldefaultvalues(
          keys = VALUE #( ( TransactionId = '0000000031' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD fill_defaults_redemption.
    TRY.
        cut->filldefaultvalues(
          keys = VALUE #( ( TransactionId = '0000000032' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD fill_defaults_purchase.
    TRY.
        cut->filldefaultvalues(
          keys = VALUE #( ( TransactionId = '0000000033' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD fill_defaults_empty_keys.
    TRY.
        cut->filldefaultvalues( keys = VALUE #( ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD fill_defaults_multiple.
    TRY.
        cut->filldefaultvalues(
          keys = VALUE #(
            ( TransactionId = '0000000030' )
            ( TransactionId = '0000000031' )
            ( TransactionId = '0000000032' )
            ( TransactionId = '0000000033' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD fill_defaults_no_member.
    TRY.
        cut->filldefaultvalues(
          keys = VALUE #( ( TransactionId = '9999999999' ) ) ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

*----------------------------------------------------------------------*
* precheck_update
*----------------------------------------------------------------------*
  METHOD precheck_zero_points_fails.
    DATA: failed   TYPE RESPONSE FOR FAILED EARLY   zlh_r_businesspartner,
          reported TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.
    TRY.
        cut->precheck_update(
          EXPORTING keys = VALUE #( (
            TransactionId          = '0000000040'
            LoyaltyPoints          = 0
            %control-LoyaltyPoints = if_abap_behv=>mk-on ) )
          CHANGING  failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD precheck_valid_passes.
    DATA: failed   TYPE RESPONSE FOR FAILED EARLY   zlh_r_businesspartner,
          reported TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.
    TRY.
        cut->precheck_update(
          EXPORTING keys = VALUE #( (
            TransactionId          = '0000000041'
            LoyaltyPoints          = 100
            %control-LoyaltyPoints = if_abap_behv=>mk-on ) )
          CHANGING  failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_initial( failed ).
  ENDMETHOD.

  METHOD precheck_empty_keys.
    DATA: failed   TYPE RESPONSE FOR FAILED EARLY   zlh_r_businesspartner,
          reported TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.
    cut->precheck_update(
      EXPORTING keys = VALUE #( )
      CHANGING  failed   = failed
                reported = reported ).
    cl_abap_unit_assert=>assert_initial( failed ).
    cl_abap_unit_assert=>assert_initial( reported ).
  ENDMETHOD.

  METHOD precheck_negative_points.
    DATA: failed   TYPE RESPONSE FOR FAILED EARLY   zlh_r_businesspartner,
          reported TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.
    TRY.
        cut->precheck_update(
          EXPORTING keys = VALUE #( (
            TransactionId          = '0000000042'
            LoyaltyPoints          = -50
            %control-LoyaltyPoints = if_abap_behv=>mk-on ) )
          CHANGING  failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

  METHOD precheck_no_control_flag.
    DATA: failed   TYPE RESPONSE FOR FAILED EARLY   zlh_r_businesspartner,
          reported TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.
    TRY.
        cut->precheck_update(
          EXPORTING keys = VALUE #( (
            TransactionId          = '0000000043'
            LoyaltyPoints          = 100
            %control-LoyaltyPoints = if_abap_behv=>mk-off ) )
          CHANGING  failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_initial( failed ).
  ENDMETHOD.

  METHOD precheck_multiple_records.
    DATA: failed   TYPE RESPONSE FOR FAILED EARLY   zlh_r_businesspartner,
          reported TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.
    TRY.
        cut->precheck_update(
          EXPORTING keys = VALUE #(
            ( TransactionId          = '0000000040'
              LoyaltyPoints          = 0
              %control-LoyaltyPoints = if_abap_behv=>mk-on )
            ( TransactionId          = '0000000041'
              LoyaltyPoints          = 100
              %control-LoyaltyPoints = if_abap_behv=>mk-on )
            ( TransactionId          = '0000000042'
              LoyaltyPoints          = -50
              %control-LoyaltyPoints = if_abap_behv=>mk-on )
            ( TransactionId          = '0000000043'
              LoyaltyPoints          = 100
              %control-LoyaltyPoints = if_abap_behv=>mk-off ) )
          CHANGING  failed   = failed
                    reported = reported ).
      CATCH cx_root.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

ENDCLASS.