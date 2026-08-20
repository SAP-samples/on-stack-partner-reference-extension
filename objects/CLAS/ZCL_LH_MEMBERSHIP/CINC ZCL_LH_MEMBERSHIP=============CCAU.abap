CLASS ltcl_membership_determination DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-DATA:
      go_sql_env TYPE REF TO if_osql_test_environment,
      go_cds_env TYPE REF TO if_cds_test_environment.

    CLASS-METHODS:
      class_setup,
      class_teardown.

    METHODS:
      setup,
      teardown,
      test_default_no_category FOR TESTING.
ENDCLASS.

CLASS ltcl_membership_determination IMPLEMENTATION.

  METHOD class_setup.
    " SQL double for category header table (kept empty in test)
    go_sql_env = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #( ( 'ZLH_R_CATEGORY_HDR' ) ( 'ZLH_R_BUSINESSPARTNER' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    go_sql_env->destroy( ).
  ENDMETHOD.

  METHOD setup.
    DATA: businesspartner type TABLE of ZLH_R_BUSINESSPARTNER.
    businesspartner = VALUE #( ( SoldToParty         = '0000000001' ) ).
    go_sql_env->clear_doubles( ).
    go_sql_env->insert_test_data( businesspartner ).
  ENDMETHOD.

  METHOD teardown.
  ENDMETHOD.

  METHOD test_default_no_category.
    DATA memberships_create TYPE TABLE FOR CREATE zlh_r_businesspartner\_MemberShip.

    " No default category inserted -> determination must not create category

    " Create Membership only through BusinessPartner association
    memberships_create = VALUE #(
      (
        %tky-SoldToParty = '0000000001'
        %is_draft        = if_abap_behv=>mk-off
        %target          = VALUE #(
          (
            %cid                       = 'cid'
            %is_draft                  = if_abap_behv=>mk-off
            MemberSince                = cl_abap_context_info=>get_system_date( )
            MembershipEndDate          = '99991231'
            MembershipStatus           = 'A'
            %control-MemberSince       = if_abap_behv=>mk-on
            %control-MembershipStatus  = if_abap_behv=>mk-on
            %control-MembershipEndDate = if_abap_behv=>mk-on
          )
        )
      )
    ).

    MODIFY ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY ZLH_R_BusinessPartner
      CREATE BY \_MemberShip
      FROM memberships_create
      MAPPED   DATA(mapped_create)
      FAILED   DATA(failed_create)
      REPORTED DATA(reported_create).

    cl_abap_unit_assert=>assert_initial( act = failed_create ).

    " Read created membership from Business Partner
    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY ZLH_R_BusinessPartner
      BY \_MemberShip
      ALL FIELDS
      WITH VALUE #(
        (
          SoldToParty = '0000000001'
          %is_draft   = if_abap_behv=>mk-off
        )
      )
      RESULT DATA(lt_membership)
      FAILED DATA(failed_read_m)
      REPORTED DATA(reported_read_m).

    cl_abap_unit_assert=>assert_initial( act = failed_read_m ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_membership ) exp = 1 ).

    " Read category children for created membership -> expected 0
    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY ZLH_R_Membership
      BY \_Category
      ALL FIELDS
      WITH VALUE #(
        (
          MembershipID = lt_membership[ 1 ]-MembershipID
          %is_draft    = lt_membership[ 1 ]-%is_draft
        )
      )
      RESULT DATA(lt_category)
      FAILED DATA(failed_read_c)
      REPORTED DATA(reported_read_c).

    cl_abap_unit_assert=>assert_initial( act = failed_read_c ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_category ) exp = 0 ).
  ENDMETHOD.

ENDCLASS.