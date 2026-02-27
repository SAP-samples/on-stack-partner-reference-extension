
# Message Handling in RAP

## Overview

Message handling is a crucial aspect of RAP. It offers an important way to guide and validate consumer and user actions, and helps to avoid and resolve problems. Thus, messages are important to communicate problems to a consumer or user. Well-designed messages help to recognize, diagnose, and resolve issues. That's why it's important to always use messages consistently and optimize the interaction as a whole. Consequently, errors and warnings that require action should be clearly stated and described in a way that helps to resolve the issue quickly and efficiently. It’s recommended to provide a message for each entry in the fail structure to give additional information.

> Note: Messages in RAP can be associated with entity level, field level, or action/function level contexts. For a detailed guidance on message severity levels (Success, Information, Warning, Error), best practices, and implementation patterns, refer to [Messages](https://help.sap.com/docs/abap-cloud/abap-rap/messages) on SAP Help Portal.

## Message Types

### State Messages

State messages refer to a business object instance and its values. They reflect the current state of the business object and are persisted until the state that caused the message is changed.

Key characteristics of state messages are:

- Always bound to a business object entity (cannot use **%OTHER** component)
- Must include **%state_area** component to identify the condition
- Persisted until the causing state changes
- Used in validations, determinations, and save operations
- Must be invalidated to prevent message accumulation

> Note: For more information, refer to [State Messages](https://help.sap.com/docs/abap-cloud/abap-rap/state-messages) on SAP Help Portal.

### Transition Messages

Transition messages refer to a triggered request and are only valid during the runtime of the request. Unlike state messages, they relate to the transition between states rather than the current state of the business object.

Key characteristics of transition messages are:
- Valid only during request runtime
- Related to state transitions, not current state
- Can be bound (**with %tky**) or unbound (**without %tky**)

> Note: For more information, refer to [Transition Messages](https://help.sap.com/docs/abap-cloud/abap-rap/transition-messages) on SAP Help Portal.

## Implementation Approaches

### 1. Using Message Classes and Message Exception Classes

#### Message Classes

Message classes provide a way to define and manage messages in a centralized manner. They allow you to group related messages and provide a consistent way to access them.

We have implemented the **ZPRA_LOYALTYHUB** message class as follows:

```abap
  METHOD validate_transaction_data.
    CHECK keys IS NOT INITIAL.
    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY zlh_r_transactions
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(transactions).
    LOOP AT transactions ASSIGNING FIELD-SYMBOL(<transaction>).
      IF <transaction>-LoyaltyPoints = 0.
        APPEND VALUE #(
          %tky = <transaction>-%tky
        ) TO failed-ZLH_R_Transactions.
        APPEND VALUE #(
          %tky = <transaction>-%tky

          %msg = new_message(
            id       = 'ZPRA_LOYALTYHUB'
            number   = '003'
            severity = if_abap_behv_message=>severity-error
          )
          %path         = VALUE #(
                  zlh_r_businesspartner-%is_draft = <transaction>-%is_draft
                  zlh_r_businesspartner-soldtoparty = <transaction>-BusinessPartner
                )
          %element-LoyaltyPoints = if_abap_behv=>mk-on
        ) TO reported-zlh_r_transactions.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
```

#### Message Exception Classes

A Message exception class in ABAP RAP is a specialized ABAP class that extends standard exception handling to provide structured, reusable message management for RAP applications. It serves as a bridge between traditional ABAP message classes and the modern RAP messaging framework. It is used to encapsulate the messages stored in a message class to handle the formatting of message variable types like dates or amounts through the exception class.


> Note: For detailed information on creating and using message exception classes, refer to [Creating a Message Exception Class](https://help.sap.com/docs/abap-cloud/abap-rap/creating-message-exception-class) on SAP Help Portal.

### 2. Direct Message Creation

For simple scenarios or prototyping, you can create messages directly:

```abap
APPEND VALUE #( %tky = <entity>-%tky
                %msg = new_message_with_text( 
                  severity = if_abap_behv_message=>severity-warning
                  text = |Message Text| ) ) TO reported-entity.
```
