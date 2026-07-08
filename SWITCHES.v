module SWITCHES (
    input  [31:0] Dado_Switches, // valor lido das chaves físicas do FPGA
    output [31:0] Saida          // saída para o MUX SwitchesON
);
    // Repasse direto do valor das chaves
    assign Saida = Dado_Switches;

endmodule
