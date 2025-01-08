public with sharing class NotifyUser {
    
    @InvocableMethod(label='MyOrgButler: Notify User' description='Sends an In-org notification message to a set of users optionally linking to a target record')
    public static List<Output> execute(List<Notification> notifications) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(notifications[0].title);
        notification.setBody(notifications[0].body);
        notification.setNotificationTypeId(notifications[0].customNotifTypeId);
        notification.setTargetId(notifications[0].targetId);
        notification.send(new Set<String>(notifications[0].recipientIds));

        return new List<Output>{ new Output() };
    }

    // INNER

    public with sharing class Notification {
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
        @InvocableVariable(label='Ignored' description='ignored' required=false)
        public String ignored;
        
    }
}