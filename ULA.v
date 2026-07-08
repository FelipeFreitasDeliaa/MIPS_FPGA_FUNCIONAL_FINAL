module ULA (
    input      [31:0] A,          // Entrada A
    input      [31:0] B,          // Entrada B
    input      [5:0]  opcode,     // Seletor de operação (6 bits)
    output reg [31:0] out,        // Resultado principal (Parte baixa / Quociente)
    output reg [31:0] high,       // Resultado secundário (Parte alta / Resto)
    output reg        z_flag      // Flag zero
);

    // Variável interna para o cálculo da multiplicação (64 bits)
    reg [63:0] produto;

    // Definição dos OPCODES
    localparam ADD    = 6'b000000;
    localparam ADDI   = 6'b001000;
    localparam MOV    = 6'b011010;
    localparam MOVI   = 6'b011011;
    localparam LOADD  = 6'b010100;
    localparam STORED = 6'b010101;
    localparam LOADI  = 6'b011000;
    localparam STOREI = 6'b011001;
    localparam LOADR  = 6'b010110;
    localparam STORER = 6'b010111;
    localparam PUSH   = 6'b011111;
	 localparam POP    = 6'b100000;
    
    localparam SUB    = 6'b000001;
    localparam SUBI   = 6'b001001;

    localparam AND    = 6'b000100;
    localparam ANDI   = 6'b001100;
    localparam OR     = 6'b000101;
    localparam ORI    = 6'b001101;
    localparam NOR    = 6'b000110;
    localparam XNOR   = 6'b000111;
    
    localparam BEQ    = 6'b010000;
    localparam BNE    = 6'b010001;
    localparam BLT    = 6'b010010;
    localparam BGT    = 6'b010011;

    localparam SL     = 6'b001110;
    localparam SR     = 6'b001111;

    localparam MUL    = 6'b000010;
    localparam MULI   = 6'b001010;
    localparam DIV    = 6'b000011;
    localparam DIVI   = 6'b001011;

    always @(*) begin
	 
			//valores padrão para evitar latches
			out    = 32'd0;
			high   = 32'd0;
			z_flag = 1'b0;

        case (opcode)
            
            ADD, ADDI, LOADD, STORED, LOADI, STOREI, LOADR, STORER, PUSH, POP, MOVI, MOV: 
                out = A + B;

            SUB, SUBI: 
                out = A - B;

            AND, ANDI: out = A & B;
            OR, ORI:   out = A | B;
            NOR:       out = ~(A | B);
            XNOR:      out = ~(A ^ B);
            BEQ: z_flag = ($signed(A) == $signed(B)) ? 1'b1 : 1'b0;
				BNE: z_flag = ($signed(A) != $signed(B)) ? 1'b1 : 1'b0;
				BLT: z_flag = ($signed(A) < $signed(B)) ? 1'b1 : 1'b0;
				BGT: z_flag = ($signed(A) > $signed(B)) ? 1'b1 : 1'b0;

            SL: out = A << B[4:0];
            SR: out = A >> B[4:0];

            MUL, MULI: begin
                produto = $signed(A) * $signed(B);
                out  = produto[31:0];
                high = produto[63:32];
            end

            DIV, DIVI: begin
                if (B != 0) begin
                    out  = $signed(A) / $signed(B);
                    high = $signed(A) % $signed(B);
                end else begin
                    out  = 32'hFFFFFFFF;
                    high = 32'hFFFFFFFF;
                end
            end

        endcase
    end

endmodule
