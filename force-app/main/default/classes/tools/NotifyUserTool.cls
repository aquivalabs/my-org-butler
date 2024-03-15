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
        if(response.getStatusCode() != 200) {
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

        // PMD False Positive: This Id value means no target and is the official SF way.
        @SuppressWarnings('PMD.AvoidHardcodingId')
        public Notification(String jsonParameter) {
            JsonReader reader = new JsonReader(jsonParameter);

            customNotifTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName='InOrgNotifications'].Id;
            recipientIds = recipientIds(reader);
            title = (String) reader.setMissingKeyResult('My Org Butler:').read('title');
            body = (String) reader.setMissingKeyResult('Click to see.').read('body');
            targetId = (String) reader.setMissingKeyResult('000000000000000AAA').read('targetId');
        }

        private List<String> recipientIds(JsonReader reader) {
            String value = (String) reader.setMissingKeyResult(UserInfo.getUserId()).read('recipientIds');
            return value.trim().split(',');
        }
    }
}