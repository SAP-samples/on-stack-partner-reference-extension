*"* use this source file for your ABAP unit test classes

CLASS ltc_salesorder_integration DEFINITION FINAL FOR TESTING
	DURATION SHORT
	RISK LEVEL HARMLESS.

	PRIVATE SECTION.
		CLASS-DATA go_env TYPE REF TO if_osql_test_environment.

		CLASS-METHODS class_setup.
		CLASS-METHODS class_teardown.

		METHODS setup.
		METHODS teardown.

		METHODS on_created_builds_tx FOR TESTING.
		METHODS on_created_skips_incomp FOR TESTING.
		METHODS on_updated_sets_draft FOR TESTING.
		METHODS on_updated_skips_exist FOR TESTING.
ENDCLASS.

CLASS ltc_salesorder_integration IMPLEMENTATION.

	METHOD class_setup.
		go_env = cl_osql_test_environment=>create(
			i_dependency_list = VALUE #( ( 'I_SALESORDERTP' )
																	 ( 'ZLH_R_MEMBERSHIP' )
												 ( 'ZLH_R_TRANSACTIONS' ) ) ).
	ENDMETHOD.


	METHOD class_teardown.
		go_env->destroy( ).
	ENDMETHOD.


	METHOD setup.
		go_env->clear_doubles( ).
		CLEAR: lcl_test_probe=>created_count,
				 lcl_test_probe=>created_ref,
				 lcl_test_probe=>updated_count,
				 lcl_test_probe=>updated_ref,
				 lcl_test_probe=>updated_draft.
	ENDMETHOD.


	METHOD teardown.
		go_env->clear_doubles( ).
	ENDMETHOD.


	METHOD on_created_builds_tx.
		DATA lt_so TYPE STANDARD TABLE OF i_salesordertp WITH EMPTY KEY.
		DATA lt_membership TYPE STANDARD TABLE OF zlh_r_membership WITH EMPTY KEY.

		lt_so = VALUE #(
			( SoldToParty = 'BP00000001'
				SalesOrder = 'SO00000001'
				TotalNetAmount = '100.00'
				TransactionCurrency = 'EUR'
				HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status ) ).

		lt_membership = VALUE #(
			( BusinessPartner = 'BP00000001'
				MembershipEndDate = zif_lh_constants=>membership_enddate ) ).

		go_env->insert_test_data( lt_so ).
		go_env->insert_test_data( lt_membership ).

		TEST-INJECTION created_modify_entities.
			lcl_test_probe=>created_count = lines( loyalty_transactions ).
			READ TABLE loyalty_transactions ASSIGNING FIELD-SYMBOL(<tx>) INDEX 1.
			IF sy-subrc = 0.
				READ TABLE <tx>-%target ASSIGNING FIELD-SYMBOL(<target>) INDEX 1.
				IF sy-subrc = 0.
					lcl_test_probe=>created_ref = <target>-RefSalesorderId.
				ENDIF.
			ENDIF.
		END-TEST-INJECTION.

		lcl_soi_executor=>execute_created( it_salesorder_ids = VALUE #( ( 'SO00000001' ) ) ).

		cl_abap_unit_assert=>assert_equals( act = lcl_test_probe=>created_count exp = 1 ).
		cl_abap_unit_assert=>assert_equals( act = lcl_test_probe=>created_ref exp = 'SO00000001' ).
	ENDMETHOD.


	METHOD on_created_skips_incomp.
		DATA lt_so TYPE STANDARD TABLE OF i_salesordertp WITH EMPTY KEY.
		DATA lt_membership TYPE STANDARD TABLE OF zlh_r_membership WITH EMPTY KEY.

		lt_so = VALUE #(
			( SoldToParty = 'BP00000002'
				SalesOrder = 'SO00000002'
				TotalNetAmount = '80.00'
				TransactionCurrency = 'EUR'
				HdrGeneralIncompletionStatus = 'X' ) ).

		lt_membership = VALUE #(
			( BusinessPartner = 'BP00000002'
				MembershipEndDate = zif_lh_constants=>membership_enddate ) ).

		go_env->insert_test_data( lt_so ).
		go_env->insert_test_data( lt_membership ).

		TEST-INJECTION created_modify_entities.
			lcl_test_probe=>created_count = lines( loyalty_transactions ).
		END-TEST-INJECTION.

		lcl_soi_executor=>execute_created( it_salesorder_ids = VALUE #( ( 'SO00000002' ) ) ).

		cl_abap_unit_assert=>assert_equals( act = lcl_test_probe=>created_count exp = 0 ).
	ENDMETHOD.


	METHOD on_updated_sets_draft.
		DATA lt_so TYPE STANDARD TABLE OF i_salesordertp WITH EMPTY KEY.
		DATA lt_membership TYPE STANDARD TABLE OF zlh_r_membership WITH EMPTY KEY.

		lt_so = VALUE #(
			( SoldToParty = 'BP00000003'
				SalesOrder = 'SO00000003'
				TotalNetAmount = '90.00'
				TransactionCurrency = 'EUR'
				HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status ) ).

		lt_membership = VALUE #(
			( BusinessPartner = 'BP00000003'
				MembershipEndDate = zif_lh_constants=>membership_enddate ) ).

		go_env->insert_test_data( lt_so ).
		go_env->insert_test_data( lt_membership ).

		TEST-INJECTION updated_modify_entities.
			lcl_test_probe=>updated_count = lines( loyalty_transactions ).
			READ TABLE loyalty_transactions ASSIGNING FIELD-SYMBOL(<tx>) INDEX 1.
			IF sy-subrc = 0.
				lcl_test_probe=>updated_draft = <tx>-%is_draft.
				READ TABLE <tx>-%target ASSIGNING FIELD-SYMBOL(<target>) INDEX 1.
				IF sy-subrc = 0.
					lcl_test_probe=>updated_ref = <target>-RefSalesorderId.
				ENDIF.
			ENDIF.
		END-TEST-INJECTION.

		lcl_soi_executor=>execute_updated( it_salesorder_ids = VALUE #( ( 'SO00000003' ) ) ).

		cl_abap_unit_assert=>assert_equals( act = lcl_test_probe=>updated_count exp = 1 ).
		cl_abap_unit_assert=>assert_equals( act = lcl_test_probe=>updated_ref exp = 'SO00000003' ).
		cl_abap_unit_assert=>assert_equals( act = lcl_test_probe=>updated_draft exp = if_abap_behv=>mk-off ).
	ENDMETHOD.


	METHOD on_updated_skips_exist.
		DATA lt_so TYPE STANDARD TABLE OF i_salesordertp WITH EMPTY KEY.
		DATA lt_membership TYPE STANDARD TABLE OF zlh_r_membership WITH EMPTY KEY.
		DATA lt_tx TYPE STANDARD TABLE OF zlh_r_transactions WITH EMPTY KEY.

		lt_so = VALUE #(
			( SoldToParty = 'BP00000004'
				SalesOrder = 'SO00000004'
				TotalNetAmount = '70.00'
				TransactionCurrency = 'EUR'
				HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status ) ).

		lt_membership = VALUE #(
			( BusinessPartner = 'BP00000004'
				MembershipEndDate = zif_lh_constants=>membership_enddate ) ).

		lt_tx = VALUE #(
			( RefSalesorderId = 'SO00000004' ) ).

		go_env->insert_test_data( lt_so ).
		go_env->insert_test_data( lt_membership ).
		go_env->insert_test_data( lt_tx ).

		TEST-INJECTION updated_modify_entities.
			lcl_test_probe=>updated_count = lines( loyalty_transactions ).
		END-TEST-INJECTION.

		lcl_soi_executor=>execute_updated( it_salesorder_ids = VALUE #( ( 'SO00000004' ) ) ).

		cl_abap_unit_assert=>assert_equals( act = lcl_test_probe=>updated_count exp = 0 ).
	ENDMETHOD.

ENDCLASS.