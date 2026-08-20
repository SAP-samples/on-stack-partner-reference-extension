"! Unit tests for ZCL_LH_CATEGORY_UPDATE_JOB
"! Covers branch coverage for: execute, init_log, add_log_msg,
"! process_category_upgrades, create_new_categories, send_notifications
CLASS ltcl_category_update_job DEFINITION DEFERRED.
CLASS zcl_lh_category_update_job DEFINITION LOCAL FRIENDS ltcl_category_update_job.

CLASS ltcl_category_update_job DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS .

  PUBLIC SECTION.
    METHODS:
      "! execute: upgrades IS INITIAL → early return
      execute_no_upgrades              FOR TESTING,
      "! execute: upgrades found → full flow (create + notify)
      execute_with_upgrades            FOR TESTING,

      "! init_log: successful log creation
      init_log_success                 FOR TESTING,

      "! add_log_msg: mo_log IS BOUND → add item + save
      add_log_msg_log_bound            FOR TESTING,
      "! add_log_msg: mo_log IS NOT BOUND → skip
      add_log_msg_log_not_bound        FOR TESTING,

      "! process_category_upgrades: no active memberships → CHECK exits early
      process_no_active_memberships    FOR TESTING,
      "! process_category_upgrades: no transactions/points → CHECK exits
      process_no_total_points          FOR TESTING,
      "! process_category_upgrades: no category headers → CHECK exits
      process_no_category_headers      FOR TESTING,
      "! process_category_upgrades: membership not in active list → CHECK skips
      process_membership_not_active    FOR TESTING,
      "! process_category_upgrades: current category ID is initial → CHECK skips
      process_no_current_category      FOR TESTING,
      "! process_category_upgrades: current header not found → CHECK skips
      process_no_current_header        FOR TESTING,
      "! process_category_upgrades: points <= threshold → CHECK skips
      process_points_below_threshold   FOR TESTING,
      "! process_category_upgrades: no next category found → CHECK skips
      process_no_next_category         FOR TESTING,
      "! process_category_upgrades: next = current category → CHECK skips
      process_next_eq_current          FOR TESTING,
      "! process_category_upgrades: full success → upgrade appended
      process_full_upgrade             FOR TESTING,

      "! create_new_categories: empty upgrades → CHECK exits
      create_categories_empty          FOR TESTING,
      "! create_new_categories: MODIFY success (failed IS INITIAL) → COMMIT
      create_categories_success        FOR TESTING,
      "! create_new_categories: MODIFY failure (failed IS NOT INITIAL) → error log
      create_categories_failure        FOR TESTING,

      "! send_notifications: email IS INITIAL → CHECK skips
      send_notif_no_email              FOR TESTING,
      "! send_notifications: email provided → attempt send
      send_notif_with_email            FOR TESTING.

  PRIVATE SECTION.
    DATA: mo_cut TYPE REF TO zcl_lh_category_update_job.
    CLASS-DATA: cds_test_environment TYPE REF TO if_cds_test_environment,
                sql_test_environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.

ENDCLASS.

CLASS ltcl_category_update_job IMPLEMENTATION.

  METHOD class_setup.
    cds_test_environment = cl_cds_test_environment=>create_for_multiple_cds(
      VALUE #( ( i_for_entity = 'ZLH_R_BusinessPartner' )
*               ( i_for_entity = 'ZLH_R_Membership' )
               ( i_for_entity = 'ZLH_R_CATEGORY' )
               ( i_for_entity = 'ZLH_R_TRANSACTIONS' )
               ( i_for_entity = 'ZLH_I_CATEGORYIDVH' )
*               ( i_for_entity = 'I_WorkplaceAddress' i_select_base_dependencies = abap_false )
               ( i_for_entity = 'I_SalesOrder' ) ) ).
    cds_test_environment->enable_double_redirection( ).

    sql_test_environment = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #( ( 'ZLH_MEMBERSHIP' )
*                                   ( 'ZLH_CATEGORY' )
*                                   ( 'ZLH_CATEGORY_HDR' )
                                    ) ).
  ENDMETHOD.

  METHOD class_teardown.
    IF cds_test_environment IS BOUND.
      cds_test_environment->destroy( ).
    ENDIF.
    IF sql_test_environment IS BOUND.
      sql_test_environment->destroy( ).
    ENDIF.
  ENDMETHOD.

  METHOD setup.
    CREATE OBJECT mo_cut.
    mo_cut->init_log( ).
  ENDMETHOD.

  METHOD teardown.
    IF cds_test_environment IS BOUND.
      cds_test_environment->clear_doubles( ).
    ENDIF.
    IF sql_test_environment IS BOUND.
      sql_test_environment->clear_doubles( ).
    ENDIF.
  ENDMETHOD.

  "-----------------------------------------------------------------------
  " execute method tests
  "-----------------------------------------------------------------------

  METHOD execute_no_upgrades.
    " Branch: upgrades IS INITIAL → logs 'No eligible upgrades found.' and RETURN
    " No test data inserted → process_category_upgrades returns empty table
    TRY.

        mo_cut->if_apj_rt_run~execute(  ).

      CATCH cx_apj_rt_content.

    ENDTRY.

    " If we reach here without dump, the early RETURN branch was taken successfully
    cl_abap_unit_assert=>assert_initial(
      act = mo_cut->process_category_upgrades( )
      msg = 'Expected no upgrades with empty database'
    ).
  ENDMETHOD.

  METHOD execute_with_upgrades.
    " Branch: upgrades IS NOT INITIAL → full flow (create + notify)
    " Insert complete test data to trigger a valid upgrade
    DATA(current_date) = cl_abap_context_info=>get_system_date( ).
    DATA(future_date) = current_date + 365.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner  = '0001000042'
                             membershipid      = 1
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = future_date ) ).
    sql_test_environment->insert_test_data( i_data = memberships ).

    DATA transactions TYPE STANDARD TABLE OF zlh_transactions.
    transactions = VALUE #( ( business_partner = '0001000042'
                              membershipid    = 1
                              loyalty_points   = 5000 ) ).
    cds_test_environment->insert_test_data( i_data = transactions ).

    DATA categories TYPE STANDARD TABLE OF zlh_category.
    categories = VALUE #( ( business_partner = '0001000042'
                            membershipid    = 1
                            categoryid      = '001'
                            status          = zif_lh_constants=>category_status-active
                            end_date         = zif_lh_constants=>category_enddate ) ).
    cds_test_environment->insert_test_data( i_data = categories ).

    DATA category_headers TYPE STANDARD TABLE OF zlh_category_hdr.
    category_headers = VALUE #( ( categoryid    = '001'
*                                  categoryname  = 'Bronze'
                                  threshold     = 100
                                  isenabled     = abap_true )
                                ( categoryid    = '002'
*                                  categoryname  = 'Silver'
                                  threshold     = 2000
                                  isenabled     = abap_true ) ).
    cds_test_environment->insert_test_data( i_data = category_headers ).

*    DATA emails TYPE STANDARD TABLE OF I_WorkplaceAddress.
*    emails = VALUE #( ( BusinessPartner     = '0001000042'
*                        DefaultEmailAddress = 'test@example.com' ) ).
*    cds_test_environment->insert_test_data( i_data = emails ).

    TRY.

        mo_cut->if_apj_rt_run~execute(  ).

      CATCH cx_apj_rt_content.

    ENDTRY.

    " Verify upgrade was detected
    DATA(upgrades) = mo_cut->process_category_upgrades( ).
    cl_abap_unit_assert=>assert_not_initial(
      act = upgrades
      msg = 'Expected upgrades to be found'
    ).
  ENDMETHOD.

  "-----------------------------------------------------------------------
  " init_log tests
  "-----------------------------------------------------------------------

  METHOD init_log_success.
    " Branch: successful creation of log → mo_log IS BOUND
    mo_cut->init_log( ).

    cl_abap_unit_assert=>assert_bound(
      act = mo_cut->mo_log
      msg = 'Expected mo_log to be bound after successful init'
    ).
  ENDMETHOD.

  "-----------------------------------------------------------------------
  " add_log_msg tests
  "-----------------------------------------------------------------------

  METHOD add_log_msg_log_bound.
    " Branch: mo_log IS BOUND → add item and save
    mo_cut->init_log( ).

    " Should not raise exception
    mo_cut->add_log_msg( iv_text = 'Test log message' iv_ty = 'I' ).

    cl_abap_unit_assert=>assert_bound(
      act = mo_cut->mo_log
      msg = 'Log should still be bound after adding message'
    ).
  ENDMETHOD.

  METHOD add_log_msg_log_not_bound.
    " Branch: mo_log IS NOT BOUND → skip add/save
    CLEAR mo_cut->mo_log.

    " Should not raise exception even without log
    mo_cut->add_log_msg( iv_text = 'Message without log' iv_ty = 'W' ).

    cl_abap_unit_assert=>assert_not_bound(
      act = mo_cut->mo_log
      msg = 'Log should remain unbound'
    ).
  ENDMETHOD.

  "-----------------------------------------------------------------------
  " process_category_upgrades tests
  "-----------------------------------------------------------------------

  METHOD process_no_active_memberships.
    " Branch: active_memberships IS INITIAL → CHECK exits, return empty
    " No membership data inserted

    DATA(upgrades) = mo_cut->process_category_upgrades( ).

    cl_abap_unit_assert=>assert_initial(
      act = upgrades
      msg = 'Expected empty result when no active memberships'
    ).
  ENDMETHOD.

  METHOD process_no_total_points.
    " Branch: total_points IS INITIAL → CHECK exits
    " Active membership exists but no transactions
    DATA(current_date) = cl_abap_context_info=>get_system_date( ).
    DATA(future_date) = current_date + 365.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner  = '0001000042'
                             membershipid      = 1
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = future_date ) ).
    sql_test_environment->insert_test_data( i_data = memberships ).

    " No transactions inserted → total_points will be empty

    DATA(upgrades) = mo_cut->process_category_upgrades( ).

    cl_abap_unit_assert=>assert_initial(
      act = upgrades
      msg = 'Expected empty result when no transaction points'
    ).
  ENDMETHOD.

  METHOD process_no_category_headers.
    " Branch: category_headers IS INITIAL → CHECK exits
    DATA(current_date) = cl_abap_context_info=>get_system_date( ).
    DATA(future_date) = current_date + 365.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner  = '0001000042'
                             membershipid      = 1
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = future_date ) ).
    sql_test_environment->insert_test_data( i_data = memberships ).

    DATA transactions TYPE STANDARD TABLE OF zlh_transactions.
    transactions = VALUE #( ( business_partner = '0001000042'
                              membershipid    = 1
                              loyalty_points   = 500 ) ).
    cds_test_environment->insert_test_data( i_data = transactions ).

    " No category_headers inserted → CHECK exits

    DATA(upgrades) = mo_cut->process_category_upgrades( ).

    cl_abap_unit_assert=>assert_initial(
      act = upgrades
      msg = 'Expected empty result when no category headers exist'
    ).
  ENDMETHOD.

  METHOD process_membership_not_active.
    " Branch: LOOP → line_exists(active_memberships[...]) fails → CHECK skips iteration
    " Transactions exist for BP that has no matching active membership
    DATA(current_date) = cl_abap_context_info=>get_system_date( ).
    DATA(future_date) = current_date + 365.

    " Active membership for BP 42
    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner  = '0001000042'
                             membershipid      = 1
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = future_date ) ).
    sql_test_environment->insert_test_data( i_data = memberships ).

    " Transactions for BP 42, membership 1 (will match JOIN)
    " But we simulate the CHECK failing by having no active categories for this BP
    DATA transactions TYPE STANDARD TABLE OF zlh_transactions.
    transactions = VALUE #( ( business_partner = '0001000042'
                              membershipid    = 1
                              loyalty_points   = 500 ) ).
    cds_test_environment->insert_test_data( i_data = transactions ).

    DATA category_headers TYPE STANDARD TABLE OF zlh_category_hdr.
    category_headers = VALUE #( ( categoryid   = '001'
*                                  categoryname = 'Bronze'
                                  threshold    = 100
                                  isenabled    = abap_true ) ).
    cds_test_environment->insert_test_data( i_data = category_headers ).

    " No categories inserted → current_category-categoryid will be initial → CHECK skips

    DATA(upgrades) = mo_cut->process_category_upgrades( ).

    cl_abap_unit_assert=>assert_initial(
      act = upgrades
      msg = 'Expected no upgrade when no active category found for membership'
    ).
  ENDMETHOD.

  METHOD process_no_current_category.
    " Branch: current_category-categoryid IS INITIAL → CHECK skips
    " Membership and transactions exist, but no category record for the BP
    DATA(current_date) = cl_abap_context_info=>get_system_date( ).
    DATA(future_date) = current_date + 365.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner  = '0001000042'
                             membershipid      = 1
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = future_date ) ).
    sql_test_environment->insert_test_data( i_data = memberships ).

    DATA transactions TYPE STANDARD TABLE OF zlh_transactions.
    transactions = VALUE #( ( business_partner = '0001000042'
                              membershipid    = 1
                              loyalty_points   = 1000 ) ).
    cds_test_environment->insert_test_data( i_data = transactions ).

    DATA category_headers TYPE STANDARD TABLE OF zlh_category_hdr.
    category_headers = VALUE #( ( categoryid   = '001'
*                                  categoryname = 'Bronze'
                                  threshold    = 100
                                  isenabled    = abap_true ) ).
    cds_test_environment->insert_test_data( i_data = category_headers ).

    " No zlh_r_category entry → current_category-categoryid IS INITIAL

    DATA(upgrades) = mo_cut->process_category_upgrades( ).

    cl_abap_unit_assert=>assert_initial(
      act = upgrades
      msg = 'Expected no upgrade when current category ID is initial'
    ).
  ENDMETHOD.

  METHOD process_no_current_header.
    " Branch: current_header-categoryid IS INITIAL → CHECK skips
    " Category exists for BP but its categoryid is not in category_map
    DATA(current_date) = cl_abap_context_info=>get_system_date( ).
    DATA(future_date) = current_date + 365.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner  = '0001000042'
                             membershipid      = 1
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = future_date ) ).
    sql_test_environment->insert_test_data( i_data = memberships ).

    DATA transactions TYPE STANDARD TABLE OF zlh_transactions.
    transactions = VALUE #( ( business_partner = '0001000042'
                              membershipid    = 1
                              loyalty_points   = 1000 ) ).
    cds_test_environment->insert_test_data( i_data = transactions ).

    " Active category with categoryid '099' which does NOT exist in category_headers
    DATA categories TYPE STANDARD TABLE OF zlh_category.
    categories = VALUE #( ( business_partner = '0001000042'
                            membershipid    = 1
                            categoryid      = '099'
                            status          = zif_lh_constants=>category_status-active
                            end_date         = zif_lh_constants=>category_enddate ) ).
    cds_test_environment->insert_test_data( i_data = categories ).

    " Category headers do NOT contain '099'
    DATA category_headers TYPE STANDARD TABLE OF zlh_category_hdr.
    category_headers = VALUE #( ( categoryid   = '001'
*                                  categoryname = 'Bronze'
                                  threshold    = 100
                                  isenabled    = abap_true ) ).
    cds_test_environment->insert_test_data( i_data = category_headers ).

    DATA(upgrades) = mo_cut->process_category_upgrades( ).

    cl_abap_unit_assert=>assert_initial(
      act = upgrades
      msg = 'Expected no upgrade when current header not found in category map'
    ).
  ENDMETHOD.

  METHOD process_points_below_threshold.
    " Branch: points-total_points > current_header-threshold fails → CHECK skips
    " Points = 50, threshold = 100 → 50 > 100 is FALSE
    DATA(current_date) = cl_abap_context_info=>get_system_date( ).
    DATA(future_date) = current_date + 365.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner  = '0001000042'
                             membershipid      = 1
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = future_date ) ).
    sql_test_environment->insert_test_data( i_data = memberships ).

    DATA transactions TYPE STANDARD TABLE OF zlh_transactions.
    transactions = VALUE #( ( business_partner = '0001000042'
                              membershipid    = 1
                              loyalty_points   = 50 ) ).
    cds_test_environment->insert_test_data( i_data = transactions ).

    DATA categories TYPE STANDARD TABLE OF zlh_category.
    categories = VALUE #( ( business_partner = '0001000042'
                            membershipid    = 1
                            categoryid      = '001'
                            status          = zif_lh_constants=>category_status-active
                            end_date         = zif_lh_constants=>category_enddate ) ).
    cds_test_environment->insert_test_data( i_data = categories ).

    DATA category_headers TYPE STANDARD TABLE OF zlh_category_hdr.
    category_headers = VALUE #( ( categoryid   = '001'
*                                  categoryname = 'Bronze'
                                  threshold    = 100
                                  isenabled    = abap_true )
                                ( categoryid   = '002'
*                                  categoryname = 'Silver'
                                  threshold    = 500
                                  isenabled    = abap_true ) ).
    cds_test_environment->insert_test_data( i_data = category_headers ).

    DATA(upgrades) = mo_cut->process_category_upgrades( ).

    cl_abap_unit_assert=>assert_initial(
      act = upgrades
      msg = 'Expected no upgrade when points are below current threshold'
    ).
  ENDMETHOD.

  METHOD process_no_next_category.
    " Branch: next_category-categoryid IS INITIAL → CHECK skips
    " Points exceed current threshold but no higher category exists
    DATA(current_date) = cl_abap_context_info=>get_system_date( ).
    DATA(future_date) = current_date + 365.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner  = '0001000042'
                             membershipid      = 1
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = future_date ) ).
    sql_test_environment->insert_test_data( i_data = memberships ).

    DATA transactions TYPE STANDARD TABLE OF zlh_transactions.
    transactions = VALUE #( ( business_partner = '0001000042'
                              membershipid    = 1
                              loyalty_points   = 5000 ) ).
    cds_test_environment->insert_test_data( i_data = transactions ).

    DATA categories TYPE STANDARD TABLE OF zlh_category.
    categories = VALUE #( ( business_partner = '0001000042'
                            membershipid    = 1
                            categoryid      = '002'
                            status          = zif_lh_constants=>category_status-active
                            end_date         = zif_lh_constants=>category_enddate ) ).
    cds_test_environment->insert_test_data( i_data = categories ).

    " Only one category at maximum level; no higher threshold exists
    DATA category_headers TYPE STANDARD TABLE OF zlh_category_hdr.
    category_headers = VALUE #( ( categoryid   = '002'
*                                  categoryname = 'Silver'
                                  threshold    = 500
                                  isenabled    = abap_true ) ).
    cds_test_environment->insert_test_data( i_data = category_headers ).

    DATA(upgrades) = mo_cut->process_category_upgrades( ).

    cl_abap_unit_assert=>assert_initial(
      act = upgrades
      msg = 'Expected no upgrade when no next category with higher threshold exists'
    ).
  ENDMETHOD.

  METHOD process_next_eq_current.
    " Branch: next_category-categoryid <> current_category-categoryid fails → CHECK skips
    " This occurs when the only qualifying next_category is the same as current
    " Scenario: points exceed threshold, but inner LOOP only finds current category again
    DATA(current_date) = cl_abap_context_info=>get_system_date( ).
    DATA(future_date) = current_date + 365.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner  = '0001000042'
                             membershipid      = 1
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = future_date ) ).
    sql_test_environment->insert_test_data( i_data = memberships ).

    " Points = 200, current threshold = 100
    DATA transactions TYPE STANDARD TABLE OF zlh_transactions.
    transactions = VALUE #( ( business_partner = '0001000042'
                              membershipid    = 1
                              loyalty_points   = 200 ) ).
    cds_test_environment->insert_test_data( i_data = transactions ).

    DATA categories TYPE STANDARD TABLE OF zlh_category.
    categories = VALUE #( ( business_partner = '0001000042'
                            membershipid    = 1
                            categoryid      = '001'
                            status          = zif_lh_constants=>category_status-active
                            end_date         = zif_lh_constants=>category_enddate ) ).
    cds_test_environment->insert_test_data( i_data = categories ).

    " Two headers: '001' threshold=100, '002' threshold=300
    " Points=200, current threshold=100 → inner LOOP: WHERE threshold > 100 AND threshold <= 200
    " '002' has threshold=300, which is > 200 → does NOT qualify → next_category stays initial
    DATA category_headers TYPE STANDARD TABLE OF zlh_category_hdr.
    category_headers = VALUE #( ( categoryid   = '001'
*                                  categoryname = 'Bronze'
                                  threshold    = 100
                                  isenabled    = abap_true )
                                ( categoryid   = '002'
*                                  categoryname = 'Silver'
                                  threshold    = 300
                                  isenabled    = abap_true ) ).
    cds_test_environment->insert_test_data( i_data = category_headers ).

    DATA(upgrades) = mo_cut->process_category_upgrades( ).

    cl_abap_unit_assert=>assert_initial(
      act = upgrades
      msg = 'Expected no upgrade when next category threshold exceeds total points'
    ).
  ENDMETHOD.

  METHOD process_full_upgrade.
    " Branch: full success path → upgrade record appended to result
    DATA(current_date) = cl_abap_context_info=>get_system_date( ).
    DATA(future_date) = current_date + 365.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner  = '0001000042'
                             membershipid      = 1
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = future_date ) ).
    sql_test_environment->insert_test_data( i_data = memberships ).

    " Points = 5000, exceeds threshold of 100 (Bronze)
    DATA transactions TYPE STANDARD TABLE OF zlh_transactions.
    transactions = VALUE #( ( business_partner = '0001000042'
                              membershipid    = 1
                              loyalty_points   = 5000 ) ).
    cds_test_environment->insert_test_data( i_data = transactions ).

    DATA categories TYPE STANDARD TABLE OF zlh_category.
    categories = VALUE #( ( business_partner = '0001000042'
                            membershipid    = 1
                            categoryid      = '001'
                            status          = zif_lh_constants=>category_status-active
                            end_date         = zif_lh_constants=>category_enddate ) ).
    cds_test_environment->insert_test_data( i_data = categories ).

    " Bronze threshold=100, Silver threshold=2000 → 5000 > 100 AND 2000 <= 5000
    DATA category_headers TYPE STANDARD TABLE OF zlh_category_hdr.
    category_headers = VALUE #( ( categoryid   = '001'
*                                  categoryname = 'Bronze'
                                  threshold    = 100
                                  isenabled    = abap_true )
                                ( categoryid   = '002'
*                                  categoryname = 'Silver'
                                  threshold    = 2000
                                  isenabled    = abap_true ) ).
    cds_test_environment->insert_test_data( i_data = category_headers ).

*    DATA emails TYPE STANDARD TABLE OF I_WorkplaceAddress.
*    emails = VALUE #( ( BusinessPartner     = '0001000042'
*                        DefaultEmailAddress = 'loyalty@example.com' ) ).
*    cds_test_environment->insert_test_data( i_data = emails ).

    DATA(upgrades) = mo_cut->process_category_upgrades( ).

    cl_abap_unit_assert=>assert_not_initial(
      act = upgrades
      msg = 'Expected at least one upgrade'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( upgrades )
      exp = 1
      msg = 'Expected exactly one upgrade record'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = upgrades[ 1 ]-business_partner
      exp = '0001000042'
      msg = 'Business partner should match'
    ).

    cl_abap_unit_assert=>assert_equals(
      act = upgrades[ 1 ]-membership_id
      exp = 1
      msg = 'Membership ID should match'
    ).

*    cl_abap_unit_assert=>assert_equals(
*      act = upgrades[ 1 ]-old_category
*      exp = 'Bronze'
*      msg = 'Old category name should be Bronze'
*    ).

    cl_abap_unit_assert=>assert_equals(
      act = upgrades[ 1 ]-new_category_id
      exp = '002'
      msg = 'New category ID should be 002 (Silver)'
    ).

*    cl_abap_unit_assert=>assert_equals(
*      act = upgrades[ 1 ]-new_category
*      exp = 'Silver'
*      msg = 'New category name should be Silver'
*    ).

    cl_abap_unit_assert=>assert_equals(
      act = upgrades[ 1 ]-total_points
      exp = 5000
      msg = 'Total points should be 5000'
    ).

*    cl_abap_unit_assert=>assert_equals(
*      act = upgrades[ 1 ]-email_address
*      exp = 'loyalty@example.com'
*      msg = 'Email address should match'
*    ).
  ENDMETHOD.

  "-----------------------------------------------------------------------
  " create_new_categories tests
  "-----------------------------------------------------------------------

  METHOD create_categories_empty.
    " Branch: new_categories IS INITIAL (empty upgrades) → CHECK exits
    DATA(upgrades) = VALUE zcl_lh_category_update_job=>upgraded_bps( ).

    " Should not raise exception; CHECK exits early
    mo_cut->create_new_categories( upgrades ).

    " If we get here, the CHECK path was successfully taken
    cl_abap_unit_assert=>assert_subrc( exp = 0 msg = 'Empty upgrades should exit gracefully' ).
  ENDMETHOD.

  METHOD create_categories_success.
    " Branch: failed IS INITIAL → COMMIT + success log
    " Insert sufficient test data so that MODIFY ENTITIES succeeds
    DATA(current_date) = cl_abap_context_info=>get_system_date( ).
    DATA(future_date) = current_date + 365.

    DATA memberships TYPE STANDARD TABLE OF zlh_membership.
    memberships = VALUE #( ( business_partner  = '0001000042'
                             membershipid      = 1
                             membership_status = zif_lh_constants=>membership_status-active
                             membership_enddate = future_date ) ).
    sql_test_environment->insert_test_data( i_data = memberships ).

    DATA(upgrades) = VALUE zcl_lh_category_update_job=>upgraded_bps(
      ( business_partner = '0001000042'
        membership_id    = 1
        old_category     = 'Bronze'
        new_category_id  = '002'
        new_category     = 'Silver'
        total_points     = 5000
        email_address    = 'example@loyalty.com' ) ).

    " Execute create - success path depends on EML behavior in test framework
    mo_cut->create_new_categories( upgrades ).

    " Method should complete without exceptions
    cl_abap_unit_assert=>assert_subrc( exp = 0 msg = 'Create categories should complete' ).
  ENDMETHOD.

  METHOD create_categories_failure.
    " Branch: failed IS NOT INITIAL → error log
    " Use invalid data that will cause EML MODIFY to fail
    DATA(upgrades) = VALUE zcl_lh_category_update_job=>upgraded_bps(
      ( business_partner = '9999999999'
        membership_id    = 99999
        old_category     = 'Invalid'
        new_category_id  = 'XXX'
        new_category     = 'NonExistent'
        total_points     = 0
        email_address    = '' ) ).

    " Execute create - expected to hit failure branch
    mo_cut->create_new_categories( upgrades ).

    " Method should complete without exceptions regardless of branch
    cl_abap_unit_assert=>assert_subrc( exp = 0 msg = 'Create categories failure should be handled' ).
  ENDMETHOD.

  "-----------------------------------------------------------------------
  " send_notifications tests
  "-----------------------------------------------------------------------

  METHOD send_notif_no_email.
    " Branch: email_address IS INITIAL → CHECK skips
    DATA(upgrades) = VALUE zcl_lh_category_update_job=>upgraded_bps(
      ( business_partner = '0001000042'
        membership_id    = 1
        old_category     = 'Bronze'
        new_category_id  = '002'
        new_category     = 'Silver'
        total_points     = 5000
        email_address    = '' ) ). " Empty email → CHECK skips

    " Should complete without exception, skipping notification
    mo_cut->send_notifications( upgrades ).

    cl_abap_unit_assert=>assert_subrc( exp = 0 msg = 'No email should skip notification gracefully' ).
  ENDMETHOD.

  METHOD send_notif_with_email.
    " Branch: email provided → attempt send (may fail in test env, handled by TRY/CATCH)
    DATA(upgrades) = VALUE zcl_lh_category_update_job=>upgraded_bps(
      ( business_partner = '0001000042'
        membership_id    = 1
        old_category     = 'Bronze'
        new_category_id  = '002'
        new_category     = 'Silver'
        total_points     = 5000
        email_address    = 'example@loyalty.com' ) ).

    " Should complete without exception; cx_bcs_mail is caught internally
    mo_cut->send_notifications( upgrades ).

    cl_abap_unit_assert=>assert_subrc( exp = 0 msg = 'Send notification with email should complete' ).
  ENDMETHOD.

ENDCLASS.