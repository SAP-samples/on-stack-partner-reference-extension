CLASS LHC_ZLH_R_CATEGORY_MAINT DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      AUGMENT_CATEGORYHEADER FOR MODIFY
        IMPORTING
          ENTITIES_CREATE FOR CREATE MaintainCategory\_CategoryHeader
          ENTITIES_UPDATE FOR UPDATE CategoryHeader.
ENDCLASS.

CLASS LHC_ZLH_R_CATEGORY_MAINT IMPLEMENTATION.
  METHOD AUGMENT_CATEGORYHEADER.
    DATA: text_for_new_entity      TYPE TABLE FOR CREATE ZLH_R_CATEGORY_HDR\_CategoryText,
          text_for_existing_entity TYPE TABLE FOR CREATE ZLH_R_CATEGORY_HDR\_CategoryText,
          text_update              TYPE TABLE FOR UPDATE ZLH_R_CATEGORY_TEXT.
    DATA: relates_create TYPE abp_behv_relating_tab,
          relates_update TYPE abp_behv_relating_tab,
          relates_cba    TYPE abp_behv_relating_tab.
    DATA: text_tky_link  TYPE STRUCTURE FOR READ LINK ZLH_R_CATEGORY_HDR\_CategoryText,
          text_tky       LIKE text_tky_link-target.

    LOOP AT entities_create INTO DATA(entity).
      DATA(tabix) = sy-tabix.
      LOOP AT entity-%TARGET ASSIGNING FIELD-SYMBOL(<target>).
        APPEND tabix TO relates_create.
        INSERT VALUE #( %CID_REF = <target>-%CID
                        %IS_DRAFT = <target>-%IS_DRAFT
                          %KEY-Categoryid = <target>-%KEY-Categoryid
                        %TARGET = VALUE #( (
                          %CID = |CREATETEXTCID{ tabix }_{ sy-tabix }|
                          %IS_DRAFT = <target>-%IS_DRAFT
                          Language = sy-langu
                          Categoryname = <target>-Categoryname
                          %CONTROL-Language = if_abap_behv=>mk-on
                          %CONTROL-Categoryname = <target>-%CONTROL-Categoryname ) ) )
                     INTO TABLE text_for_new_entity.
      ENDLOOP.
    ENDLOOP.
    MODIFY AUGMENTING ENTITIES OF ZLH_R_CATEGORY_MAINT
      ENTITY CategoryHeader
        CREATE BY \_CategoryText
        FROM text_for_new_entity
        RELATING TO entities_create BY relates_create.

    IF entities_update IS NOT INITIAL.
      READ ENTITIES OF ZLH_R_CATEGORY_MAINT
        ENTITY CategoryHeader BY \_CategoryText
          FROM CORRESPONDING #( entities_update )
          LINK DATA(link).
      LOOP AT entities_update INTO DATA(update) WHERE %CONTROL-Categoryname = if_abap_behv=>mk-on.
        tabix = sy-tabix.
        text_tky = CORRESPONDING #( update-%TKY MAPPING
                                                        Categoryid = Categoryid
                                    ).
        text_tky-Language = sy-langu.
        IF line_exists( link[ KEY draft source-%TKY  = CORRESPONDING #( update-%TKY )
                                        target-%TKY  = CORRESPONDING #( text_tky ) ] ).
          APPEND tabix TO relates_update.
          APPEND VALUE #( %TKY = CORRESPONDING #( text_tky )
                          %CID_REF = update-%CID_REF
                          Categoryname = update-Categoryname
                          %CONTROL = VALUE #( Categoryname = update-%CONTROL-Categoryname )
          ) TO text_update.
        ELSEIF line_exists(  text_for_new_entity[ KEY cid %IS_DRAFT = update-%IS_DRAFT
                                                          %CID_REF  = update-%CID_REF ] ).
          APPEND tabix TO relates_update.
          APPEND VALUE #( %TKY = CORRESPONDING #( text_tky )
                          %CID_REF = text_for_new_entity[ KEY cid %IS_DRAFT = update-%IS_DRAFT
                          %CID_REF = update-%CID_REF ]-%TARGET[ 1 ]-%CID
                          Categoryname = update-Categoryname
                          %CONTROL = VALUE #( Categoryname = update-%CONTROL-Categoryname )
          ) TO text_update.
        ELSE.
          APPEND tabix TO relates_cba.
          APPEND VALUE #( %TKY = CORRESPONDING #( update-%TKY )
                          %CID_REF = update-%CID_REF
                          %TARGET  = VALUE #( (
                            %CID = |UPDATETEXTCID{ tabix }|
                            Language = sy-langu
                            %IS_DRAFT = text_tky-%IS_DRAFT
                            Categoryname = update-Categoryname
                            %CONTROL-Language = if_abap_behv=>mk-on
                            %CONTROL-Categoryname = update-%CONTROL-Categoryname
                          ) )
          ) TO text_for_existing_entity.
        ENDIF.
      ENDLOOP.
      IF text_update IS NOT INITIAL.
        MODIFY AUGMENTING ENTITIES OF ZLH_R_CATEGORY_MAINT
          ENTITY CategoryText
            UPDATE FROM text_update
            RELATING TO entities_update BY relates_update.
      ENDIF.
      IF text_for_existing_entity IS NOT INITIAL.
        MODIFY AUGMENTING ENTITIES OF ZLH_R_CATEGORY_MAINT
          ENTITY CategoryHeader
            CREATE BY \_CategoryText
            FROM text_for_existing_entity
            RELATING TO entities_update BY relates_cba.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.