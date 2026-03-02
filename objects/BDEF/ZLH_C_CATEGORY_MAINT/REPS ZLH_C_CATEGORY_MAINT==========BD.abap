projection implementation in class ZCL_LH_C_CATEGORY_MAINT unique;
strict;
use draft;
use side effects;
define behavior for ZLH_C_CATEGORY_MAINT alias MaintainCategory
{
  use action Edit;
  use action Activate;
  use action Discard;
  use action Resume;
  use action Prepare;
  use action SelectCustomizingTransptReq;

  use association _CategoryHeader { create ( augment ); with draft; }

}

define behavior for ZLH_C_CATEGORY_HDR alias CategoryHeader
{
  field ( modify )
   Categoryname;


  use update( augment );
  use delete;

  use association _MaintainCategory { with draft; }
  use association _CategoryText { create; with draft; }

}

define behavior for ZLH_C_CATEGORY_TEXT alias CategoryText
{
  use update;
  use delete;

  use association _MaintainCategory { with draft; }
  use association _CategoryHeader { with draft; }

}