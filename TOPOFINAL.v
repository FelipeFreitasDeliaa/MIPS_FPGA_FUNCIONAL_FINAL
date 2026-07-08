// =====================================================================
//  TOPO_DE2_115.v
//  Modulo de TOPO para colocar o processador na placa DE2-115.
//
//  Configuracao desta versao:
//    - Clock do processador FIXO em 1 MHz.
//    - Botao KEY[0] = "ENTER" das instrucoes IN: o processador PARA em
//      cada instrucao IN ate voce apertar KEY[0] (tempo de ajustar as
//      chaves). Cada aperto libera UMA IN; para a proxima, solte e
//      aperte de novo.
//    - Saida mostrada em DECIMAL (com zeros a esquerda) em HEX7..HEX0.
//    - Sem LEDs de depuracao.
//
//  Mapeamento:
//    SW[15:0]  -> dado de entrada das instrucoes IN (32 bits estendidos)
//    KEY[0]    -> ENTER das instrucoes IN
//    HEX7..HEX0-> valor de saida (ROUT) em DECIMAL
// =====================================================================
module TOPOFINAL (
    input  wire        CLOCK_50,
    input  wire [17:0] SW,
    input  wire [3:0]  KEY,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,
    output wire [6:0]  HEX6,
    output wire [6:0]  HEX7
);
    // ---------------------------------------------------------------
    // Clock FIXO de 1 MHz para o processador (dentro do teto ~3,4 MHz).
    // Sem reset externo: o divisor se auto-inicializa (bloco initial).
    // ---------------------------------------------------------------
    wire clk_proc;
    DIVISOR_FREQUENCIA #(
        .CLK_ENTRADA_HZ(50000000),
        .CLK_SAIDA_HZ  (1000000)      // 1 MHz
    ) div_1mhz (
        .clk_in (CLOCK_50),
        .rst_n  (1'b1),               // sempre habilitado
        .clk_out(clk_proc),
        .tick   ()                    // nao usado
    );

    // ---------------------------------------------------------------
    // Dado das chaves para as instrucoes IN: SW[15:0] -> 32 bits
    // ---------------------------------------------------------------
    wire [31:0] dado_switches = {16'd0, SW[15:0]};

    // ---------------------------------------------------------------
    // Instancia do PROCESSADOR
    //  (usa PROGRAMCOUNTER e DATAPATHGERAL MODIFICADOS desta pasta)
    //  KEY[0] = botao de "enter" das instrucoes IN.
    // ---------------------------------------------------------------
    wire [31:0] valor_display;

    DATAPATHGERAL processador (
        .clk                  (clk_proc),
        .botao_in             (KEY[0]),          // ENTER das instrucoes IN
        .Dado_Switches_Ext    (dado_switches),
        .Saida_Display_Out    (valor_display),
        .debug_saida_ula          (),
        .debug_dado1              (),
        .debug_dado2              (),
        .debug_regescrira_banco   (),
        .debug_pc_atual           (),
        .debug_instrucao          (),
        .debug_opcode             (),
        .debug_imediato_estendido (),
        .debug_dado_lido_mem      ()
    );

    // ---------------------------------------------------------------
    // Display do valor de saida (ROUT) em DECIMAL (com zeros a esquerda)
    // ---------------------------------------------------------------
    DISPLAY_DEC32 display (
        .valor(valor_display),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3),
        .HEX4(HEX4), .HEX5(HEX5), .HEX6(HEX6), .HEX7(HEX7)
    );

endmodule
