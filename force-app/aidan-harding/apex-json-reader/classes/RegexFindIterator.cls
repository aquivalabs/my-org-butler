/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 19/06/2020
 * @description Repeatedly calls Matcher.find(), returning the whole matching result (i.e. Matcher.group()) via
 * an Iterator interface. Note: does not iterate the groups within each find
 */

global class RegexFindIterator implements Iterator<String> {

    private Matcher matcher;
    private Boolean hasNext;

    public RegexFindIterator(Pattern pattern, String searchString) {
        matcher = pattern.matcher(searchString);
        hasNext = matcher.find();
    }

    public Boolean hasNext() {
        return hasNext;
    }

    public String next() {
        String result = matcher.group();
        hasNext = matcher.find();
        return result;
    }
}