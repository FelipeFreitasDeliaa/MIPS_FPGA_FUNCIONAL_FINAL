module DISPLAY (
    input        clk,
    input        PortaON,        // 1 = captura o valor no display
    input [31:0] Dado_Display,   // valor vindo do Dado 1 do banco (ROUT)

    output reg [31:0] Saida_Display // valor exibido no display
);

// Garante que o display inicie mostrando o valor ZERO
    initial begin
        Saida_Display = 32'd0;
    end
	 
    always @(negedge clk) begin
        if (PortaON == 1'b1)
            Saida_Display <= Dado_Display;
    end

endmodule
