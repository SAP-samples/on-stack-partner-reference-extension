projection;
strict ( 2 );
use side effects;
use draft;

define behavior for ZLH_C_BusinessPartner //alias <alias_name>
{
//  use create;
  use update;
//  use delete;

  use action Edit;
  use action prepare;
  use action Activate;
  use action Resume;
  use action Discard;
   use action createMembership;
   use action deleteMembership;
  use action createCategory;
  use action reactivateMembership;
  use association _GiftCard {create; with draft; }
  use function GetDefaultsForGiftCard;
  use association _MemberShip { create; with draft; }
  use association _Transactions { create; with draft; }
}

define behavior for ZLH_C_GIFTCARD
{
  use update;
  field ( readonly ) GiftcardBalance, GiftcardStatus, CreatedOn;
  use association _BP { with draft; }
}

define behavior for ZLH_C_Membership //alias <alias_name>
{
  use update;
  use delete;

  use association _BP { with draft; }
  use association _Category { create; with draft; }
}

define behavior for ZLH_C_CATEGORY //alias <alias_name>
{
//  use update;
//  use delete;

  use association _Membership { with draft; }
  use association _BP { with draft; }
}

define behavior for ZLH_C_TRANSACTIONS //alias <alias_name>
{
  use update;
//  use delete;
  field ( readonly ) RefSalesorderId, TransactionCurrency, TransactionAmount, PointExpiryDate, TransactionDate;
  use association _BP { with draft; }
}