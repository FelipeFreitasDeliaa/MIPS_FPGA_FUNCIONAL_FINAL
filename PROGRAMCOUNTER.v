module PROGRAMCOUNTER (
    input        clk,
    input        HLT,
    input        segura_in,        // NOVO: trava o PC na instrucao IN ate o "enter"
    input        Branch,
    input        z_flag,
    input        Jump,
    input        JR,
    input [31:0] Imediato_Branch,
    input [31:0] Imediato_Jump,
    input [31:0] Endereco_JR,
    output reg [31:0] PC_atual
);
    initial begin
        PC_atual = 32'd0;
    end

    // atualizacao do PC na borda de descida
    always @(negedge clk) begin
        if (HLT) begin
            PC_atual <= PC_atual;
        end
        else if (segura_in) begin        // NOVO: aguarda o botao na IN
            PC_atual <= PC_atual;
        end
        else if (JR) begin
            PC_atual <= Endereco_JR;
        end
        else if (Jump) begin
            PC_atual <= Imediato_Jump;
        end
        else if (Branch && z_flag) begin
            PC_atual <= PC_atual + 32'd1 + Imediato_Branch;
        end
        else begin
            PC_atual <= PC_atual + 32'd1;
        end
    end
endmodule
