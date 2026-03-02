managed with additional save implementation in class ZCL_LH_AdditonalSave unique;
strict ( 2 );
with draft;
define behavior for ZLH_R_BusinessPartner //alias <alias_name>
implementation in class ZCL_LH_BusinessPartner unique
with unmanaged save


lock master
total etag ETag
draft table zlh_d_buspartner
authorization master ( instance )

{

  create ( features : global );
  update ( features : global );
  delete( features : global );
  field ( readonly ) SoldToParty, ETag;
  association _Category { with draft; }
  association _GiftCard { create(precheck){default function GetDefaultsForGiftCard;} with draft; }
  association _MemberShip { create; with draft; }
  association _Transactions { create(precheck); with draft; }
  action ( features : instance ) createMembership result [1] $self;
  action ( features : instance ) deleteMembership result [1] $self;
  action ( features : instance ) createCategory parameter ZLH_D_LHCREATECATEGORYP;

  side effects { action createMembership affects entity _Category;
                 action createCategory affects entity _Category;
                 action deleteMembership affects entity _GiftCard, entity _Category;
                 }
    draft action ( authorization : update, features : instance ) Edit;

  draft determine action Prepare
  {
    validation ZLH_R_TRANSACTIONS~validate_transaction_data;
    validation ZLH_R_GIFTCARD~validateGiftCardFields;
    validation ZLH_R_GIFTCARD~validateGiftcardBalance;
  }
  draft action Activate;
  draft action Resume;
  draft action Discard;
}

define behavior for ZLH_R_GIFTCARD
implementation in class ZCL_LH_GiftCard unique
persistent table zlh_giftcard
draft table zlh_d_giftcard
lock dependent by _BP
early numbering
authorization dependent by _BP
{
  update (precheck);
  delete;
  field ( mandatory : create ) GiftcardValue, SapDescription;
  field ( readonly ) Giftcardnumber, BusinessPartner, CreatedBy, LastChangedat, LastChangedby;
  field ( features : instance ) GiftcardValue, SapDescription, GiftcardCurrency;
  determination setGiftcardBalanceOnCreate on modify { field GiftCardValue; create; }
  determination setGiftcardFieldsOnCreate on modify { create; }
  determination addTransactionOnCreate on save { create; }
  validation validateGiftCardFields on save { create; field GiftcardValue, SapDescription; }
  validation validateGiftcardBalance on save { create; field GiftcardValue; }
  side effects { field GiftCardValue affects field GiftcardBalance; field SapDescription affects messages;  }
  association _BP { with draft; }
  mapping for zlh_giftcard corresponding
    {
      GiftcardBalance  = giftcard_balance;
      GiftcardCurrency = giftcard_currency;
      GiftcardValue    = giftcard_value;
      Giftcardnumber   = giftcardnumber;
      BusinessPartner  = business_partner;
      SapDescription   = sap_description;
      GiftcardStatus   = giftcard_status;
      CreatedBy        = created_by;
      CreatedOn        = created_on;
      LastChangedat    = last_changedat;
      LastChangedby    = last_changedby;
    }
}

define behavior for ZLH_R_Membership //alias <alias_name>
implementation in class ZCl_LH_Membership unique
persistent table zlh_membership
draft table zlh_d_membership
early numbering
lock dependent by _BP
authorization dependent by _BP
{
  update;
  delete;
  field ( readonly ) MembershipID, BusinessPartner;
  association _BP { with draft; }
  association _Category { create; with draft; }
  determination SetDefaultValuesOnCreate on modify { create; }
  side effects { field MembershipID affects entity _Category; }
  mapping for zlh_membership corresponding
    {
      BusinessPartner = business_partner;
      MembershipID    = membershipid;
      MembershipStatus = membership_status;
      MemberSince     = member_since;
      MembershipEndDate = membership_enddate;
      CreatedBy       = created_by;
      CreatedOn       = created_on;
      LastChangedat   = last_changedat;
      LastChangedby   = last_changedby;
    }
}

define behavior for ZLH_R_CATEGORY //alias <alias_name>
implementation in class ZCl_LH_Category unique
persistent table zlh_category
draft table zlh_d_category
lock dependent by _BP
authorization dependent by _BP
{
  update;
  delete;
  field ( readonly :update) MembershipID, CategoryID;
  field (readonly) BusinessPartner;
  association _BP { with draft; }
  association _Membership { with draft; }
  determination fillDefaultValues on modify{ create; }
  mapping for zlh_category corresponding
    {
      CategoryID      = categoryid;
      StartDate       = start_date;
      EndDate         = end_date;
      MembershipID    = membershipid;
      BusinessPartner = business_partner;
      CreatedBy       = created_by;
      CreatedOn       = created_on;
      LastChangedat   = last_changedat;
      LastChangedby   = last_changedby;
    }

}

define behavior for ZLH_R_TRANSACTIONS //alias <alias_name>
implementation in class ZCL_LH_Transactions unique
persistent table zlh_transactions
draft table zlh_d_trans
early numbering
lock dependent by _BP
authorization dependent by _BP
{
  update (precheck);
  delete;
  field ( mandatory ) ActivityType, LoyaltyPoints;
  field ( readonly ) TransactionId, BusinessPartner, Membershipid,  CreatedBy, LastChangedat,LastChangedby;
  field ( features : instance ) LoyaltyPoints, TransactionDate, ActivityType;
  association _BP { with draft; }
  determination LoyaltyPointCalculations on modify { create; field TransactionAmount; }
  determination fillDefaultValues on modify{ create; }
  validation validate_transaction_data
    on save { create; update; field TransactionDate, LoyaltyPoints, PointExpiryDate; }

  mapping for zlh_transactions corresponding
    {
      TransactionId       = transaction_id;
      ActivityType        = activity_type;
      PointExpiryDate     = point_expiry_date;
      Membershipid        = membershipid;
      BusinessPartner     = business_partner;
      RefSalesorderId     = ref_salesorder_id;
      LoyaltyPoints       = loyalty_points;
      CreatedBy           = created_by;
      CreatedOn           = created_on;
      TransactionDate     = transaction_date;
      TransactionCurrency = transaction_currency;
      TransactionAmount   = transaction_amount;
      LastChangedat       = last_changedat;
      LastChangedby       = last_changedby;
    }
}