class-pool .
*"* class pool for class ZLH_SALESORDER_INTEGRATION

*"* local type definitions
include ZLH_SALESORDER_INTEGRATION====ccdef.

*"* class ZLH_SALESORDER_INTEGRATION definition
*"* public declarations
  include ZLH_SALESORDER_INTEGRATION====cu.
*"* protected declarations
  include ZLH_SALESORDER_INTEGRATION====co.
*"* private declarations
  include ZLH_SALESORDER_INTEGRATION====ci.
endclass. "ZLH_SALESORDER_INTEGRATION definition

*"* macro definitions
include ZLH_SALESORDER_INTEGRATION====ccmac.
*"* local class implementation
include ZLH_SALESORDER_INTEGRATION====ccimp.

*"* test class
include ZLH_SALESORDER_INTEGRATION====ccau.

class ZLH_SALESORDER_INTEGRATION implementation.
*"* method's implementations
  include methods.
endclass. "ZLH_SALESORDER_INTEGRATION implementation
