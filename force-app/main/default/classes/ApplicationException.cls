public class ApplicationException extends Exception {
    public override String getStackTraceString() {
        String result = '';

        Exception ex = this;
        do {
            result += ex.getTypeName() + ': ' +  ex.getMessage() + ': ';
            result += (ex == this) ? getCauseStackTrace() : ex.getStackTraceString();
            ex = ex.getCause();
            if(ex != null) {
                result += '\n';
            }
        } 
        while(ex != null);

        return result;
    }

    private String getCauseStackTrace() {
        return (super.getCause() == null ) ? '' : super.getCause().getStackTraceString();
    }
}
