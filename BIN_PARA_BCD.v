// =====================================================================
//  BIN_PARA_BCD.v
//  Converte um numero binario de 32 bits em BCD (decimal), usando o
//  algoritmo "double dabble" (combinacional). Saida de 10 digitos BCD
//  (0..4.294.967.295).
//
//    bcd[3:0]   = unidades
//    bcd[7:4]   = dezenas
//    ...
//    bcd[39:36] = casa dos bilhoes
// =====================================================================
module BIN_PARA_BCD (
    input  wire [31:0] binario,
    output reg  [39:0] bcd        // 10 digitos decimais (4 bits cada)
);
    integer i, j;
    reg [71:0] tmp;              // 40 bits BCD (topo) + 32 bits binario (base)

    always @(*) begin
        tmp = 72'd0;
        tmp[31:0] = binario;

        // 32 iteracoes de "ajusta (>=5 soma 3) e desloca"
        for (i = 0; i < 32; i = i + 1) begin
            for (j = 0; j < 10; j = j + 1) begin
                if (tmp[32 + j*4 +: 4] >= 4'd5)
                    tmp[32 + j*4 +: 4] = tmp[32 + j*4 +: 4] + 4'd3;
            end
            tmp = tmp << 1;
        end

        bcd = tmp[71:32];
    end
endmodule
