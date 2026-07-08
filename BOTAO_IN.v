// =====================================================================
//  BOTAO_IN.v  -  Botao de "ENTER" para as instrucoes IN
// ---------------------------------------------------------------------
//  Objetivo: quando o processador chega numa instrucao IN, o PC fica
//  PARADO ate o usuario apertar este botao. Isso da tempo de ajustar as
//  chaves (SW) com o valor de entrada desejado; ao apertar, o PC avanca.
//
//  Regra anti-repeticao (evita entradas indesejadas em INs seguidas):
//  cada aperto libera UMA unica instrucao IN. Para liberar a proxima IN,
//  o usuario precisa SOLTAR e APERTAR de novo (segurar o botao nao pula
//  varias INs).
//
//  Este modulo e temporizado pelo MESMO clock do processador e na mesma
//  borda de atualizacao do PC (negedge), para ficar em sincronia.
//
//    em_in     : 1 quando a instrucao atual e IN  (ligar em SwitchesON)
//    segura_pc : 1 = o PC deve ficar parado (aguardando o "enter")
// =====================================================================
module BOTAO_IN #(
    parameter integer CLK_HZ      = 1000000,   // clock do processador (Hz)
    parameter integer DEBOUNCE_MS = 10,        // janela de debounce
    parameter         ATIVO_BAIXO = 1'b1        // KEY da DE2-115 = ativo-baixo
)(
    input  wire clk,          // mesmo clock do processador
    input  wire botao_bruto,  // pino fisico do botao (KEY)
    input  wire em_in,        // 1 quando a instrucao atual e IN (SwitchesON)
    output wire segura_pc     // 1 = segura o PC na IN
);
    // normaliza para ATIVO-ALTO (1 = pressionado)
    wire botao_norm = ATIVO_BAIXO ? ~botao_bruto : botao_bruto;

    // --- sincronizador de 2 estagios (anti-metaestabilidade) ---
    reg s1, s2;

    // --- debounce por contador -> 'nivel' estavel ---
    localparam integer N = (CLK_HZ/1000)*DEBOUNCE_MS;
    localparam integer W = (N <= 2) ? 1 : $clog2(N);
    reg [W-1:0] cnt;
    reg         nivel;        // 1 = botao pressionado (estavel)

    // --- FSM de consumo: 1 aperto = 1 IN liberada ---
    reg consumido;

    initial begin
        s1 = 1'b0; s2 = 1'b0; cnt = {W{1'b0}}; nivel = 1'b0; consumido = 1'b0;
    end

    always @(negedge clk) begin
        // sincronizador
        s1 <= botao_norm;
        s2 <= s1;

        // debounce
        if (s2 != nivel) begin
            if (cnt == N-1) begin nivel <= s2; cnt <= {W{1'b0}}; end
            else            cnt   <= cnt + 1'b1;
        end
        else cnt <= {W{1'b0}};

        // consumo:
        //  - soltou o botao (nivel=0)  -> rearma (consumido=0)
        //  - esta numa IN com o botao pressionado -> consome (consumido=1)
        if (!nivel)       consumido <= 1'b0;
        else if (em_in)   consumido <= 1'b1;
    end

    // ha um "enter" fresco disponivel enquanto pressionado e nao consumido
    wire liberar = nivel & ~consumido;

    // segura o PC enquanto estiver numa IN sem "enter" liberado
    assign segura_pc = em_in & ~liberar;
endmodule
