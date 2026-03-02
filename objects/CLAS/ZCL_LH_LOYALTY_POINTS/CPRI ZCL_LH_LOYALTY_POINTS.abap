  PRIVATE SECTION.
    CLASS-METHODS normalize_loyalty_points
      IMPORTING
        points                   TYPE zlh_loyaltypoint
      RETURNING
        VALUE(normalized_points) TYPE zlh_loyaltypoint.