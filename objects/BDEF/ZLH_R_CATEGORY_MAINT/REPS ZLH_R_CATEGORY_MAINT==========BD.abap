managed with additional save implementation in class ZCL_LH_CATEGORY_MAINT unique;
strict;
with draft;
define behavior for ZLH_R_CATEGORY_MAINT alias MaintainCategory
draft table ZLH_CATEGORY_M_D
with unmanaged save
lock master total etag LastChangedAtMax
authorization master( global )
{
  field ( readonly )
   SingletonID;

  field ( features : instance )
   TransportRequestID;

  field ( notrigger )
   SingletonID,
   LastChangedAtMax;


  update;
  internal create;
  internal delete;

  draft action ( features : instance ) Edit with additional implementation;
  draft action Activate optimized;
  draft action Discard;
  draft action Resume;
  draft determine action Prepare;
  action ( features : instance ) SelectCustomizingTransptReq parameter D_SelectCustomizingTransptReqP result [1] $self;

  association _CategoryHeader { create ( features : instance ); with draft; }

  validation ValidateTransportRequest on save ##NOT_ASSIGNED_TO_DETACT { create; update; }

  side effects {
    action SelectCustomizingTransptReq affects $self;
  }

}

define behavior for ZLH_R_CATEGORY_HDR alias CategoryHeader ##UNMAPPED_FIELD
persistent table ZLH_CATEGORY_HDR
draft table ZLH_CATEGORY_H_D
early numbering
lock dependent by _MaintainCategory
authorization dependent by _MaintainCategory
{
   field ( readonly )
   Categoryid;

  field ( readonly )
   SingletonID;

  field ( notrigger )
   SingletonID;


  update( features : global );
  delete( features : global );

  mapping for ZLH_CATEGORY_HDR
  {
    Categoryid = CATEGORYID;
    Isenabled = ISENABLED;
    Threshold = THRESHOLD;
    Isdefault = ISDEFAULT;
    Approver = APPROVER;
    Accuconval = ACCUCONVAL;
    CreatedOn = CREATED_ON;
    CreatedBy = CREATED_BY;
    LastChangedat = LAST_CHANGEDAT;
    LastChangedby = LAST_CHANGEDBY;
  }

  association _MaintainCategory { with draft; }
  association _CategoryText { create ( features : global ); with draft; }

  validation ValidateTransportRequest on save ##NOT_ASSIGNED_TO_DETACT { create; update; delete; }

}

define behavior for ZLH_R_CATEGORY_TEXT alias CategoryText ##UNMAPPED_FIELD
persistent table ZLH_CATEGORY_TXT
draft table ZLH_CATEGORY_T_D
lock dependent by _MaintainCategory
authorization dependent by _MaintainCategory
{
  field ( mandatory : create )
   Language;

  field ( readonly )
   SingletonID,
   Categoryid;

  field ( readonly : update )
   Language;

  field ( notrigger )
   SingletonID;


  update( features : global );
  delete( features : global );

  mapping for ZLH_CATEGORY_TXT
  {
    Categoryid = CATEGORYID;
    Language = LANGUAGE;
    Categoryname = CATEGORYNAME;
    Categorydesc = CATEGORYDESC;
    CreatedOn = CREATED_ON;
    CreatedBy = CREATED_BY;
    LastChangedat = LAST_CHANGEDAT;
    LastChangedby = LAST_CHANGEDBY;
  }

  association _MaintainCategory { with draft; }
  association _CategoryHeader { with draft; }

  validation ValidateTransportRequest on save ##NOT_ASSIGNED_TO_DETACT { create; update; delete; }

}