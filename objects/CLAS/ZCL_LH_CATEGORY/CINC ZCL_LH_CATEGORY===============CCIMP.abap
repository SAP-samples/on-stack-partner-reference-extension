**"* use this source file for the definition and implementation of
**"* local helper classes, interface definitions and type
**"* declarations
*
CLASS ltcl_category_filldefaults DEFINITION DEFERRED FOR TESTING.

CLASS lhc_category DEFINITION INHERITING FROM cl_abap_behavior_handler
FRIENDS: ltcl_category_filldefaults .

  PRIVATE SECTION.

    METHODS fillDefaultValues FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zlh_r_category~fillDefaultValues.

ENDCLASS.

CLASS lhc_category IMPLEMENTATION.

  METHOD fillDefaultValues.
    DATA: updated_categories TYPE TABLE FOR UPDATE zlh_r_category.

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY ZLH_R_Membership
      BY \_Category
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(Categories).

    LOOP AT Categories INTO DATA(category).
      IF line_exists( keys[ KEY entity COMPONENTS
                            CategoryID = category-CategoryID
                            MembershipID = category-MembershipID ] ).
        APPEND INITIAL LINE TO updated_categories ASSIGNING FIELD-SYMBOL(<category>).
        MOVE-CORRESPONDING category TO <category>.
*        <category>-%tky = keys[ 1 ]-%tky.
        <category>-Status = COND #( WHEN <category>-Status IS INITIAL
                                      THEN zif_lh_constants=>category_status-active
                                      ELSE <category>-Status ).
        <category>-StartDate = COND #( WHEN <category>-StartDate IS INITIAL
                                         THEN cl_abap_context_info=>get_system_date( )
                                         ELSE <category>-StartDate ).
        <category>-EndDate = COND #( WHEN <category>-EndDate IS INITIAL
                                       THEN zif_lh_constants=>category_enddate
                                       ELSE <category>-EndDate ).
        <category>-StatusCriticality = 3.
        UNASSIGN <category>.
      ELSEIF  category-EndDate EQ zif_lh_constants=>category_enddate.
        APPEND INITIAL LINE TO updated_categories ASSIGNING <category>.
        MOVE-CORRESPONDING category TO <category>.
        <category>-EndDate = cl_abap_context_info=>get_system_date( ).
        <category>-Status = zif_lh_constants=>category_status-inactive.
        <category>-StatusCriticality = 0.
        UNASSIGN <category>.
      ENDIF.
    ENDLOOP.

    IF updated_categories IS NOT INITIAL.
      MODIFY ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
        ENTITY zlh_r_category
        UPDATE FIELDS ( Status StartDate EndDate StatusCriticality )
        WITH updated_categories.
    ENDIF.

  ENDMETHOD.

ENDCLASS.