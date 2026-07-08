// =====================================================================
//  DIVISOR_FREQUENCIA.v
//  Divide o clock de referencia (CLOCK_50 = 50 MHz na DE2-115) para uma
//  frequencia menor, parametrizavel.
//
//  Gera DUAS saidas:
//    clk_out : onda quadrada (~50% duty) na frequencia CLK_SAIDA_HZ.
//              Use para "clocar" o processador em modo lento (drop-in).
//    tick    : pulso de 1 ciclo de clk_in por periodo de saida.
//              Use como CLOCK ENABLE (abordagem recomendada, ver README).
//
//  Ex.: 50 MHz -> 1 Hz    => CLK_SAIDA_HZ = 1
//       50 MHz -> 1 kHz   => CLK_SAIDA_HZ = 1000
//       50 MHz -> 1 MHz   => CLK_SAIDA_HZ = 1000000
// =====================================================================
module DIVISOR_FREQUENCIA #(
    parameter integer CLK_ENTRADA_HZ = 50000000,  // frequencia do clk_in
    parameter integer CLK_SAIDA_HZ   = 1          // frequencia desejada
)(
    input  wire clk_in,    // clock de referencia (50 MHz)
    input  wire rst_n,     // reset assincrono, ativo em nivel BAIXO
    output reg  clk_out,   // clock dividido (~50% duty)
    output reg  tick       // 1 pulso (largura = 1 ciclo de clk_in) por periodo
);
    // Ciclos de clk_in em MEIO periodo do clock de saida.
    // Ex.: 50e6 / (2*1) = 25.000.000 ciclos por meio periodo (1 Hz).
    localparam integer MEIO = CLK_ENTRADA_HZ / (2 * CLK_SAIDA_HZ);

    // Largura minima do contador para representar 'MEIO'.
    localparam integer W = (MEIO <= 2) ? 1 : $clog2(MEIO);

    reg [W-1:0] cont;

    initial begin
        cont    = {W{1'b0}};
        clk_out = 1'b0;
        tick    = 1'b0;
    end

    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            cont    <= {W{1'b0}};
            clk_out <= 1'b0;
            tick    <= 1'b0;
        end
        else if (cont == MEIO - 1) begin
            cont    <= {W{1'b0}};
            clk_out <= ~clk_out;
            tick    <= ~clk_out;   // 1 quando clk_out vai de 0->1 (inicio do periodo)
        end
        else begin
            cont <= cont + 1'b1;
            tick <= 1'b0;
        end
    end
endmodule
