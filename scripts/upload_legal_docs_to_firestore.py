import firebase_admin
from firebase_admin import credentials, firestore
import os
from datetime import datetime

# --- Configuration ---
SERVICE_ACCOUNT_KEY_PATH = 'scripts/serviceAccountKey.json'
FIRESTORE_COLLECTION_NAME = 'legal_documents'

# --- Legal Document Contents (in Markdown) ---
PRIVACY_POLICY_CONTENT = """
**Last Updated**: October 2025
**Effective Date**: October 12, 2025

The Republic Act No. 10173 or Data Privacy Act (DPA) of 2012 (and its Implementing Rules and Regulations) are implemented by the National Privacy Commission (NPC).

This Privacy Policy defines how the developers of ShelfControl (“we,” “us,” “our”) collect, use, store, and protect personal information in accordance with the Data Privacy Act of 2012 (RA 10173), its Implementing Rules and Regulations, and the privacy principles outlined in ISO/IEC 29100. It applies to all users of the ShelfControl mobile application and to all personal data processed through its associated Firebase infrastructure and third-party integrations.

**1. Data Privacy Principles (DPA General Principles)**
Under processing your data, we follow the following principles:
1.  **Transparency:** You understand the nature, purpose and scope of the processing of personal data.
2.  **Legitimate Purpose:** Your data is used to work only on the declared, specified and lawful purposes that are directly connected with the functioning of ShelfControl.
3.  **Proportionality:** Only the data are collected and kept in amounts that are sufficient, relevant, suitable, and necessary to achieve the stated purposes.

**2. Personal Information Collected and Processed**
We will only store and process your personal information when it is needed as per the main functionality of the ShelfControl application.

*   **Identifiers**
    *   **Specific Data Collected**: Email Address
    *   **Source of Data**: Directly from the User (Account Registration)
    *   **Legal Justification of Processing (DPA)**: Contractual Necessity
    *   **Purpose**: Account creation and authentication
*   **Pantry Data (Content Data)**
    *   **Specific Data Collected**: Name of Pantry Item, Quantity, Storage Place, Expiration Date
    *   **Source of Data**: Directly from the User (Manual Entry/Scanning)
    *   **Legal Justification of Processing (DPA)**: Contractual Necessity
    *   **Purpose**: Core service for inventory tracking
*   **Technical Data**
    *   **Specific Data Collected**: Device ID (e.g., Firebase ID), IP Address, App Usage/Crash Logs
    *   **Source of Data**: By default by Third-Party SDKs (Firebase)
    *   **Legal Justification of Processing (DPA)**: Legitimate Interest
    *   **Purpose**: Security and performance
*   **Optional Data**
    *   **Specific Data Collected**: Photos of Pantry Item (if enabled)
    *   **Source of Data**: Directly from the User (Camera/Gallery Access)
    *   **Legal Justification of Processing (DPA)**: Data Subject Consent
    *   **Purpose**: Physical identification of items

**3. Purpose and Use of Collected Data (Legitimate Purpose)**
The data that we process is solely used to meet the following purposes that were announced:

*   **Core Service Functionality:** To allow you to log in and out of different accounts, synchronize across the devices regarding pantry items in a single or multiple households, and receive alerts when something is about to expire.
*   **App Performance & Improvement:** To examine the anonymized and aggregated usage data to detect the software bugs, enhance the stability of the application, and optimize the user interface.
*   **Security and Fraud Prevention:** To control and detect fraud or illegal use of the ShelfControl service.
*   **Legal Compliance:** To act in a way that would fulfill any legal requirement, such as the need to act on a lawful request by the National Privacy Commission (NPC) or a court of competent jurisdiction.

**4. Third-Party Data Sharing (Transparency and Accountability)**
ShelfControl uses external processors bound by Data Processing Agreements compliant with RA 10173 (Section 20) and ISO 27018

*   **Google Firebase**
    *   **Data Handled**: Encrypted identifiers and inventory records
    *   **Purpose**: Authentication, cloud hosting, storage
    *   **Safeguards**: ISO 27001/SOC 2 certified; Standard Contractual Clauses applied
*   **Open Food Facts**
    *   **Data Handled**: Non-personal food names only
    *   **Purpose**: Public food metadata lookup
    *   **Safeguards**: Data minimization

Cross-border data transfers occur only where adequate protection is ensured through binding corporate rules or standard contractual clauses.

**5. Security Measures and Data Retention**
**A. Data Security**
ShelfControl shall implement prudent and suitable organizational, physical, and technical security measures to ensure that your personal information is not lost, modified, and disclosed due to an accident or illegally. These measures include:
*   **Encryption:** Data is encrypted during transmission (through SSL/TLS) and at rest (Firebase).
*   **Access Controls:** The database is accessed and only authorized development personnel can access it using Multi-Factor Authentication (MFA) based access controls (need to know).

**B. Data Retention and Disposal**

*   **Account Data**
    *   **Retention Period**: Until user requests deletion or after 12 months of inactivity
    *   **Disposal Method**: Logical deletion; 30-day purge
*   **Pantry and Household Data**
    *   **Retention Period**: While account active + 90 days backup
    *   **Disposal Method**: Automated purge scripts
*   **Audit and Usage Logs**
    *   **Retention Period**: 12 months from creation
    *   **Disposal Method**: Overwrite via log rotation
*   **Optional Images**
    *   **Retention Period**: User deletion or 90 days post deactivation
    *   **Disposal Method**: Secure Cloud erase API

After expiry, data are permanently and irreversibly deleted using Firebase’s secure erasure mechanisms.

**6. Rights of Data Subject (DPA Rights)**
Under RA 10173 (Section 16) and ISO 29100 Clause 5, users have the right to:
1.  **Right to be Informed:** You have the right to know whether personal data about you is being or has been processed.
2.  **Right to Object:** You have the right to object to the processing of your data, such as processing of your data to direct marketing or profiling.
3.  **Right to Access:** You have the right to access your personal data in a reasonable manner.
4.  **Right to Rectification:** You have a right to challenge the incorrectness or inaccuracy of your personal data and ask it to be corrected.
5.  **Right to Erasure or Blocking (Right to be Forgotten):** You have a right to suspend, withdraw or command the blocking, removal, or destruction of your personal data under the conditions set by law.
6.  **Right to Data Portability:** You have the right to receive a copy of your personal data in electronic form or structured format.
7.  **Right to Claim Damages:** You may claim damages on any damages that are caused by untrue, incomplete, outdated, false, illegally acquired or unauthorised use of your personal data.

Requests shall be addressed to the Data Protection Officer.
ShelfControl shall respond within 30 days of receipt, subject to identity verification.

**7. Consent and Withdrawal**
Consent is obtained electronically when users register or enable optional features. Users may withdraw consent at any time through the app’s Privacy Settings or by emailing the DPO. Upon withdrawal, optional data will be deleted and related functions disabled. Core processing necessary for account operation continues under contractual basis.

**8. Policy Updates and Notification**
This Policy is reviewed monthly or upon significant system changes. All updates will be announced via registered email at least 15 days before effectivity. Version history is maintained in the project repository and documentation.

**9. Compliance Monitoring**
The ShelfControl Development Team shall conduct periodic internal privacy audits to verify adherence to this policy and to NPC guidelines. Any incident of breach will be reported to the NPC and affected users within 72 hours of confirmation, in line with NPC Circular 16-03.

**10. Contact & Inquiries**
Data Protection Officer (DPO): Luis Daniel Enriquez
Email: shelfcontrol9@gmail.com
Institution: Polytechnic University of the Philippines – Sta. Mesa
NPC Complaint Channel: https://privacy.gov.ph/filing-a-complaint/

**11. Ethical and Research Use Declaration**
ShelfControl commits to use aggregated and anonymized data only for legitimate research purposes approved under institutional ethical review. No personally identifiable information shall be used in publications or analyses without explicit consent.

**12. Acknowledgement**
By installing or using ShelfControl, the user acknowledges that they have read, understood, and agreed to this Privacy Policy and that their data will be processed in accordance with the Data Privacy Act of 2012 and applicable international standards.

Approved by the ShelfControl Development Team (Version 1.0, October 2025)
"""

TERMS_AND_CONDITIONS_CONTENT = """
**Last Updated**: October 2025
**Effective Date**: October 12, 2025

**1. Agreement and Acceptance of Terms**
The Terms and Conditions (the Terms) are a legally binding contract between the user and the ShelfControl Team (Company, we, us or our) with regards to your usage of and access to the ShelfControl mobile application (the App).

BY ACCESSING OR USING SHELFCONTROL, YOU ACKNOWLEDGE THAT YOU HAVE READ, UNDERSTOOD, AND AGREED TO BE BOUND BY THESE TERMS AND CONDITIONS. IN CASE YOU DISAGREE WITH ALL THESE TERMS THEN YOU SHALL NOT ACCESS OR USE THE APP.

**2. Privacy and Data Principles**
All collection and processing of personal information shall comply with Republic Act No. 10173 (Data Privacy Act of 2012) and the ShelfControl Privacy Policy available at [insert URL]. ShelfControl shall uphold the principles of confidentiality, integrity, availability, accuracy, security, and accountability in all processing activities.

| Principle | Commitment |
| :-------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Confidentiality | No personal information (including pantry items) will be shared with unauthorized third parties unless you expressly agree that the data is shared, as per the law. |
| Integrity | We keep our security and backup procedures reasonable and appropriate so as to make sure that your records are accurate and complete. |
| Availability | We aim to make sure that the ShelfControl App is available and working. It will inform anticipated disruptions or significant maintenance beforehand when feasible. |

**3. User Accounts and Responsibilities**
All activities that take place on your account are of your responsibility.
*   **Account Confidentiality:** It is your duty to keep your login information and password confidential.
*   **Prompt Reporting:** You should immediately notify us through the prompt notification about any known or suspected unauthorized use or a breach of security with respect to your account.

You are responsible for all actions performed under your account, whether by you or an authorized household member. You shall promptly notify ShelfControl at shelfcontrol9@gmail.com upon discovery of unauthorized access. Failure to do so may result in suspension for security purposes.

**4. Usage Rules and Prohibited Activities**
You are granted a limited, non-exclusive, non-transferable, revocable license to use the App solely for personal household management.
You agree not to:
1.  Any use of the App in a manner which is unlawful or against any law in the Republic of the Philippines.
2.  Alter, disrupt, or disrupt the services, data or the host networks of the App.
3.  Interfere with the services, data of the App, such as by introducing viruses, denial-of-service attacks, or use of automated systems to harvest data (No scraping).
4.  Send spam, abuse, harass or solicit fellow users of the App.
5.  Resell, license or otherwise utilize any information or services of the App.
6.  Attempt to reverse engineer or decompile the App or its code.

Any unauthorized access, interference, or data breach attempt may constitute an offense under Republic Act No. 10175 (Cybercrime Prevention Act of 2012) and will be reported to authorities.

**5. Intellectual Property Rights**
ShelfControl source code, features, visual interfaces, interactive elements, graphics, design, and all other related content is the property of ShelfControl Team and is under copyright in the Philippines. You receive only a restricted license to use the App; you do not obtain any rights of ownership. All rights not expressly granted are reserved. Copying, modifying, or distributing any part of ShelfControl without written authorization from the Development Team is strictly prohibited.

**6. Disclaimers and Limitation of Liability**
**A. AS IS AND AS AVAILABLE DISCLAIMER**
THE APP IS BEING OFFERED “AS IS” AND “AS AVAILABLE” WITHOUT ANY WARRANTY OF ANY KIND. WE SPECIFICALLY DISCLAIM ANY AND ALL WARRANTIES, IMPLIED OR EXPRESSED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF QUALITY, SUITABILITY TO A SPECIFIC PURPOSE OR NON-INFRINGEMENT.

**B. HEALTH and SAFETY DISCLAIMER (CRITICAL)**
ShelfControl is an expiry tracking assistant only, which is not a replacement to a professional food safety practice, medical guidance, or even a visual examination of food. We will not be liable to any loss or damage (including foodborne illness, financial loss, or damage to property) because you relied on the data provided by the App, expired item notifications, or did not properly inspect and store food.

**C. LIMITATION OF LIABILITY**
To the fullest extent allowed by Philippine Laws, ShelfControl and its Developers shall not be liable for any direct, indirect, incidental, special, or consequential damages incurred by you as a result of your use of the App, including the loss of data, technical failure or the actions of any third-party service provider.

**7. Termination**
Without any warning, we can suspend or cancel your account and prevent access to the App in case of a violation of these Terms.
*   **Effect of Termination:** Once your account has been terminated, your right to use the App will be automatically transferred. Any data stored is going to be processed according to the Privacy Policy.

Upon termination, your right to use the App shall immediately cease. Data associated with the account will be handled in accordance with the ShelfControl Privacy Policy.

**8. Governing Law and Dispute Resolution**
These Terms shall be governed by and construed in accordance with the laws of the Republic of the Philippines. Any court proceeding or legal action of any kind that comes up based on these Terms shall be initiated in an appropriate court of the Republic of Manila, Philippines.

**9. Contact Information**
For any questions or concerns regarding these Terms, please contact us:
Email: shelfcontrol9@gmail.com
"""

# --- Initialize Firebase ---
try:
    if not os.path.exists(SERVICE_ACCOUNT_KEY_PATH):
        raise FileNotFoundError(f"Service account key not found at: {SERVICE_ACCOUNT_KEY_PATH}")
    
    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    if not firebase_admin._apps: # Initialize only if not already initialized
        firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("Firebase initialized successfully.")
except Exception as e:
    print(f"Error initializing Firebase: {e}")
    exit()

# --- Upload Legal Documents to Firestore ---
def upload_legal_documents():
    print(f"Starting upload of legal documents to Firestore collection '{FIRESTORE_COLLECTION_NAME}'...")
    
    current_time = datetime.now()

    # Privacy Policy
    privacy_policy_doc = {
        'content': PRIVACY_POLICY_CONTENT,
        'last_updated': current_time
    }
    db.collection(FIRESTORE_COLLECTION_NAME).document('privacy_policy').set(privacy_policy_doc)
    print("Uploaded Privacy Policy.")

    # Terms and Conditions
    terms_and_conditions_doc = {
        'content': TERMS_AND_CONDITIONS_CONTENT,
        'last_updated': current_time
    }
    db.collection(FIRESTORE_COLLECTION_NAME).document('terms_and_conditions').set(terms_and_conditions_doc)
    print("Uploaded Terms and Conditions.")
    
    print("Successfully uploaded all legal documents to Firestore.")

if __name__ == "__main__":
    upload_legal_documents()
