`timescale 1ns/1ps

module fir_accumulator_101 #(
    parameter PROD_W = 36,
    parameter ACC_W  = 64
) (
    input signed [PROD_W-1:0] p000, p001, p002, p003, p004, p005, p006, p007,
    input signed [PROD_W-1:0] p008, p009, p010, p011, p012, p013, p014, p015,
    input signed [PROD_W-1:0] p016, p017, p018, p019, p020, p021, p022, p023,
    input signed [PROD_W-1:0] p024, p025, p026, p027, p028, p029, p030, p031,
    input signed [PROD_W-1:0] p032, p033, p034, p035, p036, p037, p038, p039,
    input signed [PROD_W-1:0] p040, p041, p042, p043, p044, p045, p046, p047,
    input signed [PROD_W-1:0] p048, p049, p050, p051, p052, p053, p054, p055,
    input signed [PROD_W-1:0] p056, p057, p058, p059, p060, p061, p062, p063,
    input signed [PROD_W-1:0] p064, p065, p066, p067, p068, p069, p070, p071,
    input signed [PROD_W-1:0] p072, p073, p074, p075, p076, p077, p078, p079,
    input signed [PROD_W-1:0] p080, p081, p082, p083, p084, p085, p086, p087,
    input signed [PROD_W-1:0] p088, p089, p090, p091, p092, p093, p094, p095,
    input signed [PROD_W-1:0] p096, p097, p098, p099, p100,
    output signed [ACC_W-1:0] sum
);
    assign sum =
        {{(ACC_W-PROD_W){p000[PROD_W-1]}}, p000} + {{(ACC_W-PROD_W){p001[PROD_W-1]}}, p001} +
        {{(ACC_W-PROD_W){p002[PROD_W-1]}}, p002} + {{(ACC_W-PROD_W){p003[PROD_W-1]}}, p003} +
        {{(ACC_W-PROD_W){p004[PROD_W-1]}}, p004} + {{(ACC_W-PROD_W){p005[PROD_W-1]}}, p005} +
        {{(ACC_W-PROD_W){p006[PROD_W-1]}}, p006} + {{(ACC_W-PROD_W){p007[PROD_W-1]}}, p007} +
        {{(ACC_W-PROD_W){p008[PROD_W-1]}}, p008} + {{(ACC_W-PROD_W){p009[PROD_W-1]}}, p009} +
        {{(ACC_W-PROD_W){p010[PROD_W-1]}}, p010} + {{(ACC_W-PROD_W){p011[PROD_W-1]}}, p011} +
        {{(ACC_W-PROD_W){p012[PROD_W-1]}}, p012} + {{(ACC_W-PROD_W){p013[PROD_W-1]}}, p013} +
        {{(ACC_W-PROD_W){p014[PROD_W-1]}}, p014} + {{(ACC_W-PROD_W){p015[PROD_W-1]}}, p015} +
        {{(ACC_W-PROD_W){p016[PROD_W-1]}}, p016} + {{(ACC_W-PROD_W){p017[PROD_W-1]}}, p017} +
        {{(ACC_W-PROD_W){p018[PROD_W-1]}}, p018} + {{(ACC_W-PROD_W){p019[PROD_W-1]}}, p019} +
        {{(ACC_W-PROD_W){p020[PROD_W-1]}}, p020} + {{(ACC_W-PROD_W){p021[PROD_W-1]}}, p021} +
        {{(ACC_W-PROD_W){p022[PROD_W-1]}}, p022} + {{(ACC_W-PROD_W){p023[PROD_W-1]}}, p023} +
        {{(ACC_W-PROD_W){p024[PROD_W-1]}}, p024} + {{(ACC_W-PROD_W){p025[PROD_W-1]}}, p025} +
        {{(ACC_W-PROD_W){p026[PROD_W-1]}}, p026} + {{(ACC_W-PROD_W){p027[PROD_W-1]}}, p027} +
        {{(ACC_W-PROD_W){p028[PROD_W-1]}}, p028} + {{(ACC_W-PROD_W){p029[PROD_W-1]}}, p029} +
        {{(ACC_W-PROD_W){p030[PROD_W-1]}}, p030} + {{(ACC_W-PROD_W){p031[PROD_W-1]}}, p031} +
        {{(ACC_W-PROD_W){p032[PROD_W-1]}}, p032} + {{(ACC_W-PROD_W){p033[PROD_W-1]}}, p033} +
        {{(ACC_W-PROD_W){p034[PROD_W-1]}}, p034} + {{(ACC_W-PROD_W){p035[PROD_W-1]}}, p035} +
        {{(ACC_W-PROD_W){p036[PROD_W-1]}}, p036} + {{(ACC_W-PROD_W){p037[PROD_W-1]}}, p037} +
        {{(ACC_W-PROD_W){p038[PROD_W-1]}}, p038} + {{(ACC_W-PROD_W){p039[PROD_W-1]}}, p039} +
        {{(ACC_W-PROD_W){p040[PROD_W-1]}}, p040} + {{(ACC_W-PROD_W){p041[PROD_W-1]}}, p041} +
        {{(ACC_W-PROD_W){p042[PROD_W-1]}}, p042} + {{(ACC_W-PROD_W){p043[PROD_W-1]}}, p043} +
        {{(ACC_W-PROD_W){p044[PROD_W-1]}}, p044} + {{(ACC_W-PROD_W){p045[PROD_W-1]}}, p045} +
        {{(ACC_W-PROD_W){p046[PROD_W-1]}}, p046} + {{(ACC_W-PROD_W){p047[PROD_W-1]}}, p047} +
        {{(ACC_W-PROD_W){p048[PROD_W-1]}}, p048} + {{(ACC_W-PROD_W){p049[PROD_W-1]}}, p049} +
        {{(ACC_W-PROD_W){p050[PROD_W-1]}}, p050} + {{(ACC_W-PROD_W){p051[PROD_W-1]}}, p051} +
        {{(ACC_W-PROD_W){p052[PROD_W-1]}}, p052} + {{(ACC_W-PROD_W){p053[PROD_W-1]}}, p053} +
        {{(ACC_W-PROD_W){p054[PROD_W-1]}}, p054} + {{(ACC_W-PROD_W){p055[PROD_W-1]}}, p055} +
        {{(ACC_W-PROD_W){p056[PROD_W-1]}}, p056} + {{(ACC_W-PROD_W){p057[PROD_W-1]}}, p057} +
        {{(ACC_W-PROD_W){p058[PROD_W-1]}}, p058} + {{(ACC_W-PROD_W){p059[PROD_W-1]}}, p059} +
        {{(ACC_W-PROD_W){p060[PROD_W-1]}}, p060} + {{(ACC_W-PROD_W){p061[PROD_W-1]}}, p061} +
        {{(ACC_W-PROD_W){p062[PROD_W-1]}}, p062} + {{(ACC_W-PROD_W){p063[PROD_W-1]}}, p063} +
        {{(ACC_W-PROD_W){p064[PROD_W-1]}}, p064} + {{(ACC_W-PROD_W){p065[PROD_W-1]}}, p065} +
        {{(ACC_W-PROD_W){p066[PROD_W-1]}}, p066} + {{(ACC_W-PROD_W){p067[PROD_W-1]}}, p067} +
        {{(ACC_W-PROD_W){p068[PROD_W-1]}}, p068} + {{(ACC_W-PROD_W){p069[PROD_W-1]}}, p069} +
        {{(ACC_W-PROD_W){p070[PROD_W-1]}}, p070} + {{(ACC_W-PROD_W){p071[PROD_W-1]}}, p071} +
        {{(ACC_W-PROD_W){p072[PROD_W-1]}}, p072} + {{(ACC_W-PROD_W){p073[PROD_W-1]}}, p073} +
        {{(ACC_W-PROD_W){p074[PROD_W-1]}}, p074} + {{(ACC_W-PROD_W){p075[PROD_W-1]}}, p075} +
        {{(ACC_W-PROD_W){p076[PROD_W-1]}}, p076} + {{(ACC_W-PROD_W){p077[PROD_W-1]}}, p077} +
        {{(ACC_W-PROD_W){p078[PROD_W-1]}}, p078} + {{(ACC_W-PROD_W){p079[PROD_W-1]}}, p079} +
        {{(ACC_W-PROD_W){p080[PROD_W-1]}}, p080} + {{(ACC_W-PROD_W){p081[PROD_W-1]}}, p081} +
        {{(ACC_W-PROD_W){p082[PROD_W-1]}}, p082} + {{(ACC_W-PROD_W){p083[PROD_W-1]}}, p083} +
        {{(ACC_W-PROD_W){p084[PROD_W-1]}}, p084} + {{(ACC_W-PROD_W){p085[PROD_W-1]}}, p085} +
        {{(ACC_W-PROD_W){p086[PROD_W-1]}}, p086} + {{(ACC_W-PROD_W){p087[PROD_W-1]}}, p087} +
        {{(ACC_W-PROD_W){p088[PROD_W-1]}}, p088} + {{(ACC_W-PROD_W){p089[PROD_W-1]}}, p089} +
        {{(ACC_W-PROD_W){p090[PROD_W-1]}}, p090} + {{(ACC_W-PROD_W){p091[PROD_W-1]}}, p091} +
        {{(ACC_W-PROD_W){p092[PROD_W-1]}}, p092} + {{(ACC_W-PROD_W){p093[PROD_W-1]}}, p093} +
        {{(ACC_W-PROD_W){p094[PROD_W-1]}}, p094} + {{(ACC_W-PROD_W){p095[PROD_W-1]}}, p095} +
        {{(ACC_W-PROD_W){p096[PROD_W-1]}}, p096} + {{(ACC_W-PROD_W){p097[PROD_W-1]}}, p097} +
        {{(ACC_W-PROD_W){p098[PROD_W-1]}}, p098} + {{(ACC_W-PROD_W){p099[PROD_W-1]}}, p099} +
        {{(ACC_W-PROD_W){p100[PROD_W-1]}}, p100};
endmodule