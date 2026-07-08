module BANCO_DE_REGISTRADORES (
    input clk,
    
    // Sinais de Controle
    input RegWrite,
    input RHwrite,
    input RPIwrite,
    input RALwrite,
    
    // Endereços de Leitura e Escrita (6 bits)
    input [5:0] Registrador_1,
    input [5:0] Registrador_2,
    input [5:0] Registrador_Escrita,
    
    // Dados de Entrada (32 bits)
    input [31:0] Dado_para_Escrita,
    input [31:0] Dado_RH,
    input [31:0] Dado_RPI,
    input [31:0] Dado_RAL,
    
    // Dados de Saída (32 bits)
    output [31:0] Dado_1,
    output [31:0] Dado_2
);

    // Endereços dos registradores de uso específico
    // Os endereços 58-63 são reservados para uso específico.
    // Os registradores de uso geral ocupam os endereços 1-57.
	 
    localparam RZ_ADDR   = 6'd0;  // Armazena sempre o valor zero (protegido contra escrita)
    localparam RIN_ADDR  = 6'd58; // Armazena o valor lido dos switches (instrução IN)
    localparam ROUT_ADDR = 6'd59; // Armazena o valor a ser enviado ao display (instrução OUT)
    localparam RL_ADDR   = 6'd60; // Parte baixa da multiplicação / quociente da divisão
    localparam RAL_ADDR  = 6'd61; // Endereço de retorno salvo pela instrução JAL
    localparam RPI_ADDR  = 6'd62; // Ponteiro do topo da pilha
    localparam RH_ADDR   = 6'd63; // Parte alta da multiplicação / resto da divisão

    // Declaração da matriz do banco de registradores: 64 posições de 32 bits
    reg [31:0] banco [0:63];
    
    // Inicialização do banco (útil para simulação)
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            banco[i] = 32'd0;
        end
    end

    // Leitura combinacional (sem dependência de clock)

    assign Dado_1 = banco[Registrador_1];
    assign Dado_2 = banco[Registrador_2];

    // Escrita na borda de subida do clock

    always @(posedge clk) begin
        
        // --- Escritas por portas dedicadas ---
        // RH: resultado alto de MUL/DIV, escrita controlada por RHwrite
        if (RHwrite == 1'b1)
            banco[RH_ADDR] <= Dado_RH;
        
        // RPI: ponteiro de pilha atualizado por PUSH/POP, escrita controlada por RPIwrite
        if (RPIwrite == 1'b1)
            banco[RPI_ADDR] <= Dado_RPI;
        
        // RAL: endereço de retorno salvo por JAL, escrita controlada por RALwrite
        if (RALwrite == 1'b1)
            banco[RAL_ADDR] <= Dado_RAL;

        // --- Escrita geral ---
        // Cobre: registradores de uso geral (1-57), RL (60), RIN (58) e ROUT (59).
        // RZ (endereço 0) é permanentemente protegido contra qualquer escrita.
        if (RegWrite == 1'b1 && Registrador_Escrita != RZ_ADDR)
            banco[Registrador_Escrita] <= Dado_para_Escrita;
        
    end

endmodule
