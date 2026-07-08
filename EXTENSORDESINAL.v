module EXTENSORDESINAL (
    // Entradas vindas dos MUXes seletores de imediato
    input  [25:0] Imediato_26, // bits 25-0 da instrução (JMP, JAL)
    input  [19:0] Imediato_20, // bits 19-0 da instrução (Formatos 5 e 6)
    input  [13:0] Imediato_14, // bits 13-0 da instrução (Formatos 2 e 3)

    // Sinais de controle vindos da UC (mesmos do DATAPATH)
    input         SelImm1,     // 0=14bits, 1=20bits
    input         SelImm2,     // 0=saída MUX anterior, 1=26bits

    // Saída estendida para 32 bits
    output reg [31:0] Saida
);

    // Fio interno que carrega a saída do primeiro MUX
    wire [31:0] fio_mux1;

    // MUX 1: seleciona entre 14 bits e 20 bits e já estende o sinal
    assign fio_mux1 = (SelImm1 == 1'b1) ? {{12{Imediato_20[19]}}, Imediato_20}  // extensão de 20 para 32 bits
                                         : {{18{Imediato_14[13]}}, Imediato_14}; // extensão de 14 para 32 bits

    // MUX 2: seleciona entre saída do MUX anterior e 26 bits
    always @(*) begin
        if (SelImm2 == 1'b1)
            Saida = {{6{Imediato_26[25]}}, Imediato_26}; // extensão de 26 para 32 bits
        else
            Saida = fio_mux1;
    end

endmodule
