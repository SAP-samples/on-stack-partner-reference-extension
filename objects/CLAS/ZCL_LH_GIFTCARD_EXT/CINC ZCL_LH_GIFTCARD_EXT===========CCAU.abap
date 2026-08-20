*"* use this source file for your ABAP unit test classes
class lcl_giftcard DEFINITION FOR TESTING.
    PUBLIC SECTION.
        INTERFACES: zif_lh_giftcard_api PARTIALLY IMPLEMENTED.
        class-methods:
			factory RETURNING VALUE(ro_giftcard) TYPE REF TO zif_lh_giftcard_api,
			set_read_balance
				IMPORTING
					iv_balance  TYPE i_salesordertp-totalnetamount
					iv_currency TYPE i_salesordertp-transactioncurrency,
			set_redeem_failure
				IMPORTING
					iv_fail TYPE abap_bool,
			reset.
	PRIVATE SECTION.
		CLASS-DATA gv_balance TYPE i_salesordertp-totalnetamount.
		CLASS-DATA gv_currency TYPE i_salesordertp-transactioncurrency.
		CLASS-DATA gv_redeem_fail TYPE abap_bool.
ENDCLASS.
class lcl_giftcard IMPLEMENTATION.
    METHOD factory.
        CREATE OBJECT ro_giftcard TYPE lcl_giftcard.
    ENDMETHOD.
	METHOD set_read_balance.
		gv_balance = iv_balance.
		gv_currency = iv_currency.
	ENDMETHOD.
	METHOD set_redeem_failure.
		gv_redeem_fail = iv_fail.
	ENDMETHOD.
	METHOD reset.
		CLEAR: gv_balance, gv_currency, gv_redeem_fail.
	ENDMETHOD.
    METHOD zif_lh_giftcard_api~read_gift_card_balance.
		total_balance = gv_balance.
		currency = gv_currency.
    ENDMETHOD.
    METHOD zif_lh_giftcard_api~redeem_gift_card_amount.
		IF gv_redeem_fail = abap_true.
			RAISE EXCEPTION NEW zcx_lh_giftcard( textid = zcx_lh_giftcard=>no_gift_cards ).
		ENDIF.
    ENDMETHOD.
ENDCLASS.

CLASS ltc_gc_logic DEFINITION FINAL FOR TESTING
	DURATION SHORT
	RISK LEVEL HARMLESS.

	PRIVATE SECTION.
		CLASS-DATA go_env TYPE REF TO if_osql_test_environment.

		CLASS-METHODS class_setup.
		CLASS-METHODS class_teardown.

		METHODS setup.
		METHODS teardown.

		METHODS fail_amt_gt_balance FOR TESTING.
		METHODS fail_amt_gt_so FOR TESTING.
		METHODS fail_so_below_50 FOR TESTING.
		METHODS fail_amt_zero FOR TESTING.
		METHODS fail_redeem_error FOR TESTING.
		METHODS pass_valid_request FOR TESTING.
ENDCLASS.


CLASS ltc_gc_logic IMPLEMENTATION.

	METHOD class_setup.
		go_env = cl_osql_test_environment=>create(
			i_dependency_list = VALUE #( ( 'I_SALESORDERTP' ) ) ).
		zcl_lh_giftcard_api=>set_instance( lcl_giftcard=>factory( ) ).
	ENDMETHOD.


	METHOD class_teardown.
		go_env->destroy( ).
		zcl_lh_giftcard_api=>set_instance( NEW zcl_lh_giftcard_api( ) ).
	ENDMETHOD.


	METHOD setup.
		go_env->clear_doubles( ).
		lcl_giftcard=>reset( ).
	ENDMETHOD.


	METHOD teardown.
		go_env->clear_doubles( ).
	ENDMETHOD.


	METHOD fail_amt_gt_balance.
		DATA lt_so TYPE STANDARD TABLE OF i_salesordertp WITH EMPTY KEY.

		lt_so = VALUE #(
			( SalesOrder = 'SO10000001'
				SoldToParty = 'BP10000001'
				TransactionCurrency = 'EUR'
				TotalNetAmount = '100.00'
				HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status ) ).
		go_env->insert_test_data( lt_so ).

		lcl_giftcard=>set_read_balance( iv_balance = '50.00' iv_currency = 'EUR' ).

		DATA(ls_eval) = lcl_giftcard_logic=>evaluate(
			iv_salesorder_id = 'SO10000001'
			iv_giftcard_amount = '60.00' ).

		cl_abap_unit_assert=>assert_equals( act = ls_eval-error_no exp = '001' ).
	ENDMETHOD.


	METHOD fail_amt_gt_so.
		DATA lt_so TYPE STANDARD TABLE OF i_salesordertp WITH EMPTY KEY.

		lt_so = VALUE #(
			( SalesOrder = 'SO10000002'
				SoldToParty = 'BP10000002'
				TransactionCurrency = 'EUR'
				TotalNetAmount = '100.00'
				HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status ) ).
		go_env->insert_test_data( lt_so ).

		lcl_giftcard=>set_read_balance( iv_balance = '200.00' iv_currency = 'EUR' ).

		DATA(ls_eval) = lcl_giftcard_logic=>evaluate(
			iv_salesorder_id = 'SO10000002'
			iv_giftcard_amount = '150.00' ).

		cl_abap_unit_assert=>assert_equals( act = ls_eval-error_no exp = '018' ).
	ENDMETHOD.


	METHOD fail_so_below_50.
		DATA lt_so TYPE STANDARD TABLE OF i_salesordertp WITH EMPTY KEY.

		lt_so = VALUE #(
			( SalesOrder = 'SO10000003'
				SoldToParty = 'BP10000003'
				TransactionCurrency = 'EUR'
				TotalNetAmount = '40.00'
				HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status ) ).
		go_env->insert_test_data( lt_so ).

		lcl_giftcard=>set_read_balance( iv_balance = '200.00' iv_currency = 'EUR' ).

		DATA(ls_eval) = lcl_giftcard_logic=>evaluate(
			iv_salesorder_id = 'SO10000003'
			iv_giftcard_amount = '10.00' ).

		cl_abap_unit_assert=>assert_equals( act = ls_eval-error_no exp = '019' ).
	ENDMETHOD.


	METHOD fail_amt_zero.
		DATA lt_so TYPE STANDARD TABLE OF i_salesordertp WITH EMPTY KEY.

		lt_so = VALUE #(
			( SalesOrder = 'SO10000004'
				SoldToParty = 'BP10000004'
				TransactionCurrency = 'EUR'
				TotalNetAmount = '80.00'
				HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status ) ).
		go_env->insert_test_data( lt_so ).

		lcl_giftcard=>set_read_balance( iv_balance = '200.00' iv_currency = 'EUR' ).

		DATA(ls_eval) = lcl_giftcard_logic=>evaluate(
			iv_salesorder_id = 'SO10000004'
			iv_giftcard_amount = '0.00' ).

		cl_abap_unit_assert=>assert_equals( act = ls_eval-error_no exp = '000' ).
	ENDMETHOD.


	METHOD fail_redeem_error.
		DATA lt_so TYPE STANDARD TABLE OF i_salesordertp WITH EMPTY KEY.

		lt_so = VALUE #(
			( SalesOrder = 'SO10000005'
				SoldToParty = 'BP10000005'
				TransactionCurrency = 'EUR'
				TotalNetAmount = '90.00'
				HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status ) ).
		go_env->insert_test_data( lt_so ).

		lcl_giftcard=>set_read_balance( iv_balance = '200.00' iv_currency = 'EUR' ).
		lcl_giftcard=>set_redeem_failure( abap_true ).

		DATA(ls_eval) = lcl_giftcard_logic=>evaluate(
			iv_salesorder_id = 'SO10000005'
			iv_giftcard_amount = '10.00' ).

		cl_abap_unit_assert=>assert_equals( act = ls_eval-error_no exp = '003' ).
	ENDMETHOD.


	METHOD pass_valid_request.
		DATA lt_so TYPE STANDARD TABLE OF i_salesordertp WITH EMPTY KEY.

		lt_so = VALUE #(
			( SalesOrder = 'SO10000006'
				SoldToParty = 'BP10000006'
				TransactionCurrency = 'EUR'
				TotalNetAmount = '120.00'
				HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status ) ).
		go_env->insert_test_data( lt_so ).

		lcl_giftcard=>set_read_balance( iv_balance = '200.00' iv_currency = 'EUR' ).
		lcl_giftcard=>set_redeem_failure( abap_false ).

		DATA(ls_eval) = lcl_giftcard_logic=>evaluate(
			iv_salesorder_id = 'SO10000006'
			iv_giftcard_amount = '20.00' ).

		cl_abap_unit_assert=>assert_initial( act = ls_eval-error_no ).
		cl_abap_unit_assert=>assert_equals( act = ls_eval-should_modify exp = abap_true ).
		cl_abap_unit_assert=>assert_equals( act = ls_eval-soldtoparty exp = 'BP10000006' ).
		cl_abap_unit_assert=>assert_equals( act = ls_eval-currency exp = 'EUR' ).
	ENDMETHOD.

ENDCLASS.