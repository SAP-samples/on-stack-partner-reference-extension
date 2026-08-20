*CLASS ltcl_category_filldefaults DEFINITION DEFERRED FOR TESTING.
CLASS zcl_lh_category DEFINITION LOCAL FRIENDS ltcl_category_filldefaults.

CLASS ltcl_category_filldefaults DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    METHODS:
      fill_defaults_initial_fields   FOR TESTING,
      fill_defaults_existing_values  FOR TESTING,
      fill_defaults_deactivate       FOR TESTING,
      fill_defaults_no_match         FOR TESTING.

  PRIVATE SECTION.
    DATA: mo_cut TYPE REF TO lhc_category.
    CLASS-DATA: cds_test_environment TYPE REF TO if_cds_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.

ENDCLASS.

CLASS ltcl_category_filldefaults IMPLEMENTATION.

  METHOD class_setup.
    cds_test_environment = cl_cds_test_environment=>create_for_multiple_cds(
      VALUE #( ( i_for_entity = 'ZLH_R_BusinessPartner' )
               ( i_for_entity = 'ZLH_R_Membership' )
               ( i_for_entity = 'ZLH_R_CATEGORY' )
               ( i_for_entity = 'I_SalesOrder' ) ) ).
    cds_test_environment->enable_double_redirection( ).
  ENDMETHOD.

  METHOD class_teardown.
    IF cds_test_environment IS BOUND.
      cds_test_environment->destroy( ).
    ENDIF.
  ENDMETHOD.

  METHOD setup.
    CREATE OBJECT mo_cut FOR TESTING.

    DATA: business_partner TYPE STANDARD TABLE OF I_BusinessPartner,
          salesorder       TYPE STANDARD TABLE OF I_SalesDocument.

    business_partner = VALUE #( ( BusinessPartner = '0001000042' ) ).
    cds_test_environment->insert_test_data( i_data = business_partner ).

    salesorder = VALUE #( ( SalesDocument = '0001000042' ) ).
    cds_test_environment->insert_test_data( i_data = salesorder ).
  ENDMETHOD.

  METHOD teardown.
    IF cds_test_environment IS BOUND.
      cds_test_environment->clear_doubles( ).
    ENDIF.
  ENDMETHOD.

  METHOD fill_defaults_initial_fields.
    " Test: New category with all initial fields should get default values
    " Expected: Status = active, StartDate = system date, EndDate = category_enddate, StatusCriticality = 3

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner = '0001000042' membershipid = 1 ) ).
    cds_test_environment->insert_test_data( i_data = memberships ).

    DATA categories TYPE STANDARD TABLE OF zlh_category.
    categories = VALUE #( ( Business_Partner = '0001000042'
                            MembershipID     = 1
                            CategoryID       = '001'
                            Status           = ''
                            Start_Date        = '00000000'
                            End_Date          = '00000000' ) ).
    cds_test_environment->insert_test_data( i_data = categories ).

    " Build keys matching the category
*    DATA keys TYPE TABLE FOR  zlh_r_category~fillDefaultValues.
*    keys = VALUE #( ( CategoryID   = '001'
*                      MembershipID = 1 ) ).

    mo_cut->filldefaultvalues( keys = VALUE #( ( CategoryID   = '001'
                      MembershipID = 1 ) ) ).

    " Verify: Read the updated category entity
    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY zlh_r_category
      ALL FIELDS WITH VALUE #( ( CategoryID   = '001'
                                 MembershipID = 1 ) )
      RESULT DATA(result_categories).

    cl_abap_unit_assert=>assert_not_initial(
      act = result_categories
      msg = 'Expected category result to be returned'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-Status
      exp = zif_lh_constants=>category_status-active
      msg = 'Status should default to active'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-StartDate
      exp = cl_abap_context_info=>get_system_date( )
      msg = 'StartDate should default to system date'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-EndDate
      exp = zif_lh_constants=>category_enddate
      msg = 'EndDate should default to category_enddate constant'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-StatusCriticality
      exp = 3
      msg = 'StatusCriticality should be 3 for new categories'
    ).
  ENDMETHOD.

  METHOD fill_defaults_existing_values.
    " Test: Category with pre-filled values should retain them (no overwrite)
    " Expected: Status, StartDate, EndDate remain as provided; StatusCriticality = 3

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner = '0001000042' membershipid = 1 ) ).
    cds_test_environment->insert_test_data( i_data = memberships ).

    DATA categories TYPE STANDARD TABLE OF zlh_category.
    categories = VALUE #( ( Business_Partner = '0001000042'
                            MembershipID     = 1
                            CategoryID       = '002'
                            Status           = zif_lh_constants=>category_status-inactive
                            Start_Date        = '20250101'
                            End_Date          = '20251231' ) ).
    cds_test_environment->insert_test_data( i_data = categories ).

*    DATA keys TYPE TABLE FOR DETERMINE zlh_r_category~fillDefaultValues.
*    keys = VALUE #( ( CategoryID   = '002'
*                      MembershipID = 1 ) ).

    mo_cut->filldefaultvalues( keys = VALUE #( ( CategoryID   = '002'
                      MembershipID = 1 ) ) ).

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY zlh_r_category
      ALL FIELDS WITH VALUE #( ( CategoryID   = '002'
                                 MembershipID = 1 ) )
      RESULT DATA(result_categories).

    cl_abap_unit_assert=>assert_not_initial(
      act = result_categories
      msg = 'Expected category result to be returned'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-Status
      exp = zif_lh_constants=>category_status-inactive
      msg = 'Existing status should be preserved'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-StartDate
      exp = '20250101'
      msg = 'Existing StartDate should be preserved'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-EndDate
      exp = '20251231'
      msg = 'Existing EndDate should be preserved'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-StatusCriticality
      exp = 3
      msg = 'StatusCriticality should be set to 3'
    ).
  ENDMETHOD.

  METHOD fill_defaults_deactivate.
    " Test: Category NOT in keys but with EndDate = category_enddate should be deactivated
    " Expected: EndDate = system date, Status = inactive, StatusCriticality = 0

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner = '0001000042' membershipid = 1 ) ).
    cds_test_environment->insert_test_data( i_data = memberships ).

    DATA categories TYPE STANDARD TABLE OF zlh_category.
    categories = VALUE #( ( Business_Partner = '0001000042'
                            MembershipID     = 1
                            CategoryID       = '003'
                            Status           = zif_lh_constants=>category_status-active
                            Start_Date        = '20250101'
                            End_Date          = zif_lh_constants=>category_enddate ) ).
    cds_test_environment->insert_test_data( i_data = categories ).

    " Keys contain a DIFFERENT CategoryID so '003' is NOT in keys
    " This triggers the ELSEIF branch (EndDate = category_enddate → deactivate)
*    DATA keys TYPE TABLE FOR DETERMINE zlh_r_category~fillDefaultValues.
*    keys = VALUE #( ( CategoryID   = '999'
*                      MembershipID = 1 ) ).

    mo_cut->filldefaultvalues( keys = VALUE #( ( CategoryID   = '999'
                      MembershipID = 1 ) ) ).

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY zlh_r_category
      ALL FIELDS WITH VALUE #( ( CategoryID   = '003'
                                 MembershipID = 1 ) )
      RESULT DATA(result_categories).

    cl_abap_unit_assert=>assert_not_initial(
      act = result_categories
      msg = 'Expected category result to be returned'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-EndDate
      exp = cl_abap_context_info=>get_system_date( )
      msg = 'EndDate should be set to system date on deactivation'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-Status
      exp = zif_lh_constants=>category_status-inactive
      msg = 'Status should be set to inactive on deactivation'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-StatusCriticality
      exp = 0
      msg = 'StatusCriticality should be 0 on deactivation'
    ).
  ENDMETHOD.

  METHOD fill_defaults_no_match.
    " Test: Category NOT in keys and EndDate <> category_enddate → no update
    " Expected: No modifications, entity remains unchanged

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner = '0001000042' membershipid = 1 ) ).
    cds_test_environment->insert_test_data( i_data = memberships ).

    DATA categories TYPE STANDARD TABLE OF zlh_category.
    categories = VALUE #( ( Business_Partner = '0001000042'
                            MembershipID     = 1
                            CategoryID       = '004'
                            Status           = zif_lh_constants=>category_status-active
                            Start_Date        = '20250101'
                            End_Date          = '20251231' ) ).
    cds_test_environment->insert_test_data( i_data = categories ).

    " Keys contain a DIFFERENT CategoryID and EndDate is NOT category_enddate
    " Neither IF nor ELSEIF is triggered → no update
*    DATA keys TYPE TABLE FOR DETERMINE zlh_r_category~fillDefaultValues.
*    keys = VALUE #( ( CategoryID   = '999'
*                      MembershipID = 1 ) ).

    mo_cut->filldefaultvalues( keys = VALUE #( ( CategoryID   = '999'
                      MembershipID = 1 ) ) ).

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY zlh_r_category
      ALL FIELDS WITH VALUE #( ( CategoryID   = '004'
                                 MembershipID = 1 ) )
      RESULT DATA(result_categories).

    cl_abap_unit_assert=>assert_not_initial(
      act = result_categories
      msg = 'Expected category result to be returned'
    ).

    " Values should remain unchanged
    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-Status
      exp = zif_lh_constants=>category_status-active
      msg = 'Status should remain unchanged when no branch matches'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-StartDate
      exp = '20250101'
      msg = 'StartDate should remain unchanged when no branch matches'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = result_categories[ 1 ]-EndDate
      exp = '20251231'
      msg = 'EndDate should remain unchanged when no branch matches'
    ).
  ENDMETHOD.

ENDCLASS.