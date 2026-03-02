class-pool .
*"* class pool for class ZCL_LH_TRANSACTIONS

*"* local type definitions
include ZCL_LH_TRANSACTIONS===========ccdef.

*"* class ZCL_LH_TRANSACTIONS definition
*"* public declarations
  include ZCL_LH_TRANSACTIONS===========cu.
*"* protected declarations
  include ZCL_LH_TRANSACTIONS===========co.
*"* private declarations
  include ZCL_LH_TRANSACTIONS===========ci.
endclass. "ZCL_LH_TRANSACTIONS definition

*"* macro definitions
include ZCL_LH_TRANSACTIONS===========ccmac.
*"* local class implementation
include ZCL_LH_TRANSACTIONS===========ccimp.

*"* test class
include ZCL_LH_TRANSACTIONS===========ccau.

class ZCL_LH_TRANSACTIONS implementation.
*"* method's implementations
  include methods.
endclass. "ZCL_LH_TRANSACTIONS implementation
