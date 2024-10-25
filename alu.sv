`default_nettype none
//TODO need multiple and divide alu operations
module ALU (
    input  logic [3:0]  alu_op,  
    input  logic [31:0] A,       
    input  logic [31:0] B,       
    output logic [31:0] result  
);
    // Use uppercase to prevent keyword conflicts
    typedef enum logic [3:0] {
        ADD  = 4'b0001,  
        SUB  = 4'b0010,  
        AND  = 4'b0011,  
        OR   = 4'b0100,  
        XOR  = 4'b0101,  
        NOT  = 4'b0110,  // Bitwise NOT, B is ignored
        SLL  = 4'b0111,  // Logical shift left by B[4:0] bits
        SRL  = 4'b1000,  // Logical shift right by B[4:0] bits
        SRA  = 4'b1001,  // Arithmetic shift right by B[4:0] bits
        ROL  = 4'b1010   // Rotate left by B[4:0] bits
    } alu_ops_t;

    always_comb begin
        case (alu_op)
            ADD:  result = A + B;
            SUB:  result = A - B;
            AND:  result = A & B;
            OR:   result = A | B;
            XOR:  result = A ^ B;
            NOT:  result = ~A;             
            SLL:  result = A << B[4:0];    // Only lower 5 bits are effective
            SRL:  result = A >> B[4:0];    
            SRA:  result = $signed(A) >>> B[4:0];  
            ROL:  result = (A << B[4:0]) | (A >> (32 - B[4:0]));  
            default: result = 32'h00000000;
        endcase
    end

endmodule
