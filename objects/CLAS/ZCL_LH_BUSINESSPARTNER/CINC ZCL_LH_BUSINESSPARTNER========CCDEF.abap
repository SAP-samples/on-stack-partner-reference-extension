*    LOOP AT entities INTO DATA(ls_entity).
*
**      TRY.
*          " Get next number from the number range object
*          cl_numberrange_runtime=>number_get(
*            EXPORTING
*              nr_range_nr       = '01'
*              object            = 'ZLH_MID'
*            IMPORTING
*              number            = DATA(number_range_key)
*              returncode        = DATA(number_range_return_code)
*              returned_quantity = DATA(number_range_returned_quantity)
*          ).
*
*
**        CATCH cx_numberrange INTO DATA(lx_nr).
**          " Raise RAP-compliant exception if numbering fails
**          RAISE EXCEPTION TYPE cx_abap_behavior_error
**            EXPORTING
**              textid = cx_abap_behavior_error=>others
**              previous = lx_nr.
**      ENDTRY.
*
*    ENDLOOP.*"* use this source file for any type of declarations (class
*"* definitions, interfaces or type declarations) you need for
*"* components in the private section