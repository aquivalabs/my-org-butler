// PMD False Positive: Calling regular Salesforce APIs can be done with Session Id
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
public with sharing class SendInOrgNotification implements MyOrgButler.Tool {
    
    public String execute(String jsonParameter) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Url.getOrgDomainUrl().toExternalForm() + '/services/data/v58.0/actions/standard/customNotificationAction');
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        request.setHeader('Content-Type', 'application/json');

        Notifications notifications = new Notifications();
        notifications.inputs = new List<Notification>{ new Notification(jsonParameter) };
        request.setBody(JSON.serialize(notifications));

        HttpResponse response = new Http().send(request);
        if(response.getStatusCode() != 200) {
            throw new ApplicationException('HTTP Request failed with code: ' + response.getStatusCode() + ' and Notification: ' + response.getBody() + '.');
        }

        return response.getBody();
    }

    // INNER

    private class Notifications {
        public List<Notification> inputs = new List<Notification>();
    }

    private with sharing class Notification {
        public String customNotifTypeId;
        public List<String> recipientIds = new List<String>();
        public String title;
        public String body;
        public String targetId;
        public String senderId;

        // PMD False Positive: This Id value means no target and is the official SF way.
        @SuppressWarnings('PMD.AvoidHardcodingId')
        public Notification(String jsonParameter) {
            JsonParse params = new JSONParse(jsonParameter);

            customNotifTypeId = [SELECT Id FROM CustomNotificationType Where DeveloperName='InOrgNotifications'].Id;
            recipientIds = new List<String>{ UserInfo.getUserId() };
            title = extractOrDefault(params.get('title'), 'My Org Butler:');
            body = extractOrDefault(params.get('body'), 'Click to see.');
            targetId = extractOrDefault(params.get('targetId'), '000000000000000AAA');
            senderId = UserInfo.getUserId();
        }

        private String extractOrDefault(JSONParse params, String defaultValue) {
            String result = defaultValue;
    
            try {
                if(params != null && params.getStringValue() != '') {
                    result = params.getStringValue();
                }
            }
            catch(Exception ignored) { 
                // We don't WANT to handle this 
            }
    
            return result;
        }
    }
}