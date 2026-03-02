class-pool .
*"* class pool for class ZCL_LH_MEMBERSHIP

*"* local type definitions
include ZCL_LH_MEMBERSHIP=============ccdef.

*"* class ZCL_LH_MEMBERSHIP definition
*"* public declarations
  include ZCL_LH_MEMBERSHIP=============cu.
*"* protected declarations
  include ZCL_LH_MEMBERSHIP=============co.
*"* private declarations
  include ZCL_LH_MEMBERSHIP=============ci.
endclass. "ZCL_LH_MEMBERSHIP definition

*"* macro definitions
include ZCL_LH_MEMBERSHIP=============ccmac.
*"* local class implementation
include ZCL_LH_MEMBERSHIP=============ccimp.

*"* test class
include ZCL_LH_MEMBERSHIP=============ccau.

class ZCL_LH_MEMBERSHIP implementation.
*"* method's implementations
  include methods.
endclass. "ZCL_LH_MEMBERSHIP implementation
