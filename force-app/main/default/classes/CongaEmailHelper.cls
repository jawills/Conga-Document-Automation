public class CongaEmailHelper {

    Composer_Automation__mdt conga_automation_settings {get;set;}
    Id attatchmentId {get;set;}
    Id opportunityId {get;set;}
    Opportunity opp {get;set;}
    String sessionId = UserInfo.getSessionId();

    public CongaEmailHelper(Id opportunityId, String automationEmail){
        // Metadata for Composer Automation
        conga_automation_settings = [select id,MasterLabel, org_wide_Email__c,Include_Date__c,
                Template_Id__c, Subject__c, body__c, file_name__c
                from Composer_Automation__mdt WHERE MasterLabel =: automationEmail];

        // Query Object Fields
        opp = [SELECT Id,
                Contact__r.email,
                Contact__c
                FROM Opportunity
                WHERE Id =: opportunityId];
        this.opportunityId = opportunityId;
        this.attatchmentId = mergeDocument(conga_automation_settings.Template_Id__c);
    }

    public Boolean sendTemplateEmail(){

        if(this.attatchmentId != null && opp.Contact__r.email != null){
            // Send Email to Contact's email
            List<String> toEmails = new List<String>{opp.Contact__r.email};

            //Add ccEmails
            List<String> ccEmails = new List<String>{};
			String Subject = conga_automation_settings.Subject__c;
            String Body = conga_automation_settings.Body__c;
            sendEmail(toEmails, ccEmails, Subject, Body, attatchmentId);
        }else{
            // Failure Notification
            List<String> toEmails = new List<String>{'justin.wills@g2technologies.com'};
            String body = 'Composer Automation Failed: ' + this.opportunityId ;
            sendEmail(toEmails, null, 'Composer Automation Failed', body, null);
            return false;
        }
        return true;
    }

    private void sendEmail(List<String> toEmails, List<String> ccEmails, String Subject, String body, Id attatchmentId){
        messaging.SingleEmailMessage email1=new messaging.SingleEmailMessage();
        string[]toAdd = toEmails;
        string []ccAdd= ccEmails;
        email1.setToAddresses(toAdd);
        email1.setCcAddresses(ccAdd);
        email1.setSubject(Subject);
        email1.setHtmlBody(body);
        if(attatchmentId != null){
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            List<Attachment> files = [SELECT Name, Body, ContentType FROM Attachment WHERE Id =:attatchmentId];
            for (Attachment file: files) {
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(file.Name);
                efa.setBody(file.Body);
                efa.setContentType(file.ContentType);
                attachments.add(efa);
              }
            email1.setFileAttachments(attachments);

        }
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: conga_automation_settings.org_wide_email__c];
        if ( owea.size() > 0 ) {
            email1.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        messaging.Email[] emails = new messaging.Email[]{email1};
        messaging.sendEmail(emails);
    }

    private Id mergeDocument(Id templateId) {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        String fileName = EncodingUtil.urlEncode(conga_automation_settings.file_name__c, 'UTF-8');
        if(conga_automation_settings.include_date__c){
            fileName += String.valueOf(date.today());
        }
        String baseEndpoint = 'https://composer.congamerge.com/composer8/index.html';
        String endpoint = baseEndpoint +  '?sessionId=' + this.sessionId +
                        '&serverUrl=' + System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/51.0/' + UserInfo.getOrganizationId() + 
                        '&id=' + this.opportunityId + 
                        '&templateid=' + templateId  +
                        '&DefaultPDF=1' + 
                        '&OFN='+ fileName + 
                        '&APIMode=1';
        req.setEndpoint( endpoint );
        req.setMethod('GET');
        // Large Timeout because files are large and take time to send via https
        req.setTimeout(60000);
        System.debug(req.getEndpoint());
        res = h.send(req);
        System.debug(res.getStatusCode());
        System.debug(res.getBody());
        try{
            Id bool = (Id) res.getBody();
        }catch(Exception e){
            System.debug(e);
            return null;
        }
        return (Id) res.getBody();
    }
}