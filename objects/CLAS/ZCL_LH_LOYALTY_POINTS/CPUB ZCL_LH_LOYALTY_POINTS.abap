CLASS zcl_lh_loyalty_points DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF loyalty_point,
             business_partner TYPE zlh_businesspartner,
             available        TYPE zlh_loyaltypoint,
             redeemed         TYPE zlh_loyaltypoint,
           END OF loyalty_point,
           loyalty_points TYPE HASHED TABLE OF loyalty_point WITH UNIQUE KEY business_partner,

           BEGIN OF business_partner,
             sold_to_party TYPE zlh_businesspartner,
           END OF business_partner,
           business_partner_keys TYPE SORTED TABLE OF business_partner WITH UNIQUE KEY sold_to_party.

    CLASS-METHODS get_points
      IMPORTING
        business_partners TYPE business_partner_keys
      RETURNING
        VALUE(points)     TYPE loyalty_points.
