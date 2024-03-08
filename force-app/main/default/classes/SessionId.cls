public with sharing class SessionId {
    public String asString() {
        return (Test.isRunningTest()) ? UserInfo.getSessionId() : Page.sessionId.getContent().toString().substring(15);
    }
}