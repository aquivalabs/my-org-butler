// PMD False Positive: Calling regular Salesforce APIs can be done with Session Id
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
public with sharing class NotifyUserTool extends MyOrgButler.Tool {
    
    public override String execute(String jsonParameter) {
        List<Notification> notifications = new List<Notification>{ new Notification(jsonParameter) };
        List<Output> result = execute(notifications);
        return JSON.serialize(result[0]);
    }


    @InvocableMethod(
        label='MyOrgButler: Notify User'
        description='Sends an In-org notification message to a set of users optionally linking to a target record'
    )
    public static List<Output> execute(List<Notification> notifications) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Url.getOrgDomainUrl().toExternalForm() + '/services/data/v60.0/actions/standard/customNotificationAction');
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(notifications));

        HttpResponse response = new Http().send(request);
        if(response.getStatusCode() >= 300) {
            throw new ApplicationException('HTTP Request failed with code: ' + response.getStatusCode() + ' and Notification: ' + response.getBody() + '.');
        }
        return new List<Output>{ new Output(response.getBody()) };
    }

    // INNER

    public class Notifications {
        public List<Notification> inputs { get; set; }
    }

    public class Notification {
        public String customNotifTypeId;

        @InvocableVariable(label='Recipient User Ids' description='Comma separated list of Salesforce Ids of the users to send the notification to' required=true)
        public List<String> recipientIds;

        @InvocableVariable(label='Title' description='Short title of the notification' required=true)
        public String title;

        @InvocableVariable(label='Body' description='Notification text' required=true)
        public String body;

        @InvocableVariable(label='Target Id' description='Salesforce Id of the record to link to. If there is none use 000000000000000AAA' required=true)
        public String targetId;

        public Notification(String paramsJson) {
            customNotifTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName='InOrgNotifications'].Id;
            
            JsonParse parser = new JsonParse(paramsJson);
            title = 'My Org Butler Notification: ' + parser.get('title').getStringValue();
            body = parser.get('body').getStringValue();
            targetId = parser.get('targetId').getStringValue();
            recipientIds = recipientIds(parser);
        }

        private List<String> recipientIds(JsonParse parser) {
            String result = parser.get('recipientIds').getStringValue();
            return result.trim().split(',');
        }
    }

    public class Output {
        @InvocableVariable(
            label='Response Body' 
            description='Raw HTTP Response to be interpreted for Errors or Success' 
            required=true)
        public String responseBody;
        
        public Output(String body) {
            responseBody = body;
        }
    }
}