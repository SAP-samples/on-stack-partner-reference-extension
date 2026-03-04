# Application Logs

## Overview

Application logs provide a centralized and structured way to monitor application execution and identify errors that occur during runtime. They help developers and administrators analyze system behavior, troubleshoot issues, and ensure smooth application operations.

The application logs are delivered as a **reuse library**, primarily used within the **Application Jobs** app. They can also be consumed by other applications. The library offers a consistent and user-friendly interface to review runtime messages across applications.

### Features

Using the application logs reuse library, you can:

- View detailed application log entries  
- Filter logs based on severity levels  
- Search for specific message texts  
- Display detailed message information  
- Access archived application logs  

### SAP Help Portal Documentation

- [Application Logs](https://help.sap.com/docs/SAP_S4HANA_CLOUD/6aa39f1ac05441e5a23f484f31e477e7/091bec93bffb49b5af594115cb80ffb8.html?version=2602.500)
- [Working with Application Log Objects](https://help.sap.com/docs/abap-cloud/abap-development-tools-user-guide/working-with-application-log-objects?version=s4hana_cloud)
  
We have created an application log object to capture logs for the application job.
You can find the implementation logic in the [ZCL_LH_CATEGORY_UPDATE_JOB](../objects/CLAS/ZCL_LH_CATEGORY_UPDATE_JOB) class.
- Application log object: [ZLH_APPLICATION_LOG](../objects/APLO/ZLH_APPLICATION_LOG)
