public with sharing class SubtractNumbers {
    
    @InvocableMethod(label='Subtract Numbers' description='Subtracts the second number from the first number')
    public static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];
        Output output = new Output();
        output.result = input.number1 - input.number2;
        return new List<Output>{ output };
    }

    // INNER

    public class Input {
        @InvocableVariable(label='First Number' description='Number to subtract from' required=true)
        public Decimal number1;

        @InvocableVariable(label='Second Number' description='Number to subtract' required=true)
        public Decimal number2;
    }

    public class Output {
        @InvocableVariable(label='Difference' description='The result of subtracting the second number from the first')
        public Decimal result;
    }
}