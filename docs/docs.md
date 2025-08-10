# SponsorAll Project Documentation

## Project Summary  
SponsorAll is a generic sponsorship management solution built on the Salesforce platform. It enables organizations to define sponsorable entities, their sponsorship needs, and manage sponsorship pledges and transactions efficiently. The system supports complex sponsorship models including recurring sponsorships, installment payment plans, tagging, segmentation, and customizable attributes for flexibility across various implementations.

---

## Entity Relationship Diagram (ERD) and Core Objects

### 1. Sponsorable__c  
Represents any item or entity available for sponsorship (e.g., events, projects, assets).

| Field Name                  | Type                | Description / Tooltip                                  |
|-----------------------------|---------------------|-------------------------------------------------------|
| Name                        | Text(255)           | The name of the sponsorable item                       |
| Description__c              | RichTextArea(32000) | Detailed description of the sponsorable item          |
| Category__c                 | Picklist            | Category type (Event, Project, Asset, Other)          |
| Installment_Plan_Eligible__c | Checkbox           | Indicates if installment payments are allowed          |
| Sponsorable_Segment__c      | Lookup(Sponsorable_Segment__c) | Physical or organizational segment for this sponsorable |

---

### 2. Sponsorship_Need__c  
Defines specific sponsorship needs or goals tied to a Sponsorable.

| Field Name                | Type                | Description / Tooltip                                  |
|---------------------------|---------------------|-------------------------------------------------------|
| Name                      | Text(255)           | Sponsorship need name                                  |
| Sponsorable__c            | Lookup(Sponsorable__c) | The sponsorable entity associated with this need      |
| Amount_Requested__c       | Currency(16,2)      | Amount requested for sponsorship                       |
| Description__c            | RichTextArea(32000) | Description of the sponsorship need                    |
| Recurrence_Type__c        | Picklist            | None (one-time), Weekly, Monthly, Quarterly, Annually |
| Recurrence_Amount__c      | Currency(16,2)      | Amount for each recurrence period                       |
| Recurrence_End_Date__c    | Date                | Date when recurring sponsorship ends                   |
| Allow_Installment_Plan__c | Checkbox            | If installment payment plans are allowed                |
| Deadline__c               | Date                | Sponsorship need deadline                               |
| Status__c                 | Picklist            | Status (Open, Fulfilled, Closed)                        |
| Type__c                   | Picklist            | Need type for grouping (Marketing, Facility, Event, etc.) |

---

### 3. Sponsorship_Opportunity__c  
Represents a sponsor’s pledge to fulfill a sponsorship need.

| Field Name                       | Type                 | Description / Tooltip                                  |
|---------------------------------|----------------------|-------------------------------------------------------|
| Name                            | Auto Number          | Unique identifier (e.g., SPONSOPP-{0000})             |
| Sponsorship_Need__c             | Lookup(Sponsorship_Need__c) | The sponsorship need this opportunity fulfills         |
| Contact__c                    | Lookup(Contact)      | The sponsor (Salesforce Contact)                       |
| Pledge_Amount__c              | Currency(16,2)       | Amount pledged                                         |
| Status__c                    | Picklist             | Status of the opportunity (Pledged, Confirmed, Completed) |
| Installment_Plan__c           | Checkbox             | Whether this is an installment payment plan           |
| Installment_Total_Amount__c   | Currency(16,2)       | Total installment amount                               |
| Installment_Period__c         | Picklist             | Frequency (Weekly, Monthly, Quarterly, Custom)         |
| Installment_Number_of_Payments__c | Number            | Number of installments planned                         |
| Installments_Paid__c          | Number               | Count of installments paid so far                      |
| Next_Payment_Due_Date__c      | Date                 | Date of next installment payment due                   |

---

### 4. Sponsorship_Transaction__c  
Summarizes payment transactions for sponsorships.

| Field Name                  | Type                | Description / Tooltip                                  |
|-----------------------------|---------------------|-------------------------------------------------------|
| Name                        | Auto Number        | Unique transaction identifier (e.g., SPONSTRX-{0000}) |
| Contact__c                 | Lookup(Contact)    | Sponsor making the payment                             |
| Transaction_Date__c         | DateTime           | When the payment was made                              |
| Total_Amount__c             | Currency(16,2)     | Total amount paid                                     |
| Payment_Method__c           | Picklist           | Payment type (Credit Card, ACH, Check, Other)         |
| Status__c                  | Picklist           | Status of transaction (Pending, Completed, Failed)    |
| Payment_Provider_Ref__c     | Text(255)          | External payment provider reference                    |
| Notes__c                   | RichTextArea(32000) | Optional notes about the transaction                   |

---

### 5. Sponsorship_Transaction_Line_Item__c  
Junction between transactions and sponsorship opportunities.

| Field Name                   | Type              | Description / Tooltip                                  |
|------------------------------|-------------------|-------------------------------------------------------|
| Name                        | Auto Number      | Unique line item identifier (e.g., STLI-{0000})       |
| Sponsorship_Transaction__c  | Master-Detail    | Parent transaction (Not reparentable)                  |
| Sponsorship_Opportunity__c  | Lookup           | Sponsorship opportunity paid for                       |
| Amount_Paid__c             | Currency(16,2)   | Amount paid on this line item                          |

---

## 6. Tagging

### Sponsorship_Tag__c  
Generic tag object to apply tags to Sponsorables and Sponsorship Needs.

| Field Name       | Type          | Description / Tooltip                          |
|------------------|---------------|-----------------------------------------------|
| Name             | Text(255)     | The name of the tag                            |
| Tag_Type__c      | Picklist      | Category/type of the tag (e.g., Theme, Priority) |

---

### Junction Objects for Tagging

#### Sponsorable_Tag__c  
Links Sponsorable items to Tags.

| Field Name         | Type               | Description / Tooltip                        |
|--------------------|--------------------|---------------------------------------------|
| Sponsorable__c     | Master-Detail       | Related Sponsorable item                     |
| Sponsorship_Tag__c | Lookup             | Related Tag                                 |

#### Sponsorship_Need_Tag__c  
Links Sponsorship Needs to Tags.

| Field Name         | Type               | Description / Tooltip                        |
|--------------------|--------------------|---------------------------------------------|
| Sponsorship_Need__c | Master-Detail      | Related Sponsorship Need                     |
| Sponsorship_Tag__c  | Lookup             | Related Tag                                 |

---

## 7. Segmentation

### Sponsorable_Segment__c  
Represents physical locations or other organizational segments.

| Field Name       | Type           | Description / Tooltip                        |
|------------------|----------------|---------------------------------------------|
| Name             | Text(255)      | Name of the segment                          |
| Description__c   | RichTextArea(32000) | Description or details about the segment     |
| Parent_Segment__c | Lookup(Sponsorable_Segment__c) | Optional parent segment for hierarchy         |

---

## 8. Custom Attributes

### Sponsorable_Attribute_Definition__mdt (Custom Metadata Type)  
Defines attribute templates for sponsorable types.

| Field Name         | Type           | Description / Tooltip                        |
|--------------------|----------------|---------------------------------------------|
| Attribute_Name__c  | Text(255)      | Name of the attribute                        |
| Data_Type__c       | Picklist       | Data type (Text, Number, Date, Checkbox, etc.) |
| Required__c        | Checkbox      | Whether the attribute is mandatory           |
| Default_Value__c   | Text(255)      | Default value for the attribute              |

---

### Sponsorable_Attribute__c  
Stores attribute values per Sponsorable.

| Field Name               | Type               | Description / Tooltip                        |
|--------------------------|--------------------|---------------------------------------------|
| Sponsorable__c          | Lookup(Sponsorable__c) | Sponsorable entity this attribute applies to |


---

### Sharing Model Notes  
- `Sponsorship_Opportunity__c` and `Sponsorship_Transaction__c` objects should have external sharing set to **Private**.  
- `Sponsorship_Transaction_Line_Item__c` master-detail to Sponsorship_Transaction__c should be **Not Reparentable**.


