// PMD False Positive: Calling regular Salesforce APIs can be done with Session Id
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
public with sharing class NotifyUserTool implements MyOrgButler.Tool {
    
    public String execute(String jsonParameter) {
        Notifications notifications = new Notifications();
        notifications.inputs = new List<Notification>{ new Notification(jsonParameter) };
        
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
        return response.getBody();
    }

    // INNER

    public class Notifications {
        public List<Notification> inputs { get; set; }
    }

    public class Notification {
        public String customNotifTypeId { get; set; }
        public List<String> recipientIds { get; set; }
        public String title { get; set; }
        public String body { get; set; }
        public String targetId { get; set; }

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
}