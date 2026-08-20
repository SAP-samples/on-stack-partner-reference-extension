*CLASS ltcl_giftcard_handler DEFINITION DEFERRED FOR TESTING.
CLASS zcl_lh_giftcard DEFINITION LOCAL FRIENDS ltcl_giftcard_handler.

CLASS ltcl_giftcard_handler DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PUBLIC SECTION.
    METHODS:
      " setGiftcardBalanceOnCreate
      set_balance_on_create          FOR TESTING,
      set_balance_skip_when_zero     FOR TESTING,
      " setGiftcardFieldsOnCreate
      set_fields_on_create           FOR TESTING,
      " validateGiftCardFields
      validate_fails_initial_value   FOR TESTING,
      validate_fails_negative_value  FOR TESTING,
      validate_fails_empty_desc      FOR TESTING,
      validate_passes_valid_data     FOR TESTING,
      validate_reports_multi_errors  FOR TESTING,
      " precheck_update
      precheck_fails_zero_value      FOR TESTING,
      precheck_fails_negative_value  FOR TESTING,
      precheck_fails_exceeds_max     FOR TESTING,
      precheck_fails_low_points      FOR TESTING,
      precheck_passes_valid          FOR TESTING,
      " validateGiftcardBalance
      balance_fails_exceeds_points   FOR TESTING,
      balance_passes_within_points   FOR TESTING,
      balance_multi_gc_same_bp       FOR TESTING,
      " get_instance_features
      features_new_gc_mandatory      FOR TESTING RAISING cx_static_check,
      features_active_gc_readonly    FOR TESTING RAISING cx_static_check.

  PRIVATE SECTION.
    DATA: mo_cut TYPE REF TO lhc_zlh_r_giftcard.
    CLASS-DATA: go_cds_test_environment TYPE REF TO if_cds_test_environment,
                go_sql_test_environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.
ENDCLASS.


CLASS ltcl_giftcard_handler IMPLEMENTATION.

  METHOD class_setup.
    go_cds_test_environment = cl_cds_test_environment=>create_for_multiple_cds(
      VALUE #( ( i_for_entity = 'ZLH_R_BusinessPartner' i_select_base_dependencies = abap_false )
               ( i_for_entity = 'ZLH_R_GIFTCARD' )
               ( i_for_entity = 'ZLH_R_Membership' )
               ( i_for_entity = 'I_SalesOrder' ) ) ).
    go_cds_test_environment->enable_double_redirection( ).

    " Uncomment and adjust if zcl_lh_loyalty_points=>get_points reads from a custom table
    " go_sql_test_environment = cl_osql_test_environment=>create(
    "   i_dependency_list = VALUE #( ( 'ZLH_LOYALTY_POINTS' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    IF go_cds_test_environment IS BOUND.
      go_cds_test_environment->destroy( ).
    ENDIF.
    IF go_sql_test_environment IS BOUND.
      go_sql_test_environment->destroy( ).
    ENDIF.
  ENDMETHOD.

  METHOD setup.

    CREATE OBJECT mo_cut FOR TESTING.

    DATA giftcards TYPE STANDARD TABLE OF zlh_giftcard.
    giftcards = VALUE #(
      ( GiftcardNumber  = '00000001'
        business_partner = '0001000042'
        giftcard_value   = 100
        giftcard_balance = 0
        sap_description  = 'Test Gift Card'
        giftcard_status  = ' '
        giftcard_currency = ' ' )
    ).
    go_cds_test_environment->insert_test_data( i_data = giftcards ).

    DATA business_partners TYPE STANDARD TABLE OF I_BusinessPartner.
    business_partners = VALUE #( ( BusinessPartner = '0001000042' ) ).
    go_cds_test_environment->insert_test_data( i_data = business_partners ).

    DATA soldtoparty TYPE STANDARD TABLE OF ZLH_I_SoldToParty.
    soldtoparty = VALUE #( ( SoldToParty = '0001000042' ) ).

    go_cds_test_environment->insert_test_data( i_data = soldtoparty ).
  ENDMETHOD.

  METHOD teardown.
    IF go_cds_test_environment IS BOUND.
      go_cds_test_environment->clear_doubles( ).
    ENDIF.
    IF go_sql_test_environment IS BOUND.
      go_sql_test_environment->clear_doubles( ).
    ENDIF.
  ENDMETHOD.


  "=========================================================================
  " setGiftcardBalanceOnCreate - DETERMINE ON MODIFY
  " Balance must be set equal to GiftcardValue when value is not initial
  "=========================================================================

  METHOD set_balance_on_create.
    " Arrange: giftcard with value 100 already in CDS double (from setup)
    " Act: call determination

    mo_cut->setgiftcardbalanceoncreate(
      keys = VALUE #( ( GiftcardNumber = '00000001'
                        %is_draft      = if_abap_behv=>mk-off ) )
    ).
*    mo_cut=>
*     =>setgiftcardbalanceoncreate(
*      keys = VALUE #( ( GiftcardNumber = '00000001'
*                        %is_draft      = if_abap_behv=>mk-off ) )
*    ).

    " Assert: read entity to verify balance was set
    READ ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
      ENTITY zlh_r_giftcard
      FIELDS ( GiftcardBalance )
      WITH VALUE #( ( GiftcardNumber = '00000001'
                      %is_draft      = if_abap_behv=>mk-off ) )
      RESULT DATA(result).

    cl_abap_unit_assert=>assert_not_initial( act = result msg = 'Entity should be readable' ).
    cl_abap_unit_assert=>assert_equals(
      exp = CONV zlh_giftcardamt( 100 )
      act = result[ 1 ]-GiftcardBalance
      msg = 'GiftcardBalance must equal GiftcardValue (100)' ).
  ENDMETHOD.


  METHOD set_balance_skip_when_zero.
    " Arrange: insert giftcard with value = 0
    go_cds_test_environment->clear_doubles( ).
    DATA giftcards TYPE STANDARD TABLE OF zlh_giftcard.
    giftcards = VALUE #(
      ( GiftcardNumber  = '00000002'
        business_partner = '0001000042'
        giftcard_value   = 0
        giftcard_balance = 0
        sap_description  = 'Zero Value Card' )
    ).
    go_cds_test_environment->insert_test_data( i_data = giftcards ).

    " Act
    mo_cut->setgiftcardbalanceoncreate(
      keys = VALUE #( ( GiftcardNumber = '00000002'
                        %is_draft      = if_abap_behv=>mk-off ) )
    ).

    " Assert: balance must remain 0
    READ ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
      ENTITY zlh_r_giftcard
      FIELDS ( GiftcardBalance )
      WITH VALUE #( ( GiftcardNumber = '00000002'
                      %is_draft      = if_abap_behv=>mk-off ) )
      RESULT DATA(result).

    cl_abap_unit_assert=>assert_equals(
      exp = CONV zlh_giftcardamt( 0 )
      act = result[ 1 ]-GiftcardBalance
      msg = 'GiftcardBalance must remain 0 when GiftcardValue is initial' ).
  ENDMETHOD.


  "=========================================================================
  " setGiftcardFieldsOnCreate - DETERMINE ON MODIFY
  " Must set: GiftcardStatus = active, GiftcardCurrency = default, CreatedOn = sysdate
  "=========================================================================

  METHOD set_fields_on_create.
    " Act
    mo_cut->setgiftcardfieldsoncreate(
      keys = VALUE #( ( GiftcardNumber = '00000001'
                        %is_draft      = if_abap_behv=>mk-off ) )
    ).

    " Assert: read entity to verify defaults
    READ ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
      ENTITY zlh_r_giftcard
      FIELDS ( GiftcardStatus GiftcardCurrency CreatedOn )
      WITH VALUE #( ( GiftcardNumber = '00000001'
                      %is_draft      = if_abap_behv=>mk-off ) )
      RESULT DATA(result).

    cl_abap_unit_assert=>assert_not_initial( act = result msg = 'Entity should be readable' ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_lh_constants=>giftcard_status-active
      act = result[ 1 ]-GiftcardStatus
      msg = 'GiftcardStatus must be ACTIVE after create' ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_lh_constants=>default_currency
      act = result[ 1 ]-GiftcardCurrency
      msg = 'GiftcardCurrency must be default currency after create' ).
    cl_abap_unit_assert=>assert_equals(
      exp = cl_abap_context_info=>get_system_date( )
      act = result[ 1 ]-CreatedOn
      msg = 'CreatedOn must be system date after create' ).
  ENDMETHOD.


  "=========================================================================
  " validateGiftCardFields - VALIDATE ON SAVE
  " Must fail when: GiftcardValue IS INITIAL, GiftcardValue LE 0, SapDescription IS INITIAL
  " Messages: 006 = value initial, 013 = value <= 0, 007 = description empty
  "=========================================================================

  METHOD validate_fails_initial_value.
    DATA failed   TYPE RESPONSE FOR FAILED LATE zlh_r_businesspartner.
    DATA reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.

    " Arrange: insert giftcard with value = 0 (initial)
    go_cds_test_environment->clear_doubles( ).
    DATA giftcards TYPE STANDARD TABLE OF zlh_giftcard.
    giftcards = VALUE #(
      ( GiftcardNumber = '00001005' business_partner = '0001000042'
        giftcard_value = 0 sap_description = 'Valid Descp' ) ).
    go_cds_test_environment->insert_test_data( i_data = giftcards ).

    " Act
    mo_cut->validategiftcardfields(
      EXPORTING keys = VALUE #( ( GiftcardNumber = '00001005'
                                  %is_draft      = if_abap_behv=>mk-off ) )
      CHANGING  failed   = failed
                reported = reported ).

    " Assert
    cl_abap_unit_assert=>assert_not_initial(
      act = failed-zlh_r_giftcard
      msg = 'Expected failure when GiftcardValue is initial' ).
    cl_abap_unit_assert=>assert_equals(
      act = reported-zlh_r_giftcard[ 1 ]-%msg->if_t100_message~t100key-msgno
      exp = '006'
      msg = 'Expected message 006 for initial GiftcardValue' ).
  ENDMETHOD.


  METHOD validate_fails_negative_value.
    DATA failed   TYPE RESPONSE FOR FAILED LATE zlh_r_businesspartner.
    DATA reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.

    " Arrange: giftcard with negative value
    go_cds_test_environment->clear_doubles( ).
    DATA giftcards TYPE STANDARD TABLE OF zlh_giftcard.
    giftcards = VALUE #(
      ( GiftcardNumber = '00001003' business_partner = '0001000042'
        Giftcard_Value = -50 sap_description = 'Valid Description' ) ).
    go_cds_test_environment->insert_test_data( i_data = giftcards ).

    " Act
    mo_cut->validategiftcardfields(
      EXPORTING keys = VALUE #( ( GiftcardNumber = '00001003'
                                  %is_draft      = if_abap_behv=>mk-off ) )
      CHANGING  failed   = failed
                reported = reported ).

    " Assert
    cl_abap_unit_assert=>assert_not_initial(
      act = failed-zlh_r_giftcard
      msg = 'Expected failure for negative GiftcardValue' ).
    cl_abap_unit_assert=>assert_equals(
      act = reported-zlh_r_giftcard[ 1 ]-%msg->if_t100_message~t100key-msgno
      exp = '013'
      msg = 'Expected message 013 for negative GiftcardValue' ).
  ENDMETHOD.


  METHOD validate_fails_empty_desc.
    DATA failed   TYPE RESPONSE FOR FAILED LATE zlh_r_businesspartner.
    DATA reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.

    " Arrange: giftcard with valid value but empty description
    go_cds_test_environment->clear_doubles( ).
    DATA giftcards TYPE STANDARD TABLE OF zlh_giftcard.
    giftcards = VALUE #(
      ( GiftcardNumber = '00001001' business_partner = '0001000042'
        giftcard_value = 100 sap_description = '' ) ).
    go_cds_test_environment->insert_test_data( i_data = giftcards ).

    " Act
    mo_cut->validategiftcardfields(
      EXPORTING keys = VALUE #( ( GiftcardNumber = '00001001'
                                  %is_draft      = if_abap_behv=>mk-off ) )
      CHANGING  failed   = failed
                reported = reported ).

    " Assert
    cl_abap_unit_assert=>assert_not_initial(
      act = failed-zlh_r_giftcard
      msg = 'Expected failure when SapDescription is empty' ).
    cl_abap_unit_assert=>assert_equals(
      act = reported-zlh_r_giftcard[ 1 ]-%msg->if_t100_message~t100key-msgno
      exp = '007'
      msg = 'Expected message 007 for empty SapDescription' ).
  ENDMETHOD.


  METHOD validate_passes_valid_data.
    DATA failed   TYPE RESPONSE FOR FAILED LATE zlh_r_businesspartner.
    DATA reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.

    " Arrange: giftcard with valid value and description (from setup)

    " Act
    mo_cut->validategiftcardfields(
      EXPORTING keys = VALUE #( ( GiftcardNumber = '00000001'
                                  %is_draft      = if_abap_behv=>mk-off ) )
      CHANGING  failed   = failed
                reported = reported ).

    " Assert
    cl_abap_unit_assert=>assert_initial(
      act = failed
      msg = 'No failure expected for valid gift card fields' ).
    cl_abap_unit_assert=>assert_initial(
      act = reported
      msg = 'No messages expected for valid gift card fields' ).
  ENDMETHOD.


  METHOD validate_reports_multi_errors.
    DATA failed   TYPE RESPONSE FOR FAILED LATE zlh_r_businesspartner.
    DATA reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.

    " Arrange: both GiftcardValue = 0 AND SapDescription = ''
    go_cds_test_environment->clear_doubles( ).
    DATA giftcards TYPE STANDARD TABLE OF zlh_giftcard.
    giftcards = VALUE #(
      ( GiftcardNumber = '00000001' business_partner = '0001000042'
        Giftcard_Value = 0 sap_description = '' ) ).
    go_cds_test_environment->insert_test_data( i_data = giftcards ).

    " Act
    mo_cut->validategiftcardfields(
      EXPORTING keys = VALUE #( ( GiftcardNumber = '00000001'
                                  %is_draft      = if_abap_behv=>mk-off ) )
      CHANGING  failed   = failed
                reported = reported ).

  ENDMETHOD.


  "=========================================================================
  " precheck_update - PRECHECK for UPDATE
  " Messages: 013 = value <= 0, 015 = exceeds max, 002 = exceeds points
  "=========================================================================

  METHOD precheck_fails_zero_value.
    DATA failed   TYPE RESPONSE FOR FAILED EARLY zlh_r_businesspartner.
    DATA reported TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.

    " Act: update GiftcardValue = 0
    mo_cut->precheck_update(
      EXPORTING keys = VALUE #( (
        GiftcardNumber         = '00000001'
        %is_draft              = if_abap_behv=>mk-off
        GiftcardValue          = 0
        %control-GiftcardValue = if_abap_behv=>mk-on ) )
      CHANGING  failed   = failed
                reported = reported ).

    " Assert
    cl_abap_unit_assert=>assert_not_initial(
      act = failed-zlh_r_giftcard
      msg = 'Expected failure for zero GiftcardValue' ).
    cl_abap_unit_assert=>assert_equals(
      act = reported-zlh_r_giftcard[ 1 ]-%msg->if_t100_message~t100key-msgno
      exp = '013'
      msg = 'Expected message 013 for value <= 0' ).
  ENDMETHOD.


  METHOD precheck_fails_negative_value.
    DATA failed   TYPE RESPONSE FOR FAILED EARLY zlh_r_businesspartner.
    DATA reported TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.

    " Act: update GiftcardValue = -50
    mo_cut->precheck_update(
      EXPORTING keys = VALUE #( (
        GiftcardNumber         = '00000001'
        %is_draft              = if_abap_behv=>mk-off
        GiftcardValue          = -50
        %control-GiftcardValue = if_abap_behv=>mk-on ) )
      CHANGING  failed   = failed
                reported = reported ).

    " Assert
    cl_abap_unit_assert=>assert_not_initial(
      act = failed-zlh_r_giftcard
      msg = 'Expected failure for negative GiftcardValue' ).
    cl_abap_unit_assert=>assert_equals(
      act = reported-zlh_r_giftcard[ 1 ]-%msg->if_t100_message~t100key-msgno
      exp = '013'
      msg = 'Expected message 013 for value <= 0' ).
  ENDMETHOD.


  METHOD precheck_fails_exceeds_max.
    DATA failed   TYPE RESPONSE FOR FAILED EARLY zlh_r_businesspartner.
    DATA reported TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.

    DATA(lv_exceeding_value) = zif_lh_constants=>max_giftcard_value.

    " Act: update GiftcardValue exceeding max
    mo_cut->precheck_update(
      EXPORTING keys = VALUE #( (
        GiftcardNumber         = '00001'
        %is_draft              = if_abap_behv=>mk-off
        GiftcardValue          = lv_exceeding_value
        %control-GiftcardValue = if_abap_behv=>mk-on ) )
      CHANGING  failed   = failed
                reported = reported ).

    " Assert
    cl_abap_unit_assert=>assert_not_initial(
      act = failed-zlh_r_giftcard
      msg = 'Expected failure when GiftcardValue exceeds max' ).
    cl_abap_unit_assert=>assert_equals(
      act = reported-zlh_r_giftcard[ 1 ]-%msg->if_t100_message~t100key-msgno
      exp = '015'
      msg = 'Expected message 015 for value exceeding max_giftcard_value' ).
  ENDMETHOD.


  METHOD precheck_fails_low_points.
    DATA failed   TYPE RESPONSE FOR FAILED EARLY zlh_r_businesspartner.
    DATA reported TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.

    " Arrange: insert giftcard with associated BP that has low loyalty points
    " NOTE: This test requires mocking zcl_lh_loyalty_points=>get_points.
    " If it reads from a DB table, insert mock data into go_sql_test_environment:
    "   DATA loyalty_points TYPE STANDARD TABLE OF zlh_loyalty_points.
    "   loyalty_points = VALUE #( ( business_partner = '0001000042' available = 50 ) ).
    "   go_sql_test_environment->insert_test_data( i_data = loyalty_points ).

    " Act: request 100 points but only 50 available
    mo_cut->precheck_update(
      EXPORTING keys = VALUE #( (
        GiftcardNumber         = '00000001'
        %is_draft              = if_abap_behv=>mk-off
        GiftcardValue          = 100
        %control-GiftcardValue = if_abap_behv=>mk-on ) )
      CHANGING  failed   = failed
                reported = reported ).

    " Assert
    cl_abap_unit_assert=>assert_not_initial(
      act = failed-zlh_r_giftcard
      msg = 'Expected failure when GiftcardValue exceeds available loyalty points' ).
    cl_abap_unit_assert=>assert_equals(
      act = reported-zlh_r_giftcard[ 1 ]-%msg->if_t100_message~t100key-msgno
      exp = '002'
      msg = 'Expected message 002 for insufficient loyalty points' ).
  ENDMETHOD.


  METHOD precheck_passes_valid.
    DATA failed   TYPE RESPONSE FOR FAILED EARLY zlh_r_businesspartner.
    DATA reported TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.

    " Arrange: ensure BP has sufficient loyalty points (>= GiftcardValue)
    " NOTE: Requires mocking zcl_lh_loyalty_points=>get_points.
    "   DATA loyalty_points TYPE STANDARD TABLE OF zlh_loyalty_points.
    "   loyalty_points = VALUE #( ( business_partner = '0001000042' available = 500 ) ).
    "   go_sql_test_environment->insert_test_data( i_data = loyalty_points ).

    " Act: valid value within max and within available points
    mo_cut->precheck_update(
      EXPORTING keys = VALUE #( (
        GiftcardNumber         = '00000001'
        %is_draft              = if_abap_behv=>mk-off
        GiftcardValue          = 100
        %control-GiftcardValue = if_abap_behv=>mk-on ) )
      CHANGING  failed   = failed
                reported = reported ).

  ENDMETHOD.


  "=========================================================================
  " validateGiftcardBalance - VALIDATE ON SAVE
  " Validates total requested amount per BP against available loyalty points.
  " Message 002: total value exceeds available points
  "=========================================================================

  METHOD balance_fails_exceeds_points.
    DATA failed   TYPE RESPONSE FOR FAILED LATE zlh_r_businesspartner.
    DATA reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.

    " Arrange: giftcard value = 500, but only 200 loyalty points available
    go_cds_test_environment->clear_doubles( ).
    DATA giftcards TYPE STANDARD TABLE OF zlh_giftcard.
    giftcards = VALUE #(
      ( GiftcardNumber = '00000001' business_partner = '0001000042'
        giftcard_value = 500 ) ).
    go_cds_test_environment->insert_test_data( i_data = giftcards ).

    " NOTE: Mock loyalty points to return available = 200
    "   DATA loyalty_points TYPE STANDARD TABLE OF zlh_loyalty_points.
    "   loyalty_points = VALUE #( ( business_partner = '0001000042' available = 200 ) ).
    "   go_sql_test_environment->insert_test_data( i_data = loyalty_points ).

    " Act
    mo_cut->validategiftcardbalance(
      EXPORTING keys = VALUE #( ( GiftcardNumber = '00000001'
                                  %is_draft      = if_abap_behv=>mk-off ) )
      CHANGING  failed   = failed
                reported = reported ).

    " Assert
    cl_abap_unit_assert=>assert_not_initial(
      act = failed-zlh_r_giftcard
      msg = 'Expected failure when total value exceeds available points' ).
    cl_abap_unit_assert=>assert_equals(
      act = reported-zlh_r_giftcard[ 1 ]-%msg->if_t100_message~t100key-msgno
      exp = '002'
      msg = 'Expected message 002 for insufficient loyalty points' ).
  ENDMETHOD.


  METHOD balance_passes_within_points.
    DATA failed   TYPE RESPONSE FOR FAILED LATE zlh_r_businesspartner.
    DATA reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.

    " Arrange: giftcard value = 100, available points = 500
    " NOTE: Mock loyalty points to return available = 500
    "   DATA loyalty_points TYPE STANDARD TABLE OF zlh_loyalty_points.
    "   loyalty_points = VALUE #( ( business_partner = '0001000042' available = 500 ) ).
    "   go_sql_test_environment->insert_test_data( i_data = loyalty_points ).

    " Act
    mo_cut->validategiftcardbalance(
      EXPORTING keys = VALUE #( ( GiftcardNumber = '00000001'
                                  %is_draft      = if_abap_behv=>mk-off ) )
      CHANGING  failed   = failed
                reported = reported ).

  ENDMETHOD.


  METHOD balance_multi_gc_same_bp.
    DATA failed   TYPE RESPONSE FOR FAILED LATE zlh_r_businesspartner.
    DATA reported TYPE RESPONSE FOR REPORTED LATE zlh_r_businesspartner.

    " Arrange: two gift cards for the same BP, combined total exceeds points
    " GC1 = 300, GC2 = 300, total = 600 but available = 500
    go_cds_test_environment->clear_doubles( ).
    DATA giftcards TYPE STANDARD TABLE OF zlh_giftcard.
    giftcards = VALUE #(
      ( GiftcardNumber = '00000001' business_partner = '0001000042' giftcard_value = 300 )
      ( GiftcardNumber = '00000002' business_partner = '0001000042' giftcard_value = 300 ) ).
    go_cds_test_environment->insert_test_data( i_data = giftcards ).

    " NOTE: Mock loyalty points to return available = 500
    "   DATA loyalty_points TYPE STANDARD TABLE OF zlh_loyalty_points.
    "   loyalty_points = VALUE #( ( business_partner = '0001000042' available = 500 ) ).
    "   go_sql_test_environment->insert_test_data( i_data = loyalty_points ).

    " Act: validate both cards in one call
    mo_cut->validategiftcardbalance(
      EXPORTING keys = VALUE #( ( GiftcardNumber = '00000001' %is_draft = if_abap_behv=>mk-off )
                                ( GiftcardNumber = '00000002' %is_draft = if_abap_behv=>mk-off ) )
      CHANGING  failed   = failed
                reported = reported ).

    " Assert: both entries must appear in failed
    cl_abap_unit_assert=>assert_not_initial(
      act = failed-zlh_r_giftcard
      msg = 'Expected failure when combined total exceeds available points' ).
    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lines( failed-zlh_r_giftcard )
      msg = 'Both gift cards must appear in failed table' ).
    " Error message should be reported only ONCE per BP
    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( reported-zlh_r_giftcard )
      msg = 'Only one error message per Business Partner expected' ).
  ENDMETHOD.


  "=========================================================================
  " get_instance_features - INSTANCE FEATURES
  " GiftcardCurrency: always READ_ONLY
  " GiftcardValue: MANDATORY for new (no active record), READ_ONLY for active
  "=========================================================================

  METHOD features_new_gc_mandatory.
    " Arrange: no active record exists for this giftcard number
    go_cds_test_environment->clear_doubles( ).
    " Leave CDS double empty so the READ for active keys returns nothing

    DATA lt_keys              TYPE TABLE FOR INSTANCE FEATURES KEY zlh_r_businesspartner\\zlh_r_giftcard.
    DATA lt_requested_features TYPE STRUCTURE FOR INSTANCE FEATURES REQUEST zlh_r_businesspartner\\zlh_r_giftcard.
    DATA lt_result            TYPE TABLE FOR INSTANCE FEATURES RESULT zlh_r_businesspartner\\zlh_r_giftcard.
    DATA ls_failed            TYPE RESPONSE FOR FAILED EARLY zlh_r_businesspartner.
    DATA ls_reported          TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.

    lt_keys = VALUE #( ( GiftcardNumber = '001' %is_draft = if_abap_behv=>mk-on ) ).

    " Act
    mo_cut->get_instance_features(
      EXPORTING keys               = lt_keys
                requested_features = lt_requested_features
      CHANGING  result             = lt_result
                failed             = ls_failed
                reported           = ls_reported ).

    " Assert: GiftcardValue must be MANDATORY, GiftcardCurrency must be READ_ONLY
    cl_abap_unit_assert=>assert_initial( act = ls_failed msg = 'No failure expected' ).
    cl_abap_unit_assert=>assert_not_initial( act = lt_result msg = 'Result must not be empty' ).
    cl_abap_unit_assert=>assert_equals(
      exp = if_abap_behv=>fc-f-mandatory
      act = lt_result[ 1 ]-%features-%field-GiftcardValue
      msg = 'GiftcardValue must be MANDATORY for a new gift card' ).
    cl_abap_unit_assert=>assert_equals(
      exp = if_abap_behv=>fc-f-read_only
      act = lt_result[ 1 ]-%features-%field-GiftcardCurrency
      msg = 'GiftcardCurrency must always be READ_ONLY' ).
  ENDMETHOD.


  METHOD features_active_gc_readonly.
    " Arrange: active record exists for this giftcard number (from setup data)

    DATA lt_keys              TYPE TABLE FOR INSTANCE FEATURES KEY zlh_r_businesspartner\\zlh_r_giftcard.
    DATA lt_requested_features TYPE STRUCTURE FOR INSTANCE FEATURES REQUEST zlh_r_businesspartner\\zlh_r_giftcard.
    DATA lt_result            TYPE TABLE FOR INSTANCE FEATURES RESULT zlh_r_businesspartner\\zlh_r_giftcard.
    DATA ls_failed            TYPE RESPONSE FOR FAILED EARLY zlh_r_businesspartner.
    DATA ls_reported          TYPE RESPONSE FOR REPORTED EARLY zlh_r_businesspartner.

    lt_keys = VALUE #( ( GiftcardNumber = '00000001' %is_draft = if_abap_behv=>mk-on ) ).

    " Act
    mo_cut->get_instance_features(
      EXPORTING keys               = lt_keys
                requested_features = lt_requested_features
      CHANGING  result             = lt_result
                failed             = ls_failed
                reported           = ls_reported ).

    " Assert: GiftcardValue must be READ_ONLY for existing active card
    cl_abap_unit_assert=>assert_initial( act = ls_failed msg = 'No failure expected' ).
    cl_abap_unit_assert=>assert_not_initial( act = lt_result msg = 'Result must not be empty' ).
    cl_abap_unit_assert=>assert_equals(
      exp = if_abap_behv=>fc-f-read_only
      act = lt_result[ 1 ]-%features-%field-GiftcardValue
      msg = 'GiftcardValue must be READ_ONLY for an existing active gift card' ).
    cl_abap_unit_assert=>assert_equals(
      exp = if_abap_behv=>fc-f-read_only
      act = lt_result[ 1 ]-%features-%field-GiftcardCurrency
      msg = 'GiftcardCurrency must always be READ_ONLY' ).
  ENDMETHOD.

ENDCLASS.