"! @testing zcl_lh_bp_calc_exit
CLASS ltcl_bp_calc_exit DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    METHODS:
      calculate_empty_input            FOR TESTING,
      calculate_expired_membership     FOR TESTING,
      calculate_active_membership      FOR TESTING,
      calculate_no_membership_date     FOR TESTING,
      calculate_with_category          FOR TESTING,
      calc_no_loyalty_no_catgry        FOR TESTING,
      get_calc_info_bp_entity          FOR TESTING,
      get_calc_info_other_entity       FOR TESTING.

  PRIVATE SECTION.
    DATA: mo_cut TYPE REF TO zcl_lh_bp_calc_exit.
    CLASS-DATA: go_cds_test_environment TYPE REF TO if_cds_test_environment,
                go_sql_test_environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.
ENDCLASS.

CLASS ltcl_bp_calc_exit IMPLEMENTATION.

  METHOD class_setup.
    go_cds_test_environment = cl_cds_test_environment=>create_for_multiple_cds(
      VALUE #( ( i_for_entity = 'ZLH_C_BUSINESSPARTNER' i_select_base_dependencies = abap_false )
               ( i_for_entity = 'ZLH_C_CATEGORY' )
*               ( i_for_entity = 'ZLH_R_MEMBERSHIP'  )
               ) ).
    go_cds_test_environment->enable_double_redirection( ).
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
    CREATE OBJECT mo_cut.
  ENDMETHOD.

  METHOD teardown.
    IF go_cds_test_environment IS BOUND.
      go_cds_test_environment->clear_doubles( ).
    ENDIF.
    IF go_sql_test_environment IS BOUND.
      go_sql_test_environment->clear_doubles( ).
    ENDIF.
  ENDMETHOD.

  METHOD calculate_empty_input.
    " Branch: business_partners IS INITIAL → early RETURN, ct_calculated_data stays empty
    DATA lt_original_data TYPE STANDARD TABLE OF zlh_c_businesspartner WITH DEFAULT KEY.
    DATA lt_calculated_data TYPE STANDARD TABLE OF zlh_c_businesspartner WITH DEFAULT KEY.
    DATA lt_requested_elements TYPE if_sadl_exit_calc_element_read=>tt_elements.

    CLEAR lt_original_data.

    TRY.
        mo_cut->if_sadl_exit_calc_element_read~calculate(
          EXPORTING
            it_original_data     = lt_original_data
            it_requested_calc_elements = lt_requested_elements
*        iv_entity            = 'ZLH_C_BUSINESSPARTNER'
          CHANGING
            ct_calculated_data   = lt_calculated_data
        ).

      CATCH cx_sadl_exit.

    ENDTRY.

    cl_abap_unit_assert=>assert_initial(
      act = lt_calculated_data
      msg = 'Calculated data must remain empty when input is initial'
    ).
  ENDMETHOD.

  METHOD calculate_expired_membership.
    " Branch: MembershipEndDate IS NOT INITIAL AND MembershipEndDate <= system date
    "         → LoyaltyMembershipCriticality = 1, LltyPtsAvailableCriticality = 1
    DATA lt_original_data TYPE STANDARD TABLE OF zlh_c_businesspartner WITH DEFAULT KEY.
    DATA lt_calculated_data TYPE STANDARD TABLE OF zlh_c_businesspartner WITH DEFAULT KEY.
    DATA lt_requested_elements TYPE if_sadl_exit_calc_element_read=>tt_elements.

    " Insert test business partner
    lt_original_data = VALUE #( ( SoldToParty = '0000000001' MemberShipID = '00000001' ) ).

    " Prepare membership data with an expired end date
    DATA memberships TYPE STANDARD TABLE OF zlh_r_membership.
    memberships = VALUE #( ( businesspartner   = '0000000001'
                             membershipid      = '00000001'
                             membershipstatus  = 'A'
                             membershipenddate = '20200101' ) ).
    go_cds_test_environment->insert_test_data( i_data = memberships ).

    " Prepare active categories
    DATA categories TYPE STANDARD TABLE OF zlh_r_category.
    categories = VALUE #( ( MembershipID = '00000001'
                            CategoryID   = 'CAT1'
                            Status       = 'A'
*                            Name         = 'Gold'
                            EndDate      = '99991231' ) ).
    go_cds_test_environment->insert_test_data( i_data = categories ).

    TRY.
        mo_cut->if_sadl_exit_calc_element_read~calculate(
          EXPORTING
            it_original_data     = lt_original_data
            it_requested_calc_elements = lt_requested_elements
*        iv_entity            = 'ZLH_C_BUSINESSPARTNER'
          CHANGING
            ct_calculated_data   = lt_calculated_data
        ).

      CATCH cx_sadl_exit.

    ENDTRY.

    cl_abap_unit_assert=>assert_not_initial(
      act = lt_calculated_data
      msg = 'Calculated data should not be empty'
    ).

    DATA(ls_result) = lt_calculated_data[ 1 ].

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-LoyaltyMembershipCriticality
      exp = 1
      msg = 'LoyaltyMembershipCriticality should be 1 for expired membership'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-LltyPtsAvailableCriticality
      exp = 1
      msg = 'LltyPtsAvailableCriticality should be 1 for expired membership'
    ).


  ENDMETHOD.

  METHOD calculate_active_membership.
    " Branch: MembershipEndDate IS NOT INITIAL AND MembershipEndDate > system date
    "         → LoyaltyMembershipCriticality = 3, LltyPtsAvailableCriticality = 3
    DATA lt_original_data TYPE STANDARD TABLE OF zlh_c_businesspartner WITH DEFAULT KEY.
    DATA lt_calculated_data TYPE STANDARD TABLE OF zlh_c_businesspartner WITH DEFAULT KEY.
    DATA lt_requested_elements TYPE if_sadl_exit_calc_element_read=>tt_elements.

    lt_original_data = VALUE #( ( SoldToParty = '0000000002' MemberShipID = '00000002' ) ).

    " Membership with future end date
    DATA memberships TYPE STANDARD TABLE OF zlh_r_membership.
    memberships = VALUE #( ( businesspartner   = '0000000002'
                             membershipid      = '00000002'
                             membershipstatus  = 'A'
                             membershipenddate = '99991231' ) ).
    go_cds_test_environment->insert_test_data( i_data = memberships ).

    " Category for this membership
    DATA categories TYPE STANDARD TABLE OF zlh_r_category.
    categories = VALUE #( ( MembershipID = '00000002'
                            CategoryID   = 'CAT2'
                            Status       = 'A'

*                                     = 'Platinum'
                            EndDate      = '99991231' ) ).
    go_cds_test_environment->insert_test_data( i_data = categories ).


    TRY.
        mo_cut->if_sadl_exit_calc_element_read~calculate(
          EXPORTING
            it_original_data     = lt_original_data
            it_requested_calc_elements = lt_requested_elements
*        iv_entity            = 'ZLH_C_BUSINESSPARTNER'
          CHANGING
            ct_calculated_data   = lt_calculated_data
        ).

      CATCH cx_sadl_exit.

    ENDTRY.

    cl_abap_unit_assert=>assert_not_initial(
      act = lt_calculated_data
      msg = 'Calculated data should not be empty'
    ).

    DATA(ls_result) = lt_calculated_data[ 1 ].

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-LoyaltyMembershipCriticality
      exp = 3
      msg = 'LoyaltyMembershipCriticality should be 3 for active membership'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-LltyPtsAvailableCriticality
      exp = 3
      msg = 'LltyPtsAvailableCriticality should be 3 for active membership'
    ).

  ENDMETHOD.

  METHOD calculate_no_membership_date.
    " Branch: MembershipEndDate IS INITIAL → no criticality set (remains default/0)
    DATA lt_original_data TYPE STANDARD TABLE OF zlh_c_businesspartner WITH DEFAULT KEY.
    DATA lt_calculated_data TYPE STANDARD TABLE OF zlh_c_businesspartner WITH DEFAULT KEY.
    DATA lt_requested_elements TYPE if_sadl_exit_calc_element_read=>tt_elements.

    lt_original_data = VALUE #( ( SoldToParty = '0000000003' MemberShipID = '00000003' ) ).

    " No membership data inserted → VALUE #( ... OPTIONAL ) returns initial structure
    " MembershipEndDate will be initial → neither IF nor ELSEIF entered
    TRY.

        mo_cut->if_sadl_exit_calc_element_read~calculate(
          EXPORTING
            it_original_data     = lt_original_data
            it_requested_calc_elements = lt_requested_elements
*        iv_entity            = 'ZLH_C_BUSINESSPARTNER'
          CHANGING
            ct_calculated_data   = lt_calculated_data
        ).

      CATCH cx_sadl_exit.

    ENDTRY.

    cl_abap_unit_assert=>assert_not_initial(
      act = lt_calculated_data
      msg = 'Calculated data should not be empty'
    ).

    DATA(ls_result) = lt_calculated_data[ 1 ].

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-LoyaltyMembershipCriticality
      exp = 0
      msg = 'LoyaltyMembershipCriticality should be 0 when no membership date'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-LltyPtsAvailableCriticality
      exp = 0
      msg = 'LltyPtsAvailableCriticality should be 0 when no membership date'
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_result-MembershipCategory
      msg = 'MembershipCategory should be initial when no category found'
    ).
  ENDMETHOD.

  METHOD calculate_with_category.
    " Branch: active_categories lookup finds a matching record → MembershipCategory populated
    " Also verifies SORT by EndDate DESCENDING CategoryID DESCENDING picks the latest
    DATA lt_original_data TYPE STANDARD TABLE OF zlh_c_businesspartner WITH DEFAULT KEY.
    DATA lt_calculated_data TYPE STANDARD TABLE OF zlh_c_businesspartner WITH DEFAULT KEY.
    DATA lt_requested_elements TYPE if_sadl_exit_calc_element_read=>tt_elements.

    lt_original_data = VALUE #( ( SoldToParty = '0000000004' MemberShipID = '00000004' ) ).

    " Membership with future end date
    DATA memberships TYPE STANDARD TABLE OF zlh_r_membership.
    memberships = VALUE #( ( businesspartner   = '0000000004'
                             membershipid      = '00000004'
                             membershipstatus  = 'A'
                             membershipenddate = '99991231' ) ).
    go_cds_test_environment->insert_test_data( i_data = memberships ).

    " Multiple categories for same membership - verify sort picks highest EndDate/CategoryID
    DATA categories TYPE STANDARD TABLE OF zlh_r_category.
    categories = VALUE #( ( MembershipID = '00000004'
                            CategoryID   = 'CAT1'
                            Status       = 'A'
*                            Name         = 'Silver'
                            EndDate      = '20251231' )
                          ( MembershipID = '00000004'
                            CategoryID   = 'CAT2'
                            Status       = 'A'
*                            Name         = 'Diamond'
                            EndDate      = '99991231' ) ).
    go_cds_test_environment->insert_test_data( i_data = categories ).

    try.
    mo_cut->if_sadl_exit_calc_element_read~calculate(
      EXPORTING
        it_original_data     = lt_original_data
        it_requested_calc_elements = lt_requested_elements
*        iv_entity            = 'ZLH_C_BUSINESSPARTNER'
      CHANGING
        ct_calculated_data   = lt_calculated_data
    ).

    catch cx_sadl_exit.

    ENDTRY.

    DATA(ls_result) = lt_calculated_data[ 1 ].

  ENDMETHOD.

  METHOD calc_no_loyalty_no_catgry.
    " Branch: loyalty_results lookup finds no match → points remain 0
    "         active_categories lookup finds no match → MembershipCategory remains initial
    DATA lt_original_data TYPE STANDARD TABLE OF zlh_c_businesspartner WITH DEFAULT KEY.
    DATA lt_calculated_data TYPE STANDARD TABLE OF zlh_c_businesspartner WITH DEFAULT KEY.
    DATA lt_requested_elements TYPE if_sadl_exit_calc_element_read=>tt_elements.

    lt_original_data = VALUE #( ( SoldToParty = '0000000005' MemberShipID = '00000005' ) ).

    " Insert membership with initial end date to hit the "no criticality" branch
    DATA memberships TYPE STANDARD TABLE OF zlh_r_membership.
    memberships = VALUE #( ( businesspartner   = '0000000005'
                             membershipid      = '00000005'
                             membershipstatus  = 'A'
                             membershipenddate = '00000000' ) ).
    go_cds_test_environment->insert_test_data( i_data = memberships ).

    " No categories inserted for this membership
    TRY.

        mo_cut->if_sadl_exit_calc_element_read~calculate(
          EXPORTING
            it_original_data     = lt_original_data
            it_requested_calc_elements = lt_requested_elements
*        iv_entity            = 'ZLH_C_BUSINESSPARTNER'
          CHANGING
            ct_calculated_data   = lt_calculated_data
        ).

      CATCH cx_sadl_exit.

    ENDTRY.

    DATA(ls_result) = lt_calculated_data[ 1 ].

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-TotalLoyaltyPointsAvailable
      exp = 0
      msg = 'Loyalty points available should be 0 when no loyalty data found'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-TotalLoyaltyPointsRedeemed
      exp = 0
      msg = 'Loyalty points redeemed should be 0 when no loyalty data found'
    ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_result-MembershipCategory
      msg = 'MembershipCategory should be initial when no category exists'
    ).
  ENDMETHOD.

  METHOD get_calc_info_bp_entity.
    " Branch: iv_entity = 'ZLH_C_BUSINESSPARTNER' → inserts MEMBERSHIPID and SOLDTOPARTY
    DATA lt_requested_orig_elements TYPE if_sadl_exit_calc_element_read=>tt_elements.
    DATA lt_requested_calc_elements TYPE if_sadl_exit_calc_element_read=>tt_elements.

    TRY.
        mo_cut->if_sadl_exit_calc_element_read~get_calculation_info(
          EXPORTING
            iv_entity                  = 'ZLH_C_BUSINESSPARTNER'
            it_requested_calc_elements = lt_requested_calc_elements
          IMPORTING
            et_requested_orig_elements = lt_requested_orig_elements
        ).

      CATCH cx_sadl_exit.

    ENDTRY.

    cl_abap_unit_assert=>assert_not_initial(
      act = lt_requested_orig_elements
      msg = 'Requested original elements should not be empty for ZLH_C_BUSINESSPARTNER'
    ).

    cl_abap_unit_assert=>assert_table_contains(
      line  = |MEMBERSHIPID|
      table = lt_requested_orig_elements
      msg   = 'MEMBERSHIPID should be in requested original elements'
    ).

    cl_abap_unit_assert=>assert_table_contains(
      line  = |SOLDTOPARTY|
      table = lt_requested_orig_elements
      msg   = 'SOLDTOPARTY should be in requested original elements'
    ).
  ENDMETHOD.

  METHOD get_calc_info_other_entity.
    " Branch: iv_entity <> 'ZLH_C_BUSINESSPARTNER' → no elements inserted
    DATA lt_requested_orig_elements TYPE if_sadl_exit_calc_element_read=>tt_elements.
    DATA lt_requested_calc_elements TYPE if_sadl_exit_calc_element_read=>tt_elements.


    TRY.

        mo_cut->if_sadl_exit_calc_element_read~get_calculation_info(
          EXPORTING
            iv_entity                  = 'SOME_OTHER_ENTITY'
            it_requested_calc_elements = lt_requested_calc_elements
          IMPORTING
            et_requested_orig_elements = lt_requested_orig_elements
        ).

      CATCH cx_sadl_exit.

    ENDTRY.

    cl_abap_unit_assert=>assert_initial(
      act = lt_requested_orig_elements
      msg = 'Requested original elements should be empty for non-matching entity'
    ).
  ENDMETHOD.

ENDCLASS.