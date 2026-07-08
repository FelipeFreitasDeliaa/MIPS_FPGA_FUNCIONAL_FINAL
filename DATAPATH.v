module DATAPATH (
    input clk,
    
    // Sinais de controle do banco
    input RegWrite,
    input RHwrite,
    input RPIwrite,
    input RALwrite,
    
    // Sinais de controle dos MUXes 
	 
    input ULASource, // 0 = Dado_2 do banco,    1 = imediato estendido
    input Push,      // 0 = imediato estendido, 1 = constante 1
    input Resp,      // 0 = valor normal,       1 = força RZ (zero) na entrada B da ULA
    input MemtoReg,  // 0 = resultado da ULA,   1 = dado da memória
    input SwitchesON,// 0 = valor do MemtoReg,  1 = valor dos switches
    
    // Opcode para a ULA
    input [5:0] opcode,
    
    // Endereços de registradores
    input [5:0] Registrador_1,
    input [5:0] Registrador_2,
    input [5:0] Registrador_Escrita,
    
    // Dados externos
    input [31:0] Imediato_Estendido, // vem do extensor de sinal
    input [31:0] Dado_RPI,
    input [31:0] Dado_RAL,
    input [31:0] Dado_Memoria,
    input [31:0] Dado_Switches,
    
    // Saídas
    output [31:0] Saida_ULA,
    output        z_flag,
	 output [31:0] Dado_1_Out, 
    output [31:0] Dado_2_Out  
);

    // Fios internos

    wire [31:0] fio_dado1;
    wire [31:0] fio_dado2;
    wire [31:0] fio_resultado_ula;
    wire [31:0] fio_resultado_high;

    // Fios dos MUXes antes da ULA (entrada B)
	 
    wire [31:0] fio_mux_push;          // saída do MUX Push
    wire [31:0] fio_mux_ulasource;     // saída do MUX ULASource
    wire [31:0] fio_mux_resp;          // saída do MUX Resp → entrada B da ULA (esse mux tem 
													// como saída o registrador zero ou a saída do mux anterior)

    // Fios dos MUXes após a ULA (caminho de escrita no banco)
    wire [31:0] fio_mux_memtoreg;
    wire [31:0] fio_mux_switcheson;

    // MUXes antes da ULA — definem a entrada B

    // MUX Push: decide entre imediato estendido e constante 1
    assign fio_mux_push = (Push == 1'b1) ? 32'd1 : Imediato_Estendido;

    // MUX ULASource: decide entre Dado_2 (registrador) e saída do MUX Push
    assign fio_mux_ulasource = (ULASource == 1'b1) ? fio_mux_push : fio_dado2;

    // MUX Resp: decide entre valor normal e RZ (zero) — usado em STORER
    assign fio_mux_resp = (Resp == 1'b1) ? 32'd0 : fio_mux_ulasource;

    // MUXes após a ULA — definem o dado escrito no banco

    // MUX MemtoReg: resultado da ULA ou dado lido da memória
    assign fio_mux_memtoreg = (MemtoReg == 1'b1) ? Dado_Memoria : fio_resultado_ula;

    // MUX SwitchesON: dado do MemtoReg ou valor dos switches (instrução IN)
    assign fio_mux_switcheson = (SwitchesON == 1'b1) ? Dado_Switches : fio_mux_memtoreg;

    // Saída da ULA disponível externamente
    assign Saida_ULA = fio_resultado_ula;

    // Instância do Banco de Registradores

    BANCO_DE_REGISTRADORES meu_banco (
        .clk                (clk),
        .RegWrite           (RegWrite),
        .RHwrite            (RHwrite),
        .RPIwrite           (RPIwrite),
        .RALwrite           (RALwrite),
        .Registrador_1      (Registrador_1),
        .Registrador_2      (Registrador_2),
        .Registrador_Escrita(Registrador_Escrita),
        .Dado_para_Escrita  (fio_mux_switcheson),
        .Dado_RH            (fio_resultado_high),
        .Dado_RPI           (Dado_RPI),
        .Dado_RAL           (Dado_RAL),
        .Dado_1             (fio_dado1),
        .Dado_2             (fio_dado2)
    );

    // Instância da ULA
	 
    ULA minha_ula (
        .A      (fio_dado1),
        .B      (fio_mux_resp), // entrada B passou pelos três MUXes
        .opcode (opcode),
        .out    (fio_resultado_ula),
        .high   (fio_resultado_high),
        .z_flag (z_flag)
    );
	 
	 assign Dado_1_Out = fio_dado1;
    assign Dado_2_Out = fio_dado2;

endmodule
