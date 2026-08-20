"! @testing zcl_lh_loyalty_points
class ltcl_loyalty_points DEFINITION DEFERRED.
CLASS zcl_lh_loyalty_points DEFINITION LOCAL FRIENDS ltcl_loyalty_points.

CLASS ltcl_loyalty_points DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    METHODS:
      get_points_empty_input       FOR TESTING,
      get_points_no_transactions   FOR TESTING,
      get_points_active_accrual    FOR TESTING,
      get_points_inactive_member   FOR TESTING,
      get_points_redemption        FOR TESTING,
      get_points_multi_partners    FOR TESTING,
      get_points_normalize_max     FOR TESTING,
      get_points_normalize_neg     FOR TESTING,
      get_points_promotion         FOR TESTING,
      normalize_above_max          FOR TESTING,
      normalize_negative           FOR TESTING,
      normalize_normal_value       FOR TESTING,
      normalize_zero               FOR TESTING,
      normalize_at_max             FOR TESTING.

  PRIVATE SECTION.
    CLASS-DATA: go_cds_test_environment TYPE REF TO if_cds_test_environment,
                go_sql_test_environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.
ENDCLASS.

CLASS ltcl_loyalty_points IMPLEMENTATION.

  METHOD class_setup.
    go_cds_test_environment = cl_cds_test_environment=>create_for_multiple_cds(
      VALUE #( ( i_for_entity = 'ZLH_R_TRANSACTIONS' i_select_base_dependencies = abap_true )
               ( i_for_entity = 'ZLH_R_MEMBERSHIP' i_select_base_dependencies = abap_true ) ) ).
    go_cds_test_environment->enable_double_redirection( ).

*    go_sql_test_environment = cl_osql_test_environment=>create(
*      i_dependency_list = VALUE #(
*                                    ( 'ZLH_TRANSACTIONS' )
*                                   ( 'ZLH_MEMBERSHIP' ) ) ).
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
    " No instance needed - class only has static methods
  ENDMETHOD.

  METHOD teardown.
    IF go_cds_test_environment IS BOUND.
      go_cds_test_environment->clear_doubles( ).
    ENDIF.
    IF go_sql_test_environment IS BOUND.
      go_sql_test_environment->clear_doubles( ).
    ENDIF.
  ENDMETHOD.

  METHOD get_points_empty_input.
    " Branch: business_partners IS INITIAL → early RETURN, empty result
    DATA(lt_partners) = VALUE zcl_lh_loyalty_points=>business_partner_keys( ).

    DATA(lt_result) = zcl_lh_loyalty_points=>get_points( lt_partners ).

    cl_abap_unit_assert=>assert_initial(
      act = lt_result
      msg = 'Result must be empty when input is initial'
    ).
  ENDMETHOD.

  METHOD get_points_no_transactions.
    " Branch: partner exists but no transactions → actual_points empty
    "         → actual-business_partner IS INITIAL → available = 0, redeemed = 0
    DATA(lt_partners) = VALUE zcl_lh_loyalty_points=>business_partner_keys(
      ( sold_to_party = '0000000001' ) ).

    " Insert membership but no transactions
    DATA memberships TYPE STANDARD TABLE OF ZLH_MEMBERSHIP.
    memberships = VALUE #( ( business_partner  = '0000000001'
                             membershipid     = '00000001'
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = '99991231' ) ).
    go_cds_test_environment->insert_test_data( i_data = memberships ).

    DATA(lt_result) = zcl_lh_loyalty_points=>get_points( lt_partners ).

    cl_abap_unit_assert=>assert_not_initial(
      act = lt_result
      msg = 'Result should contain entry for the partner'
    ).

    DATA(ls_point) = VALUE #( lt_result[ business_partner = '0000000001' ] OPTIONAL ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_point-available
      exp = 0
      msg = 'Available should be 0 when no transactions exist'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_point-redeemed
      exp = 0
      msg = 'Redeemed should be 0 when no transactions exist'
    ).
  ENDMETHOD.

  METHOD get_points_active_accrual.
    " Branch: active membership + accrual/purchase/bonus transactions
    "         → available = SUM of earning points
    "         → actual-business_partner IS NOT INITIAL → normalize called (normal range)
    DATA(lt_partners) = VALUE zcl_lh_loyalty_points=>business_partner_keys(
      ( sold_to_party = '0000000010' ) ).

    DATA memberships TYPE STANDARD TABLE OF ZLH_MEMBERSHIP.
    memberships = VALUE #( ( business_partner  = '0000000010'
                             membershipid     = '00000001'
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = '99991231' ) ).
    go_cds_test_environment->insert_test_data( i_data = memberships ).

    DATA transactions TYPE STANDARD TABLE OF ZLH_TRANSACTIONS.
    transactions = VALUE #(
      ( business_partner = '0000000010'
        activity_type    = zif_lh_constants=>activity-accrual
        loyalty_points   = 100 )
      ( business_partner = '0000000010'
        activity_type    = zif_lh_constants=>activity-purchase
        loyalty_points   = 50 )
      ( business_partner = '0000000010'
        activity_type    = zif_lh_constants=>activity-bonus
        loyalty_points   = 25 ) ).
    go_cds_test_environment->insert_test_data( i_data = transactions ).

    DATA(lt_result) = zcl_lh_loyalty_points=>get_points( lt_partners ).

    DATA(ls_point) = VALUE #( lt_result[ business_partner = '0000000010' ] OPTIONAL ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_point-available
      exp = 175
      msg = 'Available should be sum of accrual + purchase + bonus (175)'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_point-redeemed
      exp = 0
      msg = 'Redeemed should be 0 when no redemption transactions'
    ).
  ENDMETHOD.

  METHOD get_points_inactive_member.
    " Branch: inactive membership (status = 'I')
    "         → CASE returns 0 for inactive membership
    DATA(lt_partners) = VALUE zcl_lh_loyalty_points=>business_partner_keys(
      ( sold_to_party = '0000000020' ) ).

    DATA memberships TYPE STANDARD TABLE OF ZLH_MEMBERSHIP.
    memberships = VALUE #( ( business_partner  = '0000000020'
                             membershipid     = '00000001'
                             membership_status = 'I'
                             membership_enddate = '20200101' ) ).
    go_cds_test_environment->insert_test_data( i_data = memberships ).

    DATA transactions TYPE STANDARD TABLE OF ZLH_TRANSACTIONS.
    transactions = VALUE #(
      ( business_partner = '0000000020'
        activity_type    = zif_lh_constants=>activity-accrual
        loyalty_points   = 500 )
      ( business_partner = '0000000020'
        activity_type    = zif_lh_constants=>activity-redemption
        loyalty_points   = 100 ) ).
    go_cds_test_environment->insert_test_data( i_data = transactions ).

    DATA(lt_result) = zcl_lh_loyalty_points=>get_points( lt_partners ).

    DATA(ls_point) = VALUE #( lt_result[ business_partner = '0000000020' ] OPTIONAL ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_point-available
      exp = 0
      msg = 'Available should be 0 for inactive membership'
    ).

  ENDMETHOD.

  METHOD get_points_redemption.
    " Branch: redemption and deactivation activity types
    "         → redeemed = SUM of redemption + deactivation points
    "         → available = accrued - redeemed
    DATA(lt_partners) = VALUE zcl_lh_loyalty_points=>business_partner_keys(
      ( sold_to_party = '0000000030' ) ).

    DATA memberships TYPE STANDARD TABLE OF ZLH_MEMBERSHIP.
    memberships = VALUE #( ( business_partner  = '0000000030'
                             membershipid     = '00000001'
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = '99991231' ) ).
    go_cds_test_environment->insert_test_data( i_data = memberships ).

    DATA transactions TYPE STANDARD TABLE OF ZLH_TRANSACTIONS.
    transactions = VALUE #(
      ( business_partner = '0000000030'
        activity_type    = zif_lh_constants=>activity-accrual
        loyalty_points   = 200 )
      ( business_partner = '0000000030'
        activity_type    = zif_lh_constants=>activity-redemption
        loyalty_points   = 50 )
      ( business_partner = '0000000030'
        activity_type    = zif_lh_constants=>activity-deactivation
        loyalty_points   = 30 ) ).
    go_cds_test_environment->insert_test_data( i_data = transactions ).

    DATA(lt_result) = zcl_lh_loyalty_points=>get_points( lt_partners ).

    DATA(ls_point) = VALUE #( lt_result[ business_partner = '0000000030' ] OPTIONAL ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_point-redeemed
      exp = 80
      msg = 'Redeemed should be sum of redemption + deactivation (80)'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_point-available
      exp = 120
      msg = 'Available should be accrual minus redeemed (200 - 80 = 120)'
    ).
  ENDMETHOD.

  METHOD get_points_multi_partners.
    " Branch: multiple partners in input → each gets independent calculation
    DATA(lt_partners) = VALUE zcl_lh_loyalty_points=>business_partner_keys(
      ( sold_to_party = '0000000040' )
      ( sold_to_party = '0000000041' ) ).

    DATA memberships TYPE STANDARD TABLE OF ZLH_MEMBERSHIP.
    memberships = VALUE #(
      ( business_partner  = '0000000040'
        membershipid     = '00000001'
        membership_status = zif_lh_constants=>membership_status-active
        membership_enddate = '99991231' )
      ( business_partner  = '0000000041'
        membershipid     = '00000002'
        membership_status = zif_lh_constants=>membership_status-active
        membership_enddate = '99991231' ) ).
    go_cds_test_environment->insert_test_data( i_data = memberships ).

    DATA transactions TYPE STANDARD TABLE OF ZLH_TRANSACTIONS.
    transactions = VALUE #(
      ( business_partner = '0000000040'
        activity_type    = zif_lh_constants=>activity-accrual
        loyalty_points   = 300 )
      ( business_partner = '0000000041'
        activity_type    = zif_lh_constants=>activity-purchase
        loyalty_points   = 150 ) ).
    go_cds_test_environment->insert_test_data( i_data = transactions ).

    DATA(lt_result) = zcl_lh_loyalty_points=>get_points( lt_partners ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_result )
      exp = 2
      msg = 'Result should contain entries for both partners'
    ).

    DATA(ls_point_40) = VALUE #( lt_result[ business_partner = '0000000040' ] OPTIONAL ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_point_40-available
      exp = 300
      msg = 'Partner 40 available should be 300'
    ).

    DATA(ls_point_41) = VALUE #( lt_result[ business_partner = '0000000041' ] OPTIONAL ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_point_41-available
      exp = 150
      msg = 'Partner 41 available should be 150'
    ).
  ENDMETHOD.

  METHOD get_points_normalize_max.
    " Branch (normalize): points > max_loyalty_points → capped at max
    " Insert transactions whose SUM exceeds max_loyalty_points
    DATA(lt_partners) = VALUE zcl_lh_loyalty_points=>business_partner_keys(
      ( sold_to_party = '0000000050' ) ).

    DATA memberships TYPE STANDARD TABLE OF ZLH_MEMBERSHIP.
    memberships = VALUE #( ( business_partner  = '0000000050'
                             membershipid     = '00000001'
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = '99991231' ) ).
    go_cds_test_environment->insert_test_data( i_data = memberships ).

    " Insert transactions whose sum exceeds max_loyalty_points
    DATA transactions TYPE STANDARD TABLE OF ZLH_TRANSACTIONS.
    transactions = VALUE #(
      ( business_partner = '0000000050'
        activity_type    = zif_lh_constants=>activity-accrual
        loyalty_points   = zif_lh_constants=>max_loyalty_points )
      ( business_partner = '0000000050'
        activity_type    = zif_lh_constants=>activity-bonus
        loyalty_points   = 1 ) ).
    go_cds_test_environment->insert_test_data( i_data = transactions ).

    DATA(lt_result) = zcl_lh_loyalty_points=>get_points( lt_partners ).

    DATA(ls_point) = VALUE #( lt_result[ business_partner = '0000000050' ] OPTIONAL ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_point-available
      exp = zif_lh_constants=>max_loyalty_points
      msg = 'Available should be capped at max_loyalty_points'
    ).
  ENDMETHOD.

  METHOD get_points_normalize_neg.
    " Branch (normalize): points < 0 → normalized to 0
    " Achieved by having more redemption than accrual → negative available
    DATA(lt_partners) = VALUE zcl_lh_loyalty_points=>business_partner_keys(
      ( sold_to_party = '0000000060' ) ).

    DATA memberships TYPE STANDARD TABLE OF ZLH_MEMBERSHIP.
    memberships = VALUE #( ( business_partner  = '0000000060'
                             membershipid     = '00000001'
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = '99991231' ) ).
    go_cds_test_environment->insert_test_data( i_data = memberships ).

    " Redemption exceeds accrual → negative raw available before normalization
    DATA transactions TYPE STANDARD TABLE OF ZLH_TRANSACTIONS.
    transactions = VALUE #(
      ( business_partner = '0000000060'
        activity_type    = zif_lh_constants=>activity-accrual
        loyalty_points   = 10 )
      ( business_partner = '0000000060'
        activity_type    = zif_lh_constants=>activity-redemption
        loyalty_points   = 100 ) ).
    go_cds_test_environment->insert_test_data( i_data = transactions ).

    DATA(lt_result) = zcl_lh_loyalty_points=>get_points( lt_partners ).

    DATA(ls_point) = VALUE #( lt_result[ business_partner = '0000000060' ] OPTIONAL ).

    " After normalization, negative available should become 0
    cl_abap_unit_assert=>assert_equals(
      act = ls_point-available
      exp = 0
      msg = 'Negative available should be normalized to 0'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_point-redeemed
      exp = 100
      msg = 'Redeemed should be 100'
    ).
  ENDMETHOD.

  METHOD get_points_promotion.
    " Branch: promotion activity type included in available calculation
    DATA(lt_partners) = VALUE zcl_lh_loyalty_points=>business_partner_keys(
      ( sold_to_party = '0000000070' ) ).

    DATA memberships TYPE STANDARD TABLE OF ZLH_MEMBERSHIP.
    memberships = VALUE #( ( business_partner  = '0000000070'
                             membershipid     = '00000001'
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = '99991231' ) ).
    go_cds_test_environment->insert_test_data( i_data = memberships ).

    DATA transactions TYPE STANDARD TABLE OF ZLH_TRANSACTIONS.
    transactions = VALUE #(
      ( business_partner = '0000000070'
        activity_type    = zif_lh_constants=>activity-promotion
        loyalty_points   = 75 ) ).
    go_cds_test_environment->insert_test_data( i_data = transactions ).

    DATA(lt_result) = zcl_lh_loyalty_points=>get_points( lt_partners ).

    DATA(ls_point) = VALUE #( lt_result[ business_partner = '0000000070' ] OPTIONAL ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_point-available
      exp = 75
      msg = 'Promotion points should count towards available'
    ).
  ENDMETHOD.

  METHOD normalize_above_max.
    " Branch: points > max_loyalty_points → capped at max
    DATA(lv_result) = zcl_lh_loyalty_points=>normalize_loyalty_points(
      points = zif_lh_constants=>max_loyalty_points + 1 ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_result
      exp = zif_lh_constants=>max_loyalty_points
      msg = 'Points exceeding max should be capped at max_loyalty_points'
    ).
  ENDMETHOD.

  METHOD normalize_negative.
    " Branch: points < 0 → returns 0
    DATA(lv_result) = zcl_lh_loyalty_points=>normalize_loyalty_points(
      points = -100 ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_result
      exp = 0
      msg = 'Negative points should be normalized to 0'
    ).
  ENDMETHOD.

  METHOD normalize_normal_value.
    " Branch: 0 < points <= max → returns points unchanged (ELSE branch)
    DATA(lv_result) = zcl_lh_loyalty_points=>normalize_loyalty_points(
      points = 500 ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_result
      exp = 500
      msg = 'Normal points should be returned unchanged'
    ).
  ENDMETHOD.

  METHOD normalize_zero.
    " Branch: points = 0 → falls into ELSE (not > max, not < 0) → returns 0
    DATA(lv_result) = zcl_lh_loyalty_points=>normalize_loyalty_points(
      points = 0 ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_result
      exp = 0
      msg = 'Zero points should be returned as 0'
    ).
  ENDMETHOD.

  METHOD normalize_at_max.
    " Branch: points = max → falls into ELSE (not strictly >) → returns max
    DATA(lv_result) = zcl_lh_loyalty_points=>normalize_loyalty_points(
      points = zif_lh_constants=>max_loyalty_points ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_result
      exp = zif_lh_constants=>max_loyalty_points
      msg = 'Points at max boundary should be returned unchanged'
    ).
  ENDMETHOD.

ENDCLASS.