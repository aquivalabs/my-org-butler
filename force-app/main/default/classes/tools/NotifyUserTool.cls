public with sharing class NotifyUserTool extends MyOrgButler.Tool {
    
    public override String execute(String paramsJson) {
        JsonParse parser = new JsonParse(paramsJson);

        NotifyUser.Notification notification = new NotifyUser.Notification();
        notification.title = 'My Org Butler Notification: ' + parser.get('title').getStringValue();
        notification.body = parser.get('body').getStringValue();
        notification.targetId = parser.get('targetId').getStringValue();
        notification.recipientIds = parser.get('recipientIds').getStringValue().trim().split(',');

        List<NotifyUser.Output> result = NotifyUser.execute( new List<NotifyUser.Notification>{ notification } );
        return JSON.serialize(result[0]);
    }
}