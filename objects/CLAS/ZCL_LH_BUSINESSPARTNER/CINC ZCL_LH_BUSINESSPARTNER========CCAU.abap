*CLASS ltcl_bp_behavior_handler DEFINITION DEFERRED FOR TESTING.
CLASS zcl_lh_businesspartner DEFINITION LOCAL FRIENDS ltcl_bp_behavior_handler.
CLASS zcl_lh_businesspartner DEFINITION LOCAL FRIENDS ltcl_category_behavior_handler.

CLASS ltcl_bp_behavior_handler DEFINITION  FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PUBLIC SECTION.
    METHODS:
      verify_membership_num FOR TESTING,
      get_features          FOR TESTING RAISING cx_static_check,
      create_membership FOR TESTING,
      delete_membership FOR TESTING.

  PRIVATE SECTION.
    DATA: mo_cut TYPE REF TO lhc_BusinessPartner.
    CLASS-DATA: go_cds_test_environment TYPE REF TO       if_cds_test_environment,
                go_test_environment               TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.
ENDCLASS.

CLASS ltcl_bp_behavior_handler IMPLEMENTATION.
  METHOD class_setup.

*    go_test_environment = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'BUT000' ) ) ).
    go_cds_test_environment = cl_cds_test_environment=>create_for_multiple_cds( VALUE #( ( i_for_entity = 'ZLH_R_BusinessPartner' )
                                                                                         ( i_for_entity = 'ZLH_R_Membership' )
                                                                                         ( i_for_entity = 'I_SalesOrder' )
                                                                                          ) ).
    go_cds_test_environment->enable_double_redirection( ).
  ENDMETHOD.

  METHOD class_teardown.
    IF go_cds_test_environment IS BOUND.
      go_cds_test_environment->destroy( ).
    ENDIF.
    IF go_test_environment IS BOUND.
      go_test_environment->destroy( ).
    ENDIF.
  ENDMETHOD.

  METHOD setup.
    CREATE OBJECT mo_cut FOR TESTING.
    DATA: business_partner TYPE STANDARD TABLE OF I_BusinessPartner,
          salesorder TYPE STANDARD TABLE OF I_SalesDocument.

    business_partner = VALUE #( ( BusinessPartner = '0001000042' ) ).
    go_cds_test_environment->insert_test_data( i_data = business_partner ).

    salesorder = VALUE #( ( SalesDocument = '0001000042' ) ).
    go_cds_test_environment->insert_test_data( i_data = salesorder ).

  ENDMETHOD.

  METHOD teardown.
    IF go_cds_test_environment IS BOUND.
      go_cds_test_environment->clear_doubles( ).
    ENDIF.
    IF go_test_environment IS BOUND.           " <-- add
      go_test_environment->clear_doubles( ).
    ENDIF.
  ENDMETHOD.

  METHOD verify_membership_num.
    DATA mapped   TYPE RESPONSE FOR MAPPED EARLY   ZLH_R_BusinessPartner.
    DATA failed   TYPE RESPONSE FOR FAILED EARLY   ZLH_R_BusinessPartner.
    DATA reported TYPE RESPONSE FOR REPORTED EARLY ZLH_R_BusinessPartner.
    DATA mapped_expected LIKE mapped.

    mo_cut->earlynumbering_cba_membership( EXPORTING entities =
                                      VALUE #( ( SoldToParty = '0000000001' %target = VALUE #( ( %cid = 'CID1' BusinessPartner = '0000000001'  ) ) ) )
                                      CHANGING mapped = mapped
                                               failed = failed
                                               reported = reported  ).

    cl_abap_unit_assert=>assert_initial( failed ).
    cl_abap_unit_assert=>assert_initial( reported ).



*    mapped_expected-zlh_r_membership = VALUE #( ( %cid = '1'  = '0001000042'  ) )

  ENDMETHOD.

  METHOD get_features.

    DATA: lt_data     TYPE TABLE FOR CREATE ZLH_R_BusinessPartner,
          lt_data_mem TYPE TABLE FOR CREATE ZLH_R_BusinessPartner\_MemberShip.


    "Features keys and parameters declaration
    DATA: lt_keys                   TYPE TABLE FOR INSTANCE FEATURES KEY ZLH_R_BusinessPartner\\ZLH_R_BusinessPartner,
          lt_requested_features     TYPE STRUCTURE FOR INSTANCE FEATURES REQUEST ZLH_R_BusinessPartner\\ZLH_R_BusinessPartner,
          ls_result                 TYPE TABLE FOR INSTANCE FEATURES RESULT ZLH_R_BusinessPartner\\ZLH_R_BusinessPartner,
          ls_mapped                 TYPE RESPONSE FOR MAPPED EARLY ZLH_R_BusinessPartner,
          ls_mapped_upgrade_version TYPE RESPONSE FOR MAPPED EARLY ZLH_R_BusinessPartner,
          ls_failed                 TYPE RESPONSE FOR FAILED EARLY ZLH_R_BusinessPartner,
          ls_reported               TYPE RESPONSE FOR REPORTED EARLY ZLH_R_BusinessPartner.

*    lt_data = VALUE #( ( %cid = 'CID1' SoldToParty = '0000000001' ) ).
    lt_data_mem = VALUE #( ( SoldToParty = '0001000042'
                             %target = VALUE #( ( %cid = 'CIDMEM1'
                                                %data-MembershipStatus = zif_lh_constants=>membership_status-active
                                                %control = VALUE #( MembershipStatus = if_abap_behv=>mk-on ) ) ) ) ).

    MODIFY ENTITIES OF ZLH_R_BusinessPartner
    ENTITY ZLH_R_BusinessPartner
    CREATE BY \_MemberShip
    FROM lt_data_mem
            MAPPED ls_mapped.

    mo_cut->get_instance_features( EXPORTING keys               = lt_keys
                                  requested_features = lt_requested_features
                        CHANGING  result             = ls_result
                                  failed             = ls_failed
                                  reported           = ls_reported ).

  ENDMETHOD.

  METHOD create_membership.
     DATA: result   TYPE TABLE FOR ACTION RESULT ZLH_R_BusinessPartner~createMembership,
           mapped   TYPE RESPONSE FOR MAPPED EARLY ZLH_R_BusinessPartner,
           failed   TYPE RESPONSE FOR FAILED EARLY ZLH_R_BusinessPartner,
           reported TYPE RESPONSE FOR REPORTED EARLY ZLH_R_BusinessPartner.


    mo_cut->createmembership( EXPORTING keys = VALUE #( (  %cid_ref = '0001000042'  SoldToParty = '0001000042' %is_draft = '01' ) )
                               CHANGING  result   = result
                                         mapped   = mapped
                                         failed   = failed
                                         reported = reported ).

     cl_abap_unit_assert=>assert_not_initial( failed ).
    cl_abap_unit_assert=>assert_initial( reported ).
     cl_abap_unit_assert=>assert_initial( result ).
  ENDMETHOD.

  METHOD delete_membership.
     DATA: result   TYPE TABLE FOR ACTION RESULT ZLH_R_BusinessPartner~deleteMembership,
           mapped   TYPE RESPONSE FOR MAPPED EARLY ZLH_R_BusinessPartner,
           failed   TYPE RESPONSE FOR FAILED EARLY ZLH_R_BusinessPartner,
           reported TYPE RESPONSE FOR REPORTED EARLY ZLH_R_BusinessPartner.

*      First create a membership to delete
     DATA: create_result TYPE TABLE FOR ACTION RESULT ZLH_R_BusinessPartner~createMembership,
           create_mapped   TYPE RESPONSE FOR MAPPED EARLY ZLH_R_BusinessPartner,
           create_failed   TYPE RESPONSE FOR FAILED EARLY ZLH_R_BusinessPartner,
           create_reported TYPE RESPONSE FOR REPORTED EARLY ZLH_R_BusinessPartner.

     mo_cut->createmembership( EXPORTING keys = VALUE #( ( SoldToParty = '0001000042' %is_draft = '01' ) )
                               CHANGING  result   = create_result
                                         mapped   = create_mapped
                                         failed   = create_failed
                                         reported = create_reported ).

*      Now delete the membership
     mo_cut->deletemembership( EXPORTING keys = VALUE #( ( SoldToParty = '0001000042' %is_draft = '01' ) )
                               CHANGING  result   = result
                                         mapped   = mapped
                                         failed   = failed
                                         reported = reported ).

     cl_abap_unit_assert=>assert_initial( failed ).
     cl_abap_unit_assert=>assert_initial( reported ).
     cl_abap_unit_assert=>assert_initial( result ).
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_category_behavior_handler DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

PUBLIC SECTION.
  METHODS:
    create_category_duplicate    FOR TESTING,
    create_category_no_hdr       FOR TESTING,
    create_category_below_thresh FOR TESTING,
    create_category_above_thresh FOR TESTING.

PRIVATE SECTION.
    CLASS-DATA: class_under_test TYPE REF TO lhc_BusinessPartner.
    CLASS-DATA: cds_test_environment TYPE REF TO if_cds_test_environment,
                sql_test_environment     TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.

ENDCLASS.

CLASS ltcl_category_behavior_handler IMPLEMENTATION.

  METHOD class_setup.

    cds_test_environment = cl_cds_test_environment=>create_for_multiple_cds(
                             VALUE #( ( i_for_entity = 'ZLH_R_BusinessPartner' )
                                      ( i_for_entity = 'ZLH_R_Membership' )
                                      ( i_for_entity = 'I_SalesOrder' )
                                      ( i_for_entity = 'ZLH_R_CATEGORY' )
*                                      ( i_for_entity = 'ZLH_I_SoldToParty' )
                                                                                         ( i_for_entity = 'ZLH_R_CATEGORY_HDR' )
*                                                                                         ( i_for_entity = 'ZLH_I_CATEGORYSTATVH' )
                                                                                         ( i_for_entity = 'ZLH_R_CATEGORY_TEXT' )
                                                                                          ) ).
    cds_test_environment->enable_double_redirection( ).

*    sql_test_environment = cl_osql_test_environment=>create(   " <-- add this
*      i_dependency_list = VALUE #( ( 'ZLH_CATEGORY_HDR' ) )
*    ).

  ENDMETHOD.

  METHOD class_teardown.
    ROLLBACK ENTITIES.
    IF cds_test_environment IS BOUND.
      cds_test_environment->destroy( ).
    ENDIF.
    IF sql_test_environment IS BOUND.
      sql_test_environment->destroy( ).
    ENDIF.
  ENDMETHOD.

  METHOD setup.
    CREATE OBJECT class_under_test  FOR TESTING.
    DATA: business_partner TYPE STANDARD TABLE OF I_BusinessPartner,
          salesorder TYPE STANDARD TABLE OF I_SalesDocument,
          soldto TYPE STANDARD TABLE OF ZLH_I_SoldToParty.

    business_partner = VALUE #( ( BusinessPartner = '0001000182' ) ).
    cds_test_environment->insert_test_data( i_data = business_partner ).

    salesorder = VALUE #( ( SalesDocument = '0001000112'
                            SoldToParty = '0001000182' ) ).
    cds_test_environment->insert_test_data( i_data = salesorder ).

    soldto = VALUE #( ( SoldToParty = '0001000182' ) ).
    cds_test_environment->insert_test_data( i_data = soldto ).

  ENDMETHOD.

  METHOD teardown.

      READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
    ENTITY ZLH_R_BusinessPartner
    BY \_Category
    FIELDS ( CategoryID )
    WITH VALUE #( ( SoldToParty = '0001000182' ) )
    RESULT DATA(categories).
    IF cds_test_environment IS BOUND.
      cds_test_environment->clear_doubles( ).
    ENDIF.
    ROLLBACK ENTITIES.
     READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
    ENTITY ZLH_R_BusinessPartner
    BY \_Category
    FIELDS ( CategoryID )
    WITH VALUE #( ( SoldToParty = '0001000182' ) )
    RESULT DATA(categories1).
    IF sql_test_environment IS BOUND.           " <-- add
      sql_test_environment->clear_doubles( ).
    ENDIF.
  ENDMETHOD.

  METHOD create_category_duplicate.
    " Branch: category already assigned (same BP/MembershipID/CategoryID) → error 017, RETURN
    DATA: mapped   TYPE RESPONSE FOR MAPPED EARLY ZLH_R_BusinessPartner,
          failed   TYPE RESPONSE FOR FAILED EARLY ZLH_R_BusinessPartner,
          reported TYPE RESPONSE FOR REPORTED EARLY ZLH_R_BusinessPartner.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner = '0001000182' membershipid = 1 ) ).
    cds_test_environment->insert_test_data( i_data = memberships ).

    DATA categories TYPE STANDARD TABLE OF zlh_category.
    categories = VALUE #( ( Business_Partner = '0001000182' MembershipID = 1 CategoryID = '001' ) ).
    cds_test_environment->insert_test_data( i_data = categories ).

    class_under_test->createcategory(
      EXPORTING keys = VALUE #( ( SoldToParty = '0001000182'
*                                  %is_draft = '01'
                                  %param-Categoryid = '001' ) )
      CHANGING  mapped   = mapped
                failed   = failed
                reported = reported
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = failed-zlh_r_category
      msg = 'Expected failure for duplicate category'
    ).
    cl_abap_unit_assert=>assert_equals(
      act = reported-zlh_r_category[ 1 ]-%msg->if_t100_message~t100key-msgno
      exp = '017'
      msg = 'Expected message 017 for duplicate category'
    ).
  ENDMETHOD.


  METHOD create_category_no_hdr.
    " Branch: no category_hdr record (sy-subrc NE 0) → skip threshold check, create category
    DATA: mapped   TYPE RESPONSE FOR MAPPED EARLY ZLH_R_BusinessPartner,
          failed   TYPE RESPONSE FOR FAILED EARLY ZLH_R_BusinessPartner,
          reported TYPE RESPONSE FOR REPORTED EARLY ZLH_R_BusinessPartner.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner = '0001000182' MembershipID = 1 ) ).
    cds_test_environment->insert_test_data( i_data = memberships ).

    " No category_hdr inserted → SELECT SINGLE returns sy-subrc = 4 → IF block skipped entirely

    class_under_test->createcategory(
      EXPORTING keys = VALUE #( ( SoldToParty = '0001000182'
*                                  %is_draft = '01'
                                  %param-Categoryid = '001' ) )
      CHANGING  mapped   = mapped
                failed   = failed
                reported = reported
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = failed-zlh_r_category
      msg = 'Expected failure for missing category header details'
    ).
    cl_abap_unit_assert=>assert_equals(
      act = reported-zlh_r_category[ 1 ]-%msg->if_t100_message~t100key-msgno
      exp = '021'
      msg = 'Expected message 021 for missing category header details'
    ).
  ENDMETHOD.

  METHOD create_category_below_thresh.
    " Branch: header found, loyalty points (0, no transactions) < threshold (9999) → error 012, RETURN
    DATA: mapped   TYPE RESPONSE FOR MAPPED EARLY ZLH_R_BusinessPartner,
          failed   TYPE RESPONSE FOR FAILED EARLY ZLH_R_BusinessPartner,
          reported TYPE RESPONSE FOR REPORTED EARLY ZLH_R_BusinessPartner.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner = '0001000182' MembershipID = 1 ) ).
    cds_test_environment->insert_test_data( i_data = memberships ).

    DATA category_hdr TYPE STANDARD TABLE OF zlh_category_hdr.
    category_hdr = VALUE #( ( Categoryid = '001' threshold = 9999 ) ).
    cds_test_environment->insert_test_data( i_data = category_hdr ).

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
    ENTITY ZLH_R_BusinessPartner
    BY \_Category
    FIELDS ( CategoryID )
    WITH VALUE #( ( SoldToParty = '0001000182' ) )
    RESULT DATA(categories).

    class_under_test->createcategory(
      EXPORTING keys = VALUE #( ( SoldToParty = '0001000182'
*                                  %is_draft = '01'
                                  %param-Categoryid = '001' ) )
      CHANGING  mapped   = mapped
                failed   = failed
                reported = reported
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = failed-zlh_r_category
      msg = 'Expected failure for insufficient loyalty points'
    ).
    cl_abap_unit_assert=>assert_equals(
      act = reported-zlh_r_category[ 1 ]-%msg->if_t100_message~t100key-msgno
      exp = '012'
      msg = 'Expected message 012 for insufficient loyalty points'
    ).
  ENDMETHOD.


  METHOD create_category_above_thresh.
    " Branch: header found, threshold = 0, total points (0) >= 0 → check passes, create category
    DATA: mapped   TYPE RESPONSE FOR MAPPED EARLY ZLH_R_BusinessPartner,
          failed   TYPE RESPONSE FOR FAILED EARLY ZLH_R_BusinessPartner,
          reported TYPE RESPONSE FOR REPORTED EARLY ZLH_R_BusinessPartner.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner = '0001000182' membershipid = 1 membership_status = 'A' ) ).
    cds_test_environment->insert_test_data( i_data = memberships ).

    " threshold = 0 → 0 < 0 is false → insufficient-points block not entered
    DATA category_hdr TYPE STANDARD TABLE OF zlh_category_hdr.
    category_hdr = VALUE #( ( categoryid = '00000001' threshold = 0 ) ).
    cds_test_environment->insert_test_data( i_data = category_hdr ).

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
    ENTITY ZLH_R_BusinessPartner
    BY \_Category
    FIELDS ( CategoryID )
    WITH VALUE #( ( SoldToParty = '0001000182' ) )
    RESULT DATA(categories).

    class_under_test->createcategory(
      EXPORTING keys = VALUE #( ( SoldToParty = '0001000182'
*                                  %is_draft = '01'
                                  %param-Categoryid = '00000001' ) )
      CHANGING  mapped   = mapped
                failed   = failed
                reported = reported
    ).

    cl_abap_unit_assert=>assert_not_initial(
      act = mapped-zlh_r_category
      msg = 'Expected failure for insufficient loyalty points'
    ).

    cl_abap_unit_assert=>assert_equals( act = mapped-zlh_r_category[ 1 ]-CategoryID
                                        exp = '00000001'
                                        msg = 'Excepted category ID is 00000001' ).


  ENDMETHOD.
ENDCLASS.