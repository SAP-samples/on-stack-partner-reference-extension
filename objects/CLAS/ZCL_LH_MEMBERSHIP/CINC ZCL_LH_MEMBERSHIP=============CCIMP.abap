CLASS lhc_zlh_r_membership DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS SetDefaultValuesOnCreate FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ZLH_R_Membership~SetDefaultValuesOnCreate.

ENDCLASS.

CLASS lhc_zlh_r_membership IMPLEMENTATION.

  METHOD SetDefaultValuesOnCreate.

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
    ENTITY ZLH_R_Membership
    ALL FIELDS WITH CORRESPONDING #( keys )
     RESULT DATA(memberships).

    DATA: new_category TYPE TABLE FOR CREATE ZLH_R_Membership\_Category.

    SELECT SINGLE categoryid FROM zlh_r_category_hdr
      WHERE Isdefault EQ @abap_true
      INTO @DATA(defaultcategory).
    IF sy-subrc IS INITIAL.
      new_category = VALUE #( (   %tky-MembershipID = keys[ 1 ]-MembershipID
                                  %is_draft = keys[ 1 ]-%is_draft
                                  %target = VALUE #( ( %cid = 'CID'
                                                       %is_draft = keys[ 1 ]-%is_draft
                                                       BusinessPartner = memberships[ 1 ]-BusinessPartner
                                                       CategoryID = defaultcategory
                                                       Status = zif_lh_constants=>category_status-active
                                                       StartDate = cl_abap_context_info=>get_system_date( )
                                                       EndDate = zif_lh_constants=>category_enddate
                                                       %control-BusinessPartner = if_abap_behv=>mk-on
                                                       %control-CategoryID = if_abap_behv=>mk-on
                                                       %control-status = if_abap_behv=>mk-on
                                                       %control-StartDate = if_abap_behv=>mk-on
                                                       %control-EndDate = if_abap_behv=>mk-on ) ) ) ).
      MODIFY ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY ZLH_R_Membership
      CREATE BY \_Category
      FROM new_category
      FAILED DATA(failed).
    ENDIF.

  ENDMETHOD.

ENDCLASS.

*CLASS lhc_membership DEFINITION INHERITING FROM cl_abap_behavior_handler.
*
*  PRIVATE SECTION.
*
**    METHODS VerifyMembership FOR VALIDATE ON SAVE
**      IMPORTING keys FOR Membership~VerifyMembership.
*
*
*ENDCLASS.
*
*CLASS lhc_membership IMPLEMENTATION.
*
**  METHOD VerifyMembership.
**  ENDMETHOD.
*
*
*ENDCLASS.
*
**"* use this source file for the definition and implementation of
**"* local helper classes, interface definitions and type
**"* declarations